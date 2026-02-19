---
description: Accumulator for operational friction signals noticed during sessions. Triggers /rethink when count reaches threshold.
---
# Observations

Capture friction, surprises, or recurring patterns noticed during work sessions.

## Format

Each observation is a separate .md file with a prose-sentence filename:
- `subagents-lose-context-about-test-patterns.md`
- `debugging-mysql-always-requires-three-attempts.md`

File contents: 2-5 sentences describing what was observed, when/where, and why it matters.

## Lifecycle

- Created during or after sessions when friction is noticed
- Reviewed during `/rethink` sessions (triggered when count >= 10)
- After review: either promoted into a CLAUDE.md/MEMORY.md rule, or deleted as noise
