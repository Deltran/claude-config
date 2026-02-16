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

# Cleanup: delete state files older than 48h
find "$SESSION_DIR" -type f -name "*.md" -mmin +2880 -delete 2>/dev/null || true

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
      [ -f "$peer_file" ] || continue  # file may have been deleted since find
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
