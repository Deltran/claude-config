---
description: Save a summary of the current session to Obsidian (or ~/claude-sessions/ as fallback)
allowed-tools: Bash(mkdir:*), Bash(ls:*), Write
---

Create a session summary file, preferring my Obsidian vault.

## Instructions

### 1. Determine topic and tags

Analyze the full conversation and assign:

- **Topic folder** — pick the single best-fit folder name from this list (or create a new short lowercase name if nothing fits):
  - `dorf` — Dorf game development, hero design, balance, features, bugs
  - `skills` — Claude Code skill creation, editing, or workflow
  - `claude` — Claude Code configuration, setup, memory, tools
  - `research` — General research, exploration, learning
  - `devops` — Git, CI/CD, deployment, infra, dotfiles
  - `linux` — Linux setup, CLI tools, WSL
  - `hardware` — GPU, peripherals, hardware setup
  - `obsidian` — Obsidian vault management
  - `misc` — Anything that doesn't fit above

- **Tags** — assign 2-5 tags from the session content. Use lowercase, hyphen-separated. Mix broad and specific:
  - Broad: `dorf`, `claude-code`, `skills`, `devops`, `linux`, `research`, `obsidian`
  - Specific: `hero-design`, `battle-engine`, `bug-fix`, `refactor`, `ui`, `balance`, `gacha`, `local-llm`, `git`, `testing`, `tdd`, `animation`, `inventory`, etc.
  - Always include the topic folder name as a tag

### 2. Choose save location

- If `~/obsidian/pwaddingham/` exists, save to `~/obsidian/pwaddingham/Claude Sessions/<topic>/`
- Otherwise, fall back to `~/claude-sessions/<topic>/`
- Create the target directory if it doesn't exist

### 3. Generate filename

Use: `session-YYYY-MM-DD-HHMMSS-<context>.md` where `<context>` is:
- Extract 2-4 keywords from the session's main work (lowercase, hyphen-separated, no special chars)
- Example: "analyze make-rpm script" → `session-2026-01-13-120000-analyze-make-rpm.md`
- Keep context portion under 30 characters

### 4. Write the file

Write a markdown file with YAML frontmatter tags at the top, followed by the summary:

```
---
tags:
  - tag-one
  - tag-two
  - tag-three
---

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

### 5. Confirm

After saving, confirm the file location and list the assigned tags to the user.
