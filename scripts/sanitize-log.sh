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

# --- Prong 2: Exact value matching from secrets cache ---
SECRETS_BIN="$HOME/.local/bin/secrets"
if [[ -x "$SECRETS_BIN" ]]; then
  while IFS='=' read -r key val; do
    if [[ -n "$key" && -n "$val" && ${#val} -ge 8 ]]; then
      # Escape special sed chars in the value
      escaped=$(printf '%s' "$val" | sed 's/[&/\]/\\&/g')
      INPUT=$(echo "$INPUT" | sed "s|${escaped}|[REDACTED:${key}]|g")
    fi
  done < <("$SECRETS_BIN" values 2>/dev/null || true)
fi

printf '%s' "$INPUT"
