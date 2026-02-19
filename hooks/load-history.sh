#!/bin/bash
# Hook: SessionStart
# Loads the last 2 days of daily logs into Claude's context,
# then loads session state files for compaction recovery and peer awareness.

# Read hook input from stdin
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"' 2>/dev/null)

LOG_BASE="$HOME/.claude/logs"

OUTPUT=""

# --- Daily Logs (from all machines) ---
if [ -d "$LOG_BASE" ]; then
  TODAY=$(date +%Y-%m-%d)
  YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

  # Cap each daily log at 10KB per machine (tail keeps the most recent entries)
  for MACHINE_DIR in "$LOG_BASE"/*/; do
    [ -d "$MACHINE_DIR" ] || continue
    MACHINE=$(basename "$MACHINE_DIR")

    if [ -f "$MACHINE_DIR/$YESTERDAY.md" ]; then
      OUTPUT+="### [$MACHINE] $YESTERDAY"
      OUTPUT+=$'\n'
      OUTPUT+="$(tail -c 10240 "$MACHINE_DIR/$YESTERDAY.md")"
      OUTPUT+=$'\n\n---\n\n'
    fi

    if [ -f "$MACHINE_DIR/$TODAY.md" ]; then
      OUTPUT+="### [$MACHINE] $TODAY"
      OUTPUT+=$'\n'
      OUTPUT+="$(tail -c 10240 "$MACHINE_DIR/$TODAY.md")"
      OUTPUT+=$'\n\n---\n\n'
    fi
  done
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

# --- Work Inbox ---
INBOX="$HOME/.claude/work-inbox.md"
if [ -f "$INBOX" ]; then
  PENDING=$(sed -n '/^## Pending/,/^## /{ /^- \[ \]/p }' "$INBOX")
  if [ -n "$PENDING" ]; then
    ITEM_COUNT=$(echo "$PENDING" | wc -l)
    echo ""
    echo "## Work Inbox ($ITEM_COUNT pending)"
    echo ""
    echo "$PENDING"
    echo ""
  fi
fi

# --- Active Sessions (peer awareness) ---
SESSION_DIR="$HOME/.claude/sessions"
if [ -d "$SESSION_DIR" ]; then
  PEER_INFO=""
  while IFS= read -r -d '' sfile; do
    # Skip if it's our own session
    BASENAME=$(basename "$sfile" .md)
    if [ "$BASENAME" = "$SESSION_ID" ]; then
      continue
    fi
    # Get project from parent dir name
    PROJECT=$(basename "$(dirname "$sfile")")
    # Get the "What I'm Doing" line
    DOING=$(sed -n '/^## What I.*Doing/,/^##/{/^[^#]/p}' "$sfile" | head -2 | tr '\n' ' ')
    BRANCH=$(grep -m1 'Branch:' "$sfile" | sed 's/.*Branch:\*\* //' | sed 's/\*\*//g')
    if [ -n "$DOING" ]; then
      PEER_INFO+="- **$PROJECT** ($BRANCH): $DOING"
      PEER_INFO+=$'\n'
    fi
  done < <(find "$SESSION_DIR" -name "*.md" -mmin -1440 -print0 2>/dev/null)

  if [ -n "$PEER_INFO" ]; then
    echo ""
    echo "## Active Sessions (last 24h)"
    echo ""
    echo "$PEER_INFO"
  fi
fi

# --- Operational Learning Loop (threshold checks) ---
OPS_DIR="$HOME/.claude/projects/-home-deltran/memory/ops"
if [ -d "$OPS_DIR/observations" ]; then
  OBS_COUNT=$(find "$OPS_DIR/observations" -name "*.md" ! -name "README.md" 2>/dev/null | wc -l)
  if [ "$OBS_COUNT" -ge 10 ]; then
    echo ""
    echo "CONDITION: $OBS_COUNT pending observations. Consider running a /rethink session."
  fi
fi
if [ -d "$OPS_DIR/tensions" ]; then
  TENS_COUNT=$(find "$OPS_DIR/tensions" -name "*.md" ! -name "README.md" 2>/dev/null | wc -l)
  if [ "$TENS_COUNT" -ge 5 ]; then
    echo ""
    echo "CONDITION: $TENS_COUNT unresolved tensions. Consider running a /rethink session."
  fi
fi

exit 0
