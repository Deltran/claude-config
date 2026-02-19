---
description: Root memory file loaded into every session. Contains user preferences, workflow conventions, and pointers to detailed docs. Keep under 200 lines.
---
# Memory

## User Preferences

### Context Window Management
- **Default to delegating coding work to subagents** — user is protective of the main context window
- Keep the main window for orchestration, decision-making, and conversation
- Only do work inline when it's trivially small (one-liner fixes, simple git ops, quick reads)
- Delegate to agents: multi-file implementations, research/exploration, debugging, anything multi-step
- See [workflow-preferences.md](workflow-preferences.md) for details

## File Conventions

### Description Frontmatter
Every memory/note file should have YAML frontmatter with a `description:` field. The description must add information beyond the title -- mechanism, implication, or scope. Cold-read test: "Can you predict the file's content from title + description alone?" If not, rewrite it.

### Operational Learning Loop
Friction, surprises, and recurring patterns go in `ops/observations/` as individual .md files with prose-sentence filenames. Unresolved conflicts between rules go in `ops/tensions/`. The SessionStart hook monitors counts and flags when a `/rethink` session is needed.

## Subagent Handoff Protocol

When delegating significant work to a subagent, instruct it to end its response with:

```
=== HANDOFF ===
Work Done:
- {what was completed}

Learnings:
- [Friction]: {description} | NONE
- [Surprise]: {description} | NONE
- [Methodology]: {description} | NONE

Next:
- {what should happen next}
=== END HANDOFF ===
```

When a handoff contains a `[Friction]` or `[Surprise]` signal, consider capturing it as an observation in `ops/observations/`.

## Self-Space

Persistent identity, methodology, and goals live in `self/`:
- [self/identity.md](self/identity.md) -- who Claude is in this working relationship
- [self/methodology.md](self/methodology.md) -- how we work together (delegation, continuity, learning loop)
- [self/goals.md](self/goals.md) -- active projects and persistent threads (living document)

## Methodology Notes

`ops/methodology/` contains notes documenting WHY the system is configured the way it is. These are reference material, not instructions -- they explain the reasoning behind rules in CLAUDE.md and MEMORY.md so future sessions can make informed changes rather than cargo-culting existing patterns.

## The /rethink Cycle

When observations (>= 10) or tensions (>= 5) accumulate, the SessionStart hook flags that a `/rethink` session is needed. A /rethink session:

1. **Review** -- read all pending observations and tensions
2. **Detect patterns** -- look for clusters, recurring themes, or contradictions
3. **Propose changes** -- specific edits to CLAUDE.md, MEMORY.md, or new methodology notes
4. **Implement** -- apply approved changes
5. **Archive** -- delete processed observations/tensions (they've been absorbed into the system)

The system is not sacred. Evidence beats intuition. If accumulated friction says a rule is wrong, change the rule.
