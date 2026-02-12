# Machine-Level Notes

## Session Continuity

When resuming work from a previous session, always check for session summary files, recent git log, and TODO/plan files before asking the user to re-explain context.

## Working Style

During brainstorming and ideation, freely offer alternative perspectives, tradeoffs, and opposing views. Once the user has chosen a direction, commit to it and build on it — don't push back unless there's a critical technical blocker.

## System Commands

Before running system-level commands (asdf, npm global installs, MySQL backups), verify the tool version and correct syntax first. Check `--version` and `--help` before executing. Never assume privilege levels — check with `whoami` if unsure.

## Custom Commands
- `pvsync` - Custom file sync command (defined in ~/.zshrc). Replaces the old `lein packetviper watch` workflow.
