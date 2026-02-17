---
name: session-end
description: Save a summary of the current session to .claude/SESSION_STATE.md so the next session can pick up where we left off
user_invocable: true
---

**Context Marker:** Begin every response with 💾 to indicate session end mode.

# Session End

Write a session state file at `.claude/SESSION_STATE.md` (relative to the project root) that gives the next Claude session full context to resume without asking the user to re-explain anything.

## Steps

1. **Review the session.** Look at what was discussed, what changed, and what's still open.
2. **Check git state.** Run `git diff --stat` and `git log --oneline -5` to capture the current branch and recent work.
3. **Write `.claude/SESSION_STATE.md`** with the format below. If the file already exists, replace it entirely — this is a snapshot, not an append log.

## Format

```markdown
# Session State

**Branch:** [current branch]
**Last updated:** [date]

## What We Did
- [Bullet points summarizing accomplishments this session]

## What's Pending
- [Unfinished work, next steps, open questions]

## Blockers
- [Anything that's stuck or needs external input]
- [Or "None" if clear]

## Key Context
- [Anything the next session needs to know that isn't obvious from the code]
- [Decisions made, tradeoffs chosen, user preferences expressed]
```

## Rules

- Keep it concise. This gets read at the start of every session — don't write an essay.
- Focus on what the *next session* needs, not a diary of this one.
- If there are no blockers, write "None" — don't omit the section.
- If `.claude/` doesn't exist, create it.
- Don't commit the file. It's local working state.
