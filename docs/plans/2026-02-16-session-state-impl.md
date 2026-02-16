# Session State Persistence — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Survive context compaction and provide cross-session awareness via lightweight state files.

**Architecture:** Claude writes its own session state periodically (CLAUDE.md instruction). On SessionStart, a script loads the session's own state (compaction recovery) or recent peer states (new session awareness). Files keyed by `{project}/{sessionId}.md` under `~/.claude/sessions/`.

**Tech Stack:** Bash (hooks/scripts), Markdown (state files), jq (JSON parsing)

---

### Task 1: Create the sessions directory and load-session-state.sh script

**Files:**
- Create: `~/.claude/sessions/` (directory)
- Create: `~/.claude/scripts/load-session-state.sh`

**Step 1: Create the directory**

```bash
mkdir -p ~/.claude/sessions
```

**Step 2: Write the load-session-state.sh script**

Create `~/.claude/scripts/load-session-state.sh` with this content:

```bash
#!/bin/bash
# load-session-state.sh — Load session state files on SessionStart.
# Called from load-history.sh with two args: SESSION_ID and CWD.
# Also receives SOURCE as $3 ("startup", "resume", "clear", "compact").
#
# Behavior:
#   - Derives project name from CWD (basename of repo directory)
#   - If source=compact: loads only THIS session's state file (compaction recovery)
#   - Otherwise: loads own file (if exists) + 2-3 most recent peer files (awareness)
#   - Cleans up files older than 48h
#   - Outputs markdown to stdout for hook injection

set -euo pipefail

SESSION_ID="${1:-}"
CWD="${2:-$PWD}"
SOURCE="${3:-startup}"

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

# Derive project name: use basename of CWD, but if it's $HOME use "home"
if [ "$CWD" = "$HOME" ]; then
  PROJECT="home"
else
  PROJECT="$(basename "$CWD")"
fi

SESSION_DIR="$HOME/.claude/sessions/$PROJECT"
OWN_FILE="$SESSION_DIR/$SESSION_ID.md"

# Create project session dir if it doesn't exist
mkdir -p "$SESSION_DIR"

# Cleanup: delete files older than 48h
find "$SESSION_DIR" -name "*.md" -mmin +2880 -delete 2>/dev/null || true

# Collect output
OUTPUT=""

# Load own session file if it exists (compaction recovery)
if [ -f "$OWN_FILE" ]; then
  OUTPUT+="## Active Sessions ($PROJECT)"
  OUTPUT+=$'\n\n'
  OUTPUT+="### This Session (resuming)"
  OUTPUT+=$'\n'
  OUTPUT+="$(cat "$OWN_FILE")"
  OUTPUT+=$'\n\n'
fi

# If not compaction, also load recent peer sessions for awareness
if [ "$SOURCE" != "compact" ]; then
  # Get up to 3 most recent peer files (not our own), sorted by modification time
  PEERS=$(find "$SESSION_DIR" -name "*.md" ! -name "$SESSION_ID.md" -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn \
    | head -3 \
    | awk '{print $2}')

  if [ -n "$PEERS" ]; then
    if [ -z "$OUTPUT" ]; then
      OUTPUT+="## Active Sessions ($PROJECT)"
      OUTPUT+=$'\n\n'
    fi
    OUTPUT+="### Recent Peer Sessions"
    OUTPUT+=$'\n'

    while IFS= read -r peer_file; do
      [ -z "$peer_file" ] && continue
      peer_id="$(basename "$peer_file" .md)"
      # Calculate age
      file_age_min=$(( ($(date +%s) - $(stat -c %Y "$peer_file")) / 60 ))
      if [ "$file_age_min" -lt 60 ]; then
        age_str="${file_age_min} min ago"
      else
        age_hours=$(( file_age_min / 60 ))
        age_str="${age_hours}h ago"
      fi
      # Extract first line of "What I'm Doing" section and branch
      doing=$(sed -n '/^## What I.*Doing/,/^##/{/^## What/d;/^##/d;/^$/d;p;}' "$peer_file" | head -1)
      branch=$(grep -oP '(?<=\*\*Branch:\*\* ).*' "$peer_file" | head -1)
      OUTPUT+=$'\n'"**Session ${peer_id:0:7}** (${age_str}):"
      [ -n "$doing" ] && OUTPUT+=$'\n'"- $doing"
      [ -n "$branch" ] && OUTPUT+=$'\n'"- Branch: \`$branch\`"
      OUTPUT+=$'\n'
    done <<< "$PEERS"
  fi
fi

if [ -n "$OUTPUT" ]; then
  echo "$OUTPUT"
fi

exit 0
```

**Step 3: Make it executable**

```bash
chmod +x ~/.claude/scripts/load-session-state.sh
```

**Step 4: Verify it runs without error (no sessions yet, should be silent)**

Run: `~/.claude/scripts/load-session-state.sh "test-session-123" "$HOME/code/dorf" "startup"`
Expected: No output, exit 0

**Step 5: Commit**

```bash
git -C ~/.claude add scripts/load-session-state.sh
git -C ~/.claude commit -m "feat: add load-session-state.sh for session state persistence"
```

---

### Task 2: Enhance load-history.sh to call load-session-state.sh

**Files:**
- Modify: `~/.claude/hooks/load-history.sh`

**Step 1: Read current load-history.sh to confirm state**

Read `~/.claude/hooks/load-history.sh` — currently loads daily logs only.

**Step 2: Update load-history.sh to parse hook input and call load-session-state.sh**

The SessionStart hook receives JSON on stdin with fields: `session_id`, `cwd`, `source`, `hook_event_name`.

Replace `~/.claude/hooks/load-history.sh` with:

```bash
#!/bin/bash
# Hook: SessionStart
# Loads the last 2 days of daily logs into Claude's context,
# then loads session state files for compaction recovery and peer awareness.

# Read hook input from stdin
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"' 2>/dev/null)

LOG_DIR="$HOME/.claude/logs"

OUTPUT=""

# --- Daily Logs ---
if [ -d "$LOG_DIR" ]; then
  TODAY=$(date +%Y-%m-%d)
  YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

  if [ -f "$LOG_DIR/$YESTERDAY.md" ]; then
    OUTPUT+="$(cat "$LOG_DIR/$YESTERDAY.md")"
    OUTPUT+=$'\n\n---\n\n'
  fi

  if [ -f "$LOG_DIR/$TODAY.md" ]; then
    OUTPUT+="$(cat "$LOG_DIR/$TODAY.md")"
  fi
fi

if [ -n "$OUTPUT" ]; then
  echo "## Recent Session History"
  echo ""
  echo "$OUTPUT"
  echo ""
fi

# --- Session State ---
LOADER="$HOME/.claude/scripts/load-session-state.sh"
if [ -x "$LOADER" ] && [ -n "$SESSION_ID" ]; then
  "$LOADER" "$SESSION_ID" "$CWD" "$SOURCE"
fi

exit 0
```

**Step 3: Verify the hook still works for daily logs**

Run: `echo '{"session_id":"test","cwd":"/home/deltran/code/dorf","source":"startup","hook_event_name":"SessionStart"}' | ~/.claude/hooks/load-history.sh`
Expected: Daily log output followed by (empty) session state section. No errors.

**Step 4: Commit**

```bash
git -C ~/.claude add hooks/load-history.sh
git -C ~/.claude commit -m "feat: enhance SessionStart hook to load session state files"
```

---

### Task 3: Add CLAUDE.md instruction for periodic state writes

**Files:**
- Modify: `~/.claude/CLAUDE.md`

**Step 1: Read current CLAUDE.md**

Read `~/.claude/CLAUDE.md` to confirm current contents.

**Step 2: Add session state instruction block**

Append the following section to `~/.claude/CLAUDE.md`:

```markdown

## Session State Persistence

Periodically write a session state summary to `~/.claude/sessions/{project}/{sessionId}.md` where:
- `{project}` is the basename of the current working directory (e.g., `dorf`, `clip-editor`). If CWD is `$HOME`, use `home`.
- `{sessionId}` is your current session ID.

**When to write:**
- After completing a significant task or milestone
- Roughly every 15-20 tool calls during active work
- Before a long chain of subagent dispatches
- When you notice context is getting large

**What to write** (keep it ~100-200 tokens):

```
# Session State
**Project:** {project}
**Branch:** {current branch}
**Updated:** {YYYY-MM-DD HH:MM}

## What I'm Doing
{1-2 sentences about the current task}

## Key Decisions
{bullet list of important choices made this session}

## Files Touched
{bullet list of key files modified}

## Blockers / Open
{anything unresolved}

## Next
{what comes after current work}
```

**Do NOT:**
- Write state on every tool call (too noisy)
- Include raw tool outputs or file contents
- Write state for trivial/short sessions (< 5 tool calls)
```

**Step 3: Commit**

```bash
git -C ~/.claude add CLAUDE.md
git -C ~/.claude commit -m "feat: add CLAUDE.md instruction for periodic session state writes"
```

---

### Task 4: Integration test — simulate compaction recovery

**Step 1: Create a fake session state file**

```bash
mkdir -p ~/.claude/sessions/dorf
cat > ~/.claude/sessions/dorf/test-session-aaa.md << 'EOF'
# Session State
**Project:** dorf
**Branch:** feat/hard-mode-enemies
**Updated:** 2026-02-16 14:35

## What I'm Doing
Implementing hard mode enemy overrides for forest regions.

## Key Decisions
- Using isMinibossWave flag instead of enemy count check

## Files Touched
- src/screens/BattleScreen.vue

## Blockers / Open
- None

## Next
- Apply to mountain regions
EOF
```

**Step 2: Test compaction recovery (own session)**

Run: `echo '{"session_id":"test-session-aaa","cwd":"/home/deltran/code/dorf","source":"compact"}' | ~/.claude/hooks/load-history.sh 2>/dev/null | grep -A 20 "Active Sessions"`

Expected: Shows "This Session (resuming)" with full state file contents. Does NOT show peer sessions (source=compact).

**Step 3: Create a second fake peer session**

```bash
cat > ~/.claude/sessions/dorf/test-session-bbb.md << 'EOF'
# Session State
**Project:** dorf
**Branch:** main
**Updated:** 2026-02-16 13:00

## What I'm Doing
Running UI critiques across all screens.

## Key Decisions
- Using Cinzel for titles, Nunito for body

## Files Touched
- src/screens/GachaScreen.vue

## Blockers / Open
- None

## Next
- Implement critique feedback
EOF
```

**Step 4: Test new session awareness (startup)**

Run: `echo '{"session_id":"test-session-ccc","cwd":"/home/deltran/code/dorf","source":"startup"}' | ~/.claude/hooks/load-history.sh 2>/dev/null | grep -A 20 "Active Sessions"`

Expected: Shows "Recent Peer Sessions" with condensed view of both test-session-aaa and test-session-bbb. Does NOT show "This Session" (no file for ccc).

**Step 5: Clean up test files**

```bash
rm ~/.claude/sessions/dorf/test-session-aaa.md ~/.claude/sessions/dorf/test-session-bbb.md
```

**Step 6: Commit any test fixes if needed**

---

### Task 5: Update memory file with session state documentation

**Files:**
- Modify: `~/.claude/projects/-home-deltran/memory/MEMORY.md`

**Step 1: Add session state section to MEMORY.md**

Add a new section:

```markdown

## Session State Persistence
- **Purpose**: Survive context compaction + cross-session awareness
- **State files**: `~/.claude/sessions/{project}/{sessionId}.md`
- **Write trigger**: CLAUDE.md instruction — periodic writes (~15-20 tool calls) and milestones
- **Read trigger**: SessionStart hook — loads own file on compact, own + 3 peers on startup
- **Cleanup**: Files older than 48h auto-deleted on SessionStart
- **Format**: Intent-focused markdown (~100-200 tokens): what I'm doing, decisions, files, blockers, next
```

**Step 2: Commit**

```bash
git -C ~/.claude add projects/-home-deltran/memory/MEMORY.md
git -C ~/.claude commit -m "docs: add session state persistence to memory notes"
```
