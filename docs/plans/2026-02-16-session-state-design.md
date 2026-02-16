# Session State Persistence

Lightweight cross-session and compaction-surviving state for Claude Code.

## Problem

When Claude Code auto-compacts (at ~83% context usage), session context is lost. When starting a new session on a project with other active sessions, there's no awareness of concurrent work. Daily logs capture prompts but not intent, decisions, or work state.

## Approach

**CLAUDE.md-driven writes + enhanced SessionStart reads.** Claude writes its own session state periodically via the Write tool (instructed by CLAUDE.md). On session start, a hook loads the current session's state (compaction recovery) plus recent peer sessions (awareness).

No database, no background worker, no new dependencies.

## File Structure

```
~/.claude/sessions/
  {project}/
    {sessionId}.md
```

- **Project name**: derived from CWD — basename of the repo/directory (e.g., `~/code/dorf` → `dorf`, `~` → `home`)
- **Session ID**: from Claude Code's hook input or environment
- **Cleanup**: files older than 48h deleted on SessionStart

## State File Format

```markdown
# Session State
**Project:** dorf
**Branch:** feat/hard-mode-enemies
**Updated:** 2026-02-16 14:35

## What I'm Doing
Implementing hard mode enemy overrides for forest regions.

## Key Decisions
- Using isMinibossWave flag instead of enemy count check
- forest_01 and forest_02 get +2 enemies in hard mode

## Files Touched
- src/screens/BattleScreen.vue
- src/data/hardMode/nodeOverrides.js

## Blockers / Open
- Tavern agent sprites sometimes don't load (noted as bug for later)

## Next
- Apply same pattern to mountain regions
```

~100-200 tokens. Intent-focused, no raw tool outputs.

## Write Triggers

1. **CLAUDE.md instruction**: Claude updates its session state file roughly every 15-20 tool calls, or after completing a significant milestone (task completion, merge, etc.)
2. **No Stop hook write**: Stop fires after Claude is done, so Claude can't Write at that point. Periodic writes are the mechanism.

## Read Triggers (SessionStart)

Enhanced `load-history.sh` hook:

1. Parse session ID and CWD from hook input JSON
2. Derive project name from CWD
3. Look for `~/.claude/sessions/{project}/*.md`
4. If own session file exists → load full contents (compaction recovery)
5. Load 2-3 most recent peer session files → condensed view (awareness)
6. Delete files older than 48h
7. Inject alongside daily logs as additional context

## Injection Format

```markdown
## Active Sessions (dorf)

### This Session (resuming)
[full contents of own session file]

### Recent Peer Sessions
**Session def456 (2 hours ago):**
- Implementing gacha pity progress bar
- On branch: feat/gacha-juice

**Session ghi789 (45 min ago):**
- Running UI critiques across all screens
- On branch: main
```

Own session: full contents. Peers: first two lines of "What I'm Doing" + branch only.

## Implementation Components

1. **`~/.claude/CLAUDE.md` addition** — instruction block for periodic state writes
2. **`~/.claude/scripts/load-session-state.sh`** — new script called from load-history.sh, handles read + cleanup + formatting
3. **`~/.claude/hooks/load-history.sh` enhancement** — call load-session-state.sh and append output
4. **`~/.claude/sessions/` directory** — created on first write

## What This Does NOT Do

- No observation extraction from tool outputs
- No SQLite or persistent storage beyond plain markdown files
- No background worker process
- No modification to compaction behavior itself
- No hook on every tool call
