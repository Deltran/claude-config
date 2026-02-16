# Secrets Management Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a three-layer secrets management system — Bitwarden vault with encrypted local cache, log sanitizer, and gitleaks pre-commit hook — so secrets never end up in git history or log files.

**Architecture:** All secrets live in Bitwarden. A `secrets` CLI wrapper pulls them into an age-encrypted local cache. Shell startup decrypts the cache into env vars (non-blocking, 5s timeout). A log sanitizer redacts secrets before they hit disk. Gitleaks blocks any commit containing secret patterns.

**Tech Stack:** age (encryption), gitleaks (secret scanning), Bitwarden CLI, bash/zsh, jq

---

### Task 1: Install Dependencies

**Files:**
- None created (system packages)

**Step 1: Install age**

```bash
sudo apt update && sudo apt install -y age
```

Verify: `age --version` should print a version string.

**Step 2: Install gitleaks**

Download the latest release binary:

```bash
GITLEAKS_VERSION=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | jq -r '.tag_name' | sed 's/^v//')
curl -sSLo /tmp/gitleaks.tar.gz "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
tar -xzf /tmp/gitleaks.tar.gz -C /tmp gitleaks
mv /tmp/gitleaks ~/.local/bin/gitleaks
chmod +x ~/.local/bin/gitleaks
rm /tmp/gitleaks.tar.gz
```

Verify: `gitleaks version` should print the version.

**Step 3: Commit**

No commit — system-level install, nothing to track in git.

---

### Task 2: Generate Age Encryption Key

**Files:**
- Create: `~/.secrets-cache-key.txt`

**Step 1: Generate the key**

```bash
age-keygen -o ~/.secrets-cache-key.txt 2>/dev/null
chmod 600 ~/.secrets-cache-key.txt
```

**Step 2: Verify**

```bash
ls -la ~/.secrets-cache-key.txt
```

Expected: `-rw-------` permissions, file contains `# created:` header and `AGE-SECRET-KEY-...` line.

**Step 3: Extract the public key for later use**

```bash
grep 'public key' ~/.secrets-cache-key.txt
```

Note this public key — the `secrets` script will read it from the file automatically.

**Step 4: Commit**

No commit — this file must NEVER be committed anywhere.

---

### Task 3: Create the `secrets` CLI Wrapper

**Files:**
- Create: `~/.local/bin/secrets`

**Step 1: Write the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

CACHE_FILE="$HOME/.secrets-cache.age"
KEY_FILE="$HOME/.secrets-cache-key.txt"
CACHE_TTL_HOURS=24
BW_FOLDER_NAME="cli-secrets"

_die() { echo "secrets: $*" >&2; exit 1; }

_check_key() {
  [[ -f "$KEY_FILE" ]] || _die "age key not found at $KEY_FILE"
}

_get_public_key() {
  grep 'public key' "$KEY_FILE" | awk '{print $NF}'
}

_cache_age_hours() {
  if [[ ! -f "$CACHE_FILE" ]]; then
    echo "999"
    return
  fi
  local now mtime
  now=$(date +%s)
  mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
  echo $(( (now - mtime) / 3600 ))
}

cmd_refresh() {
  _check_key

  # Ensure BW is unlocked
  local status
  status=$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null) || true
  if [[ "$status" != "unlocked" ]]; then
    _die "Bitwarden vault is not unlocked. Run: bw unlock"
  fi

  # Sync vault first
  bw sync >/dev/null 2>&1 || true

  # Get the folder ID for cli-secrets
  local folder_id
  folder_id=$(bw list folders --session "${BW_SESSION:-}" 2>/dev/null \
    | jq -r ".[] | select(.name==\"$BW_FOLDER_NAME\") | .id")
  [[ -n "$folder_id" ]] || _die "Bitwarden folder '$BW_FOLDER_NAME' not found. Create it first."

  # Pull all items from that folder
  local items
  items=$(bw list items --folderid "$folder_id" --session "${BW_SESSION:-}" 2>/dev/null)

  # Build KEY=VALUE pairs from secure notes (name=key, notes=value)
  local plaintext=""
  while IFS= read -r line; do
    local name val
    name=$(echo "$line" | jq -r '.name')
    val=$(echo "$line" | jq -r '.notes // empty')
    if [[ -n "$name" && -n "$val" ]]; then
      plaintext+="${name}=${val}"$'\n'
    fi
  done < <(echo "$items" | jq -c '.[]')

  if [[ -z "$plaintext" ]]; then
    _die "No secrets found in '$BW_FOLDER_NAME' folder."
  fi

  # Encrypt and write cache
  local pubkey
  pubkey=$(_get_public_key)
  echo -n "$plaintext" | age -r "$pubkey" -o "$CACHE_FILE"
  chmod 600 "$CACHE_FILE"

  echo "secrets: cache refreshed ($(echo "$plaintext" | grep -c .) entries)" >&2
}

cmd_load() {
  _check_key
  [[ -f "$CACHE_FILE" ]] || { echo "secrets: no cache file — run 'secrets refresh' first" >&2; return 1; }

  # Decrypt and print export lines
  age -d -i "$KEY_FILE" "$CACHE_FILE" 2>/dev/null | while IFS='=' read -r key val; do
    [[ -n "$key" ]] && printf 'export %s="%s"\n' "$key" "$val"
  done
}

cmd_get() {
  local name="$1"
  _check_key
  [[ -f "$CACHE_FILE" ]] || { echo "secrets: no cache file" >&2; return 1; }

  age -d -i "$KEY_FILE" "$CACHE_FILE" 2>/dev/null | while IFS='=' read -r key val; do
    if [[ "$key" == "$name" ]]; then
      printf '%s' "$val"
      return 0
    fi
  done
}

cmd_stale() {
  local hours
  hours=$(_cache_age_hours)
  if (( hours >= CACHE_TTL_HOURS )); then
    echo "[secrets] cache is ${hours}h old — unlock Bitwarden to refresh" >&2
    return 0
  fi
  return 1
}

cmd_list() {
  _check_key
  [[ -f "$CACHE_FILE" ]] || { echo "secrets: no cache file" >&2; return 1; }
  age -d -i "$KEY_FILE" "$CACHE_FILE" 2>/dev/null | cut -d= -f1
}

cmd_values() {
  # Output raw KEY=VALUE pairs (used by sanitizer)
  _check_key
  [[ -f "$CACHE_FILE" ]] || return 1
  age -d -i "$KEY_FILE" "$CACHE_FILE" 2>/dev/null
}

case "${1:-help}" in
  refresh) cmd_refresh ;;
  load)    cmd_load ;;
  get)     cmd_get "${2:?Usage: secrets get <name>}" ;;
  stale)   cmd_stale ;;
  list)    cmd_list ;;
  values)  cmd_values ;;
  help)
    echo "Usage: secrets <command>"
    echo "  refresh  — Pull secrets from Bitwarden, encrypt to cache"
    echo "  load     — Decrypt cache, print export lines (eval \"\$(secrets load)\")"
    echo "  get NAME — Print a single secret value"
    echo "  list     — List secret names in cache"
    echo "  stale    — Warn if cache is older than ${CACHE_TTL_HOURS}h"
    ;;
  *) _die "Unknown command: $1. Run 'secrets help'." ;;
esac
```

**Step 2: Make executable**

```bash
chmod +x ~/.local/bin/secrets
```

**Step 3: Verify help works**

```bash
secrets help
```

Expected: prints the usage text.

**Step 4: Commit**

No commit — `~/.local/bin` is not in a git repo.

---

### Task 4: Populate Bitwarden and Create Initial Cache

**This task requires user interaction — Bitwarden must be unlocked.**

**Step 1: Create the `cli-secrets` folder in Bitwarden**

```bash
bw get template folder | jq '.name = "cli-secrets"' | bw create folder
bw sync
```

**Step 2: Add secrets as Secure Notes**

Current secrets from `~/.zshrc.secrets`:
- `OPENAI_API_KEY`
- `GEMINI_API_KEY`

Current secrets from `~/code/discord-claude/.env`:
- `DISCORD_TOKEN`

Current secrets from `~/code/dorf/.env`:
- `PIXELLAB_TOKEN`

For each, create a Secure Note in the `cli-secrets` folder. The `bw` CLI template for a secure note:

```bash
# Get the folder ID
FOLDER_ID=$(bw list folders | jq -r '.[] | select(.name=="cli-secrets") | .id')

# Helper to create a secret note
add_secret() {
  local name="$1" value="$2"
  bw get template item | jq \
    --arg name "$name" \
    --arg value "$value" \
    --arg fid "$FOLDER_ID" \
    '.type = 2 | .secureNote = {"type": 0} | .name = $name | .notes = $value | .folderId = $fid' \
    | bw create item > /dev/null
  echo "Added: $name"
}

add_secret "OPENAI_API_KEY" "<value from .zshrc.secrets>"
add_secret "GEMINI_API_KEY" "<value from .zshrc.secrets>"
add_secret "DISCORD_TOKEN" "<value from discord-claude .env>"
add_secret "PIXELLAB_TOKEN" "<value from dorf .env>"
```

**Important:** The actual secret values should be read from the existing files, not hardcoded in the command. The implementing agent should `source ~/.zshrc.secrets` and read the .env files to get values.

**Step 3: Refresh the cache**

```bash
bw sync
secrets refresh
```

Expected: `secrets: cache refreshed (4 entries)`

**Step 4: Verify cache contents**

```bash
secrets list
```

Expected: prints `OPENAI_API_KEY`, `GEMINI_API_KEY`, `DISCORD_TOKEN`, `PIXELLAB_TOKEN`

```bash
secrets load
```

Expected: prints 4 `export KEY="VALUE"` lines.

---

### Task 5: Update `.zshrc` with New Startup Flow

**Files:**
- Modify: `~/.zshrc:7-8` (replace the secrets source line)

**Step 1: Replace the old secrets loading**

Replace lines 7-8 of `~/.zshrc`:

```bash
# Secrets (API keys, tokens — not managed by chezmoi)
[[ -f ~/.zshrc.secrets ]] && source ~/.zshrc.secrets
```

With:

```bash
# Secrets management — Bitwarden vault + encrypted cache
# Non-blocking: 5s timeout on BW unlock prompt, skips silently on failure
_secrets_init() {
  local bw_status
  bw_status=$(timeout 2 bw status 2>/dev/null | jq -r '.status' 2>/dev/null) || bw_status="timeout"

  case "$bw_status" in
    unlocked)
      # Already unlocked — refresh cache silently in background
      secrets refresh &>/dev/null &
      ;;
    locked)
      # Prompt for master password (non-blocking, 5s timeout)
      if [[ -t 0 ]]; then
        echo -n "[secrets] Vault locked. Master password (5s timeout): "
        local pw
        if read -rs -t 5 pw 2>/dev/null && [[ -n "$pw" ]]; then
          echo ""
          BW_SESSION=$(echo "$pw" | bw unlock --raw 2>/dev/null) && export BW_SESSION
          if [[ -n "$BW_SESSION" ]]; then
            secrets refresh &>/dev/null &
          else
            echo "[secrets] unlock failed — using cached secrets" >&2
          fi
        else
          echo ""
          echo "[secrets] skipped — using cached secrets" >&2
        fi
      fi
      ;;
    unauthenticated)
      if [[ -t 0 ]]; then
        echo "[secrets] not logged in — run 'bw login' manually" >&2
      fi
      ;;
    *)
      # timeout or error — skip silently
      ;;
  esac

  # Always load from cache (regardless of BW status)
  if [[ -f "$HOME/.secrets-cache.age" ]]; then
    eval "$(secrets load 2>/dev/null)"
    # Check staleness
    secrets stale 2>/dev/null || true
  fi
}
_secrets_init
unset -f _secrets_init
```

**Step 2: Verify syntax**

```bash
zsh -n ~/.zshrc
```

Expected: no errors.

**Step 3: Test in a subshell**

```bash
zsh -c 'source ~/.zshrc; echo "GEMINI_API_KEY is ${GEMINI_API_KEY:+set}"'
```

Expected: `GEMINI_API_KEY is set` (loaded from cache).

**Step 4: Commit**

No commit — `~/.zshrc` is not in a git repo (managed separately).

---

### Task 6: Create Log Sanitizer

**Files:**
- Create: `~/.claude/scripts/sanitize-log.sh`

**Step 1: Write the sanitizer script**

```bash
#!/usr/bin/env bash
# sanitize-log.sh — Redacts secrets from text before it's written to log files.
# Usage: echo "$text" | sanitize-log.sh
# Two-pronged approach:
#   1. Regex patterns for known secret formats (Discord tokens, API keys, etc.)
#   2. Exact value matching against the encrypted secrets cache

set -uo pipefail

INPUT=$(cat)

# --- Prong 1: Known patterns ---
# Discord bot tokens: base64-encoded user ID, period, timestamp, period, HMAC
INPUT=$(echo "$INPUT" | sed -E 's/[MN][A-Za-z0-9_-]{23,}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27,}/[REDACTED:DISCORD_TOKEN_PATTERN]/g')

# OpenAI API keys
INPUT=$(echo "$INPUT" | sed -E 's/sk-[A-Za-z0-9_-]{20,}/[REDACTED:OPENAI_KEY_PATTERN]/g')

# Google/Gemini API keys
INPUT=$(echo "$INPUT" | sed -E 's/AIzaSy[A-Za-z0-9_-]{33}/[REDACTED:GOOGLE_KEY_PATTERN]/g')

# AWS access keys
INPUT=$(echo "$INPUT" | sed -E 's/AKIA[0-9A-Z]{16}/[REDACTED:AWS_KEY_PATTERN]/g')

# GitHub tokens (ghp_, gho_, ghu_, ghs_, ghr_)
INPUT=$(echo "$INPUT" | sed -E 's/gh[pousr]_[A-Za-z0-9_]{36,}/[REDACTED:GITHUB_TOKEN_PATTERN]/g')

# Generic bearer tokens (long base64 strings after "token" or "bearer")
INPUT=$(echo "$INPUT" | sed -Ei 's/(token|bearer)([[:space:]]*[:=][[:space:]]*)[A-Za-z0-9_\/-]{40,}/\1\2[REDACTED:BEARER_PATTERN]/gi' 2>/dev/null || true)

# --- Prong 2: Exact value matching from secrets cache ---
SECRETS_BIN="$HOME/.local/bin/secrets"
if [[ -x "$SECRETS_BIN" ]]; then
  while IFS='=' read -r key val; do
    if [[ -n "$key" && -n "$val" && ${#val} -ge 8 ]]; then
      # Escape special regex chars in the value
      escaped=$(printf '%s' "$val" | sed 's/[&/\]/\\&/g')
      INPUT=$(echo "$INPUT" | sed "s|${escaped}|[REDACTED:${key}]|g")
    fi
  done < <("$SECRETS_BIN" values 2>/dev/null || true)
fi

printf '%s' "$INPUT"
```

**Step 2: Make executable**

```bash
chmod +x ~/.claude/scripts/sanitize-log.sh
```

**Step 3: Test with a known secret pattern**

```bash
echo "my token is FAKE_TOKEN_EXAMPLE.Abc123.XXXXXXXXXXXXXXXXXXXXXXXXXXX" | ~/.claude/scripts/sanitize-log.sh
```

Expected: `my token is [REDACTED:DISCORD_TOKEN_PATTERN]`

```bash
echo "key is sk-svcacct-something12345678901234" | ~/.claude/scripts/sanitize-log.sh
```

Expected: `key is [REDACTED:OPENAI_KEY_PATTERN]`

**Step 4: Commit**

```bash
cd ~/.claude && git add scripts/sanitize-log.sh && git commit -m "feat: add log sanitizer script for secret redaction"
```

---

### Task 7: Wire Sanitizer into Session Log Hook

**Files:**
- Modify: `~/.claude/hooks/log-prompt.sh:26-28` (pipe content through sanitizer)

**Step 1: Modify log-prompt.sh**

The current code at lines 26-28:

```bash
# Truncate long prompts for readability
TRUNCATED=$(echo "$PROMPT" | head -c 1000)
if [ ${#PROMPT} -gt 1000 ]; then
  TRUNCATED="${TRUNCATED}..."
fi
```

Replace with:

```bash
# Truncate long prompts for readability
TRUNCATED=$(echo "$PROMPT" | head -c 1000)
if [ ${#PROMPT} -gt 1000 ]; then
  TRUNCATED="${TRUNCATED}..."
fi

# Sanitize secrets before writing
SANITIZER="$HOME/.claude/scripts/sanitize-log.sh"
if [ -x "$SANITIZER" ]; then
  TRUNCATED=$(printf '%s' "$TRUNCATED" | "$SANITIZER")
fi
```

**Step 2: Test end-to-end**

```bash
echo '{"prompt":"my secret key is AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ok?"}' | ~/.claude/hooks/log-prompt.sh
# Check the log file
tail -1 ~/.claude/logs/$(date +%Y-%m-%d).md
```

Expected: the log line contains `[REDACTED:GOOGLE_KEY_PATTERN]` instead of the actual key.

**Step 3: Commit**

```bash
cd ~/.claude && git add hooks/log-prompt.sh && git commit -m "feat: wire log sanitizer into session log hook"
```

---

### Task 8: Set Up Global Gitleaks Pre-commit Hook

**Files:**
- Create: `~/.config/git/hooks/pre-commit`
- Modify: `~/.gitconfig` (add core.hooksPath)

**Step 1: Create the hooks directory**

```bash
mkdir -p ~/.config/git/hooks
```

**Step 2: Write the global pre-commit hook**

```bash
#!/usr/bin/env bash
# Global pre-commit hook — runs gitleaks on staged changes.
# Blocks commits containing detected secrets.
# Override per-file with: # gitleaks:allow
# Override per-repo with: .gitleaksignore

if command -v gitleaks &>/dev/null; then
  gitleaks protect --staged --verbose --redact 2>&1
  RESULT=$?
  if [[ $RESULT -ne 0 ]]; then
    echo ""
    echo "=== COMMIT BLOCKED: gitleaks found secrets ==="
    echo "Fix the issue, or add '# gitleaks:allow' to the line if it's a false positive."
    echo ""
    exit 1
  fi
fi

# Chain to repo-local pre-commit hook if it exists
REPO_HOOK="$(git rev-parse --git-dir)/hooks/pre-commit.local"
if [[ -x "$REPO_HOOK" ]]; then
  exec "$REPO_HOOK" "$@"
fi

exit 0
```

**Step 3: Make executable**

```bash
chmod +x ~/.config/git/hooks/pre-commit
```

**Step 4: Set global hooksPath in gitconfig**

```bash
git config --global core.hooksPath ~/.config/git/hooks
```

**Step 5: Verify gitconfig**

```bash
git config --global core.hooksPath
```

Expected: `/home/deltran/.config/git/hooks`

**Step 6: Test gitleaks on a dummy commit**

```bash
cd /tmp && mkdir test-gitleaks && cd test-gitleaks && git init
echo 'DISCORD_TOKEN=FAKE_TOKEN_EXAMPLE.Abc123.XXXXXXXXXXXXXXXXXXXXXXXXXXX' > test.env
git add test.env
git commit -m "test"
```

Expected: commit BLOCKED by gitleaks.

```bash
cd /tmp && rm -rf test-gitleaks
```

**Step 7: Commit**

No commit needed for gitconfig (not tracked). The hook itself lives outside any repo.

---

### Task 9: Verify All Layers End-to-End

**Step 1: Verify Layer 1 (secrets load)**

```bash
# In a new subshell
zsh -c 'source ~/.zshrc; secrets list; echo "---"; echo "OPENAI set: ${OPENAI_API_KEY:+yes}"; echo "GEMINI set: ${GEMINI_API_KEY:+yes}"'
```

Expected: lists all secret names, confirms env vars are set.

**Step 2: Verify Layer 2 (log sanitizer)**

```bash
echo "token FAKE_TOKEN_EXAMPLE.Abc123.XXXXXXXXXXXXXXXXXXXXXXXXXXX and key AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" | ~/.claude/scripts/sanitize-log.sh
```

Expected: both values replaced with `[REDACTED:...]`.

**Step 3: Verify Layer 3 (gitleaks)**

```bash
cd ~/.claude
echo "test_secret=sk-1234567890abcdefghij" > /tmp/test-secret.txt
cp /tmp/test-secret.txt ./test-secret.txt
git add test-secret.txt
git commit -m "test gitleaks"
# Should be blocked
git reset HEAD test-secret.txt
rm test-secret.txt /tmp/test-secret.txt
```

Expected: commit blocked by gitleaks.

**Step 4: Commit verification results**

No commit — just verification.

---

### Task 10: Migrate and Clean Up

**Step 1: Verify all secrets load from cache (not from .zshrc.secrets)**

```bash
# Temporarily rename .zshrc.secrets to prove we don't need it
mv ~/.zshrc.secrets ~/.zshrc.secrets.bak

# Open new subshell
zsh -c 'source ~/.zshrc; echo "OPENAI: ${OPENAI_API_KEY:+set}"; echo "GEMINI: ${GEMINI_API_KEY:+set}"'
```

Expected: both say `set` (loaded from cache, not from the old file).

**Step 2: Delete the old secrets file**

```bash
rm ~/.zshrc.secrets.bak
```

**Step 3: Final commit**

```bash
cd ~/.claude && git add -A && git commit -m "feat: complete secrets management system — vault, sanitizer, gitleaks"
git push
```
