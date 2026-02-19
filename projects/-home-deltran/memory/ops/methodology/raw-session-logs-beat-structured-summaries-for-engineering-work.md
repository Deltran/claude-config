---
description: Why load-history.sh loads raw daily logs instead of curated summaries -- software engineering needs the texture of actual decisions, dead ends, and context, not just bullet points.
---
# Raw Session Logs Beat Structured Summaries for Engineering Work

The session continuity system (load-history.sh) loads raw daily logs capped at 20KB each, not structured summaries. This is deliberate.

Software engineering context is messy. A bullet point saying "fixed auth bug" loses the texture of which approaches were tried and rejected, what the actual error was, and what adjacent systems were involved. When resuming work, that texture matters -- it prevents re-exploring dead ends and preserves the reasoning chain that led to decisions.

Structured session state files exist too (in `~/.claude/sessions/`), but they complement the raw logs rather than replacing them. The state files give quick orientation ("what was I doing, what branch, what's next"); the raw logs give the actual engineering context needed to continue effectively.

The 20KB cap per day prevents context bloat while preserving the most recent (and most relevant) conversation history.
