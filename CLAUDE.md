# Machine-Level Notes

## Session Continuity

When resuming work from a previous session, always check for session summary files, recent git log, and TODO/plan files before asking the user to re-explain context.

## Working Style

During brainstorming and ideation, freely offer alternative perspectives, tradeoffs, and opposing views. Once the user has chosen a direction, commit to it and build on it — don't push back unless there's a critical technical blocker.

## Failed Approach Recovery

After 2 failed attempts at the same task using the same approach, do not retry harder — try a fundamentally different approach. If no alternative is obvious, step back and reassess the problem before continuing.

## Verify Assumptions Before Writing Code

Before implementing or testing, explicitly list assumptions about how the system behaves — then write tests that validate those assumptions first. This catches wrong mental models early, before they compound into harder bugs. If an assumption turns out to be wrong, update the mental model and adjust the plan before proceeding.

## System Commands

Before running system-level commands (asdf, npm global installs, MySQL backups), verify the tool version and correct syntax first. Check `--version` and `--help` before executing. Never assume privilege levels — check with `whoami` if unsure.

## Custom Commands
- `pvsync` - Custom file sync command (defined in ~/.zshrc). Replaces the old `lein packetviper watch` workflow.

## Session State Persistence

Periodically write a session state summary to `~/.claude/sessions/{project}/{sessionId}.md` where:
- `{project}` is the basename of the current working directory (e.g., `dorf`, `clip-editor`). If CWD is `$HOME`, use `home`.
- `{sessionId}` is your current session ID.

**When to write:**
- After completing a significant task or milestone
- Roughly every 15-20 tool calls during active work
- Before a long chain of subagent dispatches
- When you notice context is getting large

**What to write** (keep it ~100-200 tokens):

```
# Session State
**Project:** {project}
**Branch:** {current branch}
**Updated:** {YYYY-MM-DD HH:MM}

## What I'm Doing
{1-2 sentences about the current task}

## Key Decisions
{bullet list of important choices made this session}

## Files Touched
{bullet list of key files modified}

## Blockers / Open
{anything unresolved}

## Next
{what comes after current work}
```

**Do NOT:**
- Write state on every tool call (too noisy)
- Include raw tool outputs or file contents
- Write state for trivial/short sessions (< 5 tool calls)
