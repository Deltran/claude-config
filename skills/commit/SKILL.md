---
name: commit
description: Stage, commit, and push changes. Handles both "commit everything" and "commit just these files" scenarios.
user_invocable: true
---

# Commit & Push

## Overview

Handle the full git commit workflow — stage files, write a good commit message, and push. Adapts to what the user wants: everything, or just specific files.

## Steps

### 1. Check git status

Run `git status` and `git diff --stat` to see what's changed (staged and unstaged).

If nothing has changed, tell the user and stop.

### 2. Determine what to stage

**If the user specified files or a scope** (e.g., "commit the battle changes", "commit the new hero files"):
- Stage only the files matching that scope. Use your understanding of the codebase to pick the right files.
- Show the user what you're staging and confirm.

**If the user said "commit and push" or just invoked `/commit` with no scope**:
- Stage all changed files (`git add -A`).

**If there's a mix of unrelated changes** and the user didn't specify:
- Show the groups of changes and ask what to include using AskUserQuestion.

### 3. Write commit message

Run `git diff --cached --stat` and `git diff --cached` to understand what's staged.

Draft a concise commit message:
- Summarize the "why" not just the "what"
- Match the style of recent commits (`git log --oneline -5`)
- Keep the first line under 72 characters

Present the message to the user. They can approve, edit, or provide their own.

### 4. Commit

Commit with the approved message. Always include the co-author trailer:

```
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

### 5. Push

Run `git push`.

If it fails:
- **Behind remote**: Run `git pull --rebase` then push again
- **No upstream**: Run `git push -u origin <branch>`
- **Auth failure**: Report the error and suggest checking SSH vs HTTPS config
- **Other**: Report the error clearly, don't retry blindly

### 6. Confirm

Show a one-line summary: branch, commit hash, and what was pushed.
