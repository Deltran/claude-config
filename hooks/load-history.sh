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
