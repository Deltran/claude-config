---
description: Save a summary of the current session to ~/claude-sessions/
allowed-tools: Bash(mkdir:*), Bash(basename:*), Write
---

Create a session summary file and save it to my home directory.

## Instructions

1. Get the project name from the current working directory (e.g., `/home/user/code/my-project` → `my-project`)
2. Create the directory `~/claude-sessions/<project-name>/` if it doesn't exist
3. Generate a filename using: `session-YYYY-MM-DD-HHMMSS-<context>.md` where `<context>` is:
   - Extract 2-4 keywords from the first user question (lowercase, hyphen-separated, no special chars)
   - Example: "analyze make-rpm script" → `session-2026-01-13-120000-analyze-make-rpm.md`
   - Keep context portion under 30 characters
4. Write a markdown file with the following sections:

```
# Claude Code Session Summary

**Date:** [current date and time]
**Working Directory:** [the project directory]

## Questions Asked

[List each question or request the user made, numbered]

## Answers & Responses

[For each question above, summarize the key points of Claude's response]

## Actions Taken

[List all concrete actions Claude Code performed, such as:]
- Files read
- Files created or edited
- Commands run
- Searches performed

## Session Outcome

[Brief summary of what was accomplished]

## Suggested Next Steps

[If applicable, list any logical follow-up tasks or unfinished work]
```

5. After saving, confirm the file location to the user
