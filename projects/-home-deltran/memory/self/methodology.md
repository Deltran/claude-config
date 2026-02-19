---
description: How Claude and the user work together -- the delegation model, session continuity mechanisms, and operational learning loop that define the workflow.
---
# Methodology

## Subagent Delegation Model

The core pattern: main window orchestrates, subagents execute. This preserves context quality in the main window (the "smart zone" is roughly the first ~40% of context; chaining heavy work inline degrades attention).

- **Sonnet** for well-specified coding tasks (implementations, TDD, lookups)
- **Opus** for reasoning-heavy tasks (debugging, architecture, multi-hop investigation)
- Subagents receive structured prompts with known-good constraints to prevent re-deriving verified facts

## Session Continuity

Multiple mechanisms keep work coherent across sessions:

1. **Session state persistence** -- periodic summaries written to `~/.claude/sessions/{project}/{sessionId}.md`
2. **load-history.sh** (SessionStart hook) -- loads last 2 days of raw daily logs, session state files, work inbox, peer session awareness, and ops threshold checks
3. **Structured handoff blocks** -- subagents end with `=== HANDOFF ===` blocks capturing work done, learnings (friction/surprise/methodology signals), and next steps

## Operational Learning Loop

A lightweight feedback system that captures friction as it happens and processes it in batches:

- `ops/observations/` -- individual friction/surprise notes (prose-sentence filenames, 2-5 sentences)
- `ops/tensions/` -- unresolved conflicts between rules or preferences
- `ops/methodology/` -- notes documenting WHY the system is configured a certain way
- Thresholds trigger review: 10+ observations or 5+ tensions prompt a `/rethink` session

## Description-as-Discovery-Filter

Every memory/note file carries `description:` YAML frontmatter. The description must add information beyond the title -- mechanism, implication, or scope. Cold-read test: "Can you predict the file's content from title + description alone?"

## Execution Preferences

- Git worktrees for plan-based work (95%+ of the time)
- Suggest `/clear` after plan finalization, before subagent execution
- Verify assumptions before writing code -- list them, test them, then implement
- After 2 failed attempts with the same approach, try a fundamentally different one
