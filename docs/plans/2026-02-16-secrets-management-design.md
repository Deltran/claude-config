# Personal Secrets Management System

**Date:** 2026-02-16
**Status:** Approved

## Problem

Secrets leak into version-controlled files through two vectors:
1. Pasting tokens into chat sessions that get logged verbatim
2. No safety net to catch accidental secret commits across repos

Current state: secrets scattered across `.zshrc.secrets`, multiple `.env` files, and potentially session logs. Bitwarden is already in use but the CLI's session expiry makes it painful for repeated use and impossible for automation.

## Solution: Three-Layer Defense

### Layer 1: Bitwarden Vault + Encrypted Cache

**Single source of truth:** All secrets stored in a Bitwarden folder called `cli-secrets` as Secure Notes (name = env var name, notes = secret value).

**`~/.local/bin/secrets` CLI wrapper:**
- `secrets refresh` — Unlocks BW, pulls all items from `cli-secrets` folder, encrypts into `~/.secrets-cache.age` using `age`.
- `secrets load` — Decrypts cache, prints `export KEY=VALUE` lines for eval. Always works if cache + age key exist.
- `secrets get <name>` — Decrypts cache, prints a single value. For use in scripts.

**Shell startup flow (.zshrc):**
```
terminal opens
  -> is BW_SESSION valid? (bw status, 2s timeout)
    -> yes: secrets refresh (update cache silently)
    -> no: prompt for master password (read -t 5, non-blocking)
      -> success: bw unlock, export BW_SESSION, secrets refresh
      -> fail/timeout: skip silently
  -> secrets load (always runs from cache)
```

**Key properties:**
- Non-blocking: 5-second timeout on password prompt. Automated processes and failed auth just skip.
- Existing sessions unaffected: BW_SESSION lives in each shell's env, cache persists on disk.
- Cache TTL: If cache mtime > 24h, prints subtle reminder on shell startup. Non-blocking.
- Automation (cron, discord bot, morning briefing): calls `secrets load` or `secrets get`, reads from cache, never calls `bw` directly.

**Encryption:**
- `~/.secrets-cache.age` — encrypted with `age`
- `~/.secrets-cache-key.txt` — age identity file, permissions 600, never committed anywhere

**Migration:** After setup, move secrets from `~/.zshrc.secrets` into Bitwarden, replace `source ~/.zshrc.secrets` with `eval "$(secrets load)"`, then delete `~/.zshrc.secrets`.

### Layer 2: Log Sanitizer

**Problem:** User pastes a token into chat, session log hook records it verbatim.

**Script:** `~/.claude/scripts/sanitize-log.sh`

**Two-pronged matching:**
1. **Known patterns:** Discord tokens (`[MN][A-Za-z0-9]{23,}\.…`), OpenAI keys (`sk-…`), Google keys (`AIzaSy…`), UUID-format tokens, long hex/base64 strings.
2. **Exact value matching:** Decrypts secrets cache, matches actual secret values found in content. Replaces with `[REDACTED:KEY_NAME]`. This catches secrets that don't match any standard regex pattern.

**Integration:** Called by the session log hook before writing content to disk. Single pass over content.

**Tradeoff:** Sanitizer briefly decrypts cache to know what to match. Values exist in memory for duration of script call only. Acceptable for personal machine.

### Layer 3: Gitleaks Global Pre-commit Hook

**Last line of defense.** Blocks any commit containing secret patterns across all repos.

**Setup:**
- Install `gitleaks` (single binary)
- `~/.config/git/hooks/pre-commit` runs `gitleaks protect --staged`
- Git global config: `core.hooksPath = ~/.config/git/hooks/`
- Global hook chains to per-repo hooks if they exist

**Coverage:** 700+ built-in rules for Discord, AWS, GCP, GitHub, Slack, generic API keys, private keys, etc.

**Override:** `# gitleaks:allow` inline comment or `.gitleaksignore` file for intentional false positives (test fixtures, docs).

## Dependencies

- `age` — file encryption (single static binary, no runtime deps)
- `gitleaks` — secret scanner (single static binary, no runtime deps)
- `jq` — already installed (for parsing BW output)
- `bw` — already installed (Bitwarden CLI)

## Files Created/Modified

| File | Action |
|------|--------|
| `~/.local/bin/secrets` | Create — CLI wrapper |
| `~/.secrets-cache.age` | Create — encrypted secrets cache |
| `~/.secrets-cache-key.txt` | Create — age identity (600 perms) |
| `~/.claude/scripts/sanitize-log.sh` | Create — log sanitizer |
| `~/.config/git/hooks/pre-commit` | Create — global gitleaks hook |
| `~/.gitconfig` | Modify — set core.hooksPath |
| `~/.zshrc` | Modify — replace .zshrc.secrets source with secrets load + BW unlock flow |
| `~/.zshrc.secrets` | Delete — after migration |

## Implementation Order

1. Install `age` and `gitleaks`
2. Generate age key at `~/.secrets-cache-key.txt` (chmod 600)
3. Create `~/.local/bin/secrets` script
4. Create Bitwarden `cli-secrets` folder, add all current secrets as Secure Notes
5. Run `secrets refresh` to create initial cache
6. Update `~/.zshrc` with new startup flow
7. Wire sanitizer into session log hook
8. Set up global gitleaks pre-commit hook
9. Verify all layers work
10. Delete `~/.zshrc.secrets`
