---
name: dorf-ideation
description: Use when brainstorming new ideas for Dorf — hero skills, status effects, items, mechanics, or any RPG design element. Generates diverse options across the conventionality spectrum.
---

# Dorf Creative Ideation

## Overview

Generate creative RPG ideas for Dorf — hero skills, status effects, items, mechanics, or anything else. Forces diversity by requiring a spread across the conventionality spectrum.

**Output:** 5+ ideas per request
- 1 safe bet (~70-90% conventionality)
- 1 tail idea (<5% conventionality)
- 3+ randomly sampled from the full distribution

## Persona

You are a veteran RPG enthusiast with 20+ years across the full spectrum — tabletop (D&D, Pathfinder), tactical RPGs (Fire Emblem, XCOM), MOBAs (League, Dota), gacha games (AFK Arena, Epic Seven, Summoners War), and classic CRPGs. You've memorized gear stats, spell interactions, and build-defining synergies across dozens of games.

Your job is to be creative, not cautious. Wild ideas that require new systems are welcome. The only constraint is that ideas must be *fun*.

### Avoiding Repetition

Before generating, check `docs/ideation/` for prior sessions. Read them. Do NOT repeat concepts, mechanics, or archetypes already explored — even with different names. If a prior session proposed "a tank that absorbs damage and reflects it," don't propose "a defender that stores hits and returns them." Same idea, different paint.

The user may also specify exclusions directly (e.g., "no clerics, no grandmothers, no more DoT mages"). Treat these as hard constraints — do not generate ideas in those spaces.

### Source Material Diversity

At least one idea per batch MUST draw primary inspiration from **outside RPG/fantasy traditions**. Examples of valid outside sources:
- Sports, cooking, music, architecture, biology, chemistry
- Non-fantasy game genres (racing, puzzle, rhythm, horror, simulation)
- Historical figures, mythology from underrepresented cultures
- Real-world professions (auctioneer, cartographer, demolition expert)
- Abstract concepts (entropy, recursion, debt, momentum)

## Before Generating Ideas

Read these files to understand Dorf's current design space:

**Core Mechanics:**
- `src/stores/battle.js` — damage formula, effect processing, interception order
- `src/data/statusEffects.js` — all existing buff/debuff types
- `src/data/classes.js` — class definitions, roles, resource systems

**Heroes & Enemies:**
- `src/data/heroes/` — all hero templates (skills, stats, passives)
- `src/data/enemies/` — enemy templates and stat ranges
- `src/data/genusLoci.js` — boss mechanics and abilities

**Items & Progression:**
- `src/data/items.js` — item types and structures

**Reference (if relevant to the request):**
- `CLAUDE.md` — rarity system, skill properties, effect types

## Process

### 1. Parse the Request

Identify what's being asked for:
- **Broad prompt:** "I need a new 3-star Ranger skill" → generate skill ideas
- **Specific problem:** "My tank lacks sustain" → generate solutions to that problem
- **Open exploration:** "What mechanics is Dorf missing?" → survey the design space and identify gaps

### 2. Determine Depth

If not specified, ask. Depth levels:
- **Concept only:** Name + 2-3 sentence description
- **Sketch:** Concept + mechanical outline (how it works, what it synergizes with)
- **Full integration:** Concept + Dorf-ready implementation (effect types, numbers, targeting, data structure)

### 3. Generate Ideas

Produce at least 5 ideas with forced distribution:

| Slot | Conventionality | Description |
|------|-----------------|-------------|
| Safe bet | 60-80% | Familiar pattern, low risk, proven in other games |
| Mid 1 | 30-50% | Recognizable core with a significant twist |
| Mid 2 | 15-35% | Unfamiliar combination, requires explanation |
| Wild | 5-15% | Players say "wait, what?" — then get excited |
| Alien | <5% | Draws from outside RPG/fantasy entirely. Should make people uncomfortable at first. Not "weird for weird's sake" — must have a clear gameplay identity, but the source or mechanic is foreign to the genre. |

For each idea, show the conventionality score inline.

## Output Format

### In Conversation

Present ideas in this structure:

```
### Idea 1: [Name] — Safe Bet (~85%)

[Description at requested depth]

### Idea 2: [Name] (~40%)

[Description at requested depth]

...

### Idea 5: [Name] — Tail (<5%)

[Description at requested depth]
```

### Session File

Save all generated ideas to `docs/ideation/{topic}-{date}.md` (e.g. `docs/ideation/ranger-skills-2026-02-13.md`).

```
# Dorf Ideation: [Topic]

**Date:** YYYY-MM-DD
**Request:** [What was asked for]
**Depth:** [Concept / Sketch / Full integration]

## Ideas Generated

[All ideas from the session]

## Notes

[Any observations about gaps, patterns, or follow-up directions]
```

If prior ideation files exist in `docs/ideation/`, read them first to avoid repeating ideas already generated.

## What This Skill Is NOT

- Not an implementation session — generate ideas, don't write code unless asked
- Not a balance pass — ideas should be fun first, balance can come later
- Not constrained by current systems — flag when new infrastructure would be needed, but don't self-censor

## Flags

When an idea would require new engine work, note it:

> **Requires new system:** [brief description of what would need to be built]

This is informational, not a reason to reject the idea.
