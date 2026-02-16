#!/bin/bash
# Hook: SessionStart
# Loads the last 2 days of daily logs into Claude's context.
# Gives persistent memory of what was worked on recently.

LOG_DIR="$HOME/.claude/logs"

if [ ! -d "$LOG_DIR" ]; then
  exit 0
fi

TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

OUTPUT=""

# Load yesterday's log if it exists
if [ -f "$LOG_DIR/$YESTERDAY.md" ]; then
  OUTPUT+="$(cat "$LOG_DIR/$YESTERDAY.md")"
  OUTPUT+=$'\n\n---\n\n'
fi

# Load today's log if it exists
if [ -f "$LOG_DIR/$TODAY.md" ]; then
  OUTPUT+="$(cat "$LOG_DIR/$TODAY.md")"
fi

if [ -n "$OUTPUT" ]; then
  echo "## Recent Session History"
  echo ""
  echo "$OUTPUT"
fi

exit 0
