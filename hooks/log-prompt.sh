#!/bin/bash
# Hook: UserPromptSubmit
# Appends each user prompt to a daily log file with timestamp.
# No tool usage — runs automatically via hook.

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# Skip empty prompts and slash commands
if [ -z "$PROMPT" ] || [[ "$PROMPT" == /* ]]; then
  exit 0
fi

# Skip system-generated messages (task notifications, XML tags)
if [[ "$PROMPT" == *"<task-notification>"* ]] || \
   [[ "$PROMPT" == *"<task-id>"* ]] || \
   [[ "$PROMPT" == *"<system-reminder>"* ]] || \
   [[ "$PROMPT" == *"<tool-use-id>"* ]] || \
   [[ "$PROMPT" == *"<output-file>"* ]] || \
   [[ "$PROMPT" == *"<status>"* ]] || \
   [[ "$PROMPT" == *"<summary>"* ]] || \
   [[ "$PROMPT" == *"Read the output file to retrieve"* ]]; then
  exit 0
fi

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
HOSTNAME=$(hostname)
LOG_DIR="$HOME/.claude/logs/$HOSTNAME"
LOG_FILE="$LOG_DIR/$DATE.md"

mkdir -p "$LOG_DIR"

# Create header if new file
if [ ! -f "$LOG_FILE" ]; then
  echo "# Daily Log — $DATE" > "$LOG_FILE"
fi

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

echo "" >> "$LOG_FILE"
echo "**$TIME** — $TRUNCATED" >> "$LOG_FILE"

exit 0
