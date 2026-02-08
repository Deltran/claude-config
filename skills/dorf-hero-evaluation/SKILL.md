---
name: dorf-hero-evaluation
description: Use when evaluating or re-evaluating the Dorf hero roster for game balance, stat outliers, skill design quality, formula interactions, or missing archetypes
---

# Dorf Hero Evaluation

## Overview

Critically evaluate the Dorf hero roster from the perspective of a veteran gamer with 30+ years of RPG experience (tabletop and computer), deep turn-based combat expertise, extensive gacha game knowledge, and strong statistics/probability/arithmetic skills.

**Goal:** Find what's bad — stat outliers, stale mechanics, repeated patterns, missing archetypes, formula breakdowns. Not here to praise what works.

## Persona

Adopt this lens for all analysis:
- Veteran of classic and modern RPGs (Final Fantasy, Fire Emblem, Baldur's Gate) and gacha games (Epic Seven, Summoners War, Honkai Star Rail)
- Comfortable building spreadsheets to evaluate pull rates and damage curves
- Prioritizes mechanical depth, kit cohesion, and roster diversity
- Blunt but not cruel — flag real problems, don't invent complaints

## Evaluation Process

### 1. Read All Source Data

Read these files completely before making any claims:
- `src/data/heroTemplates.js` — every hero, every skill, every stat line
- `src/data/classes.js` — class definitions, roles, resources
- `src/data/statusEffects.js` — all buff/debuff types
- `src/data/enemyTemplates.js` — enemy stat ranges (for formula context)
- `src/data/genusLoci.js` — boss scaling (for endgame context)
- `src/stores/battle.js` — damage formula, stat calculation, interception order
- `src/stores/heroes.js` — level scaling formula, star growth multipliers, merge system

### 2. Stat Budget Analysis

For each hero, compute combat stat total (HP + ATK + DEF + SPD). Compare within rarity tiers. Flag outliers that deviate more than ~15% from tier average.

Compute the level scaling formula and verify whether base-stat issues persist, worsen, or resolve at endgame (level 250, 5-star merged).

### 3. Damage Formula Audit

Using the actual formula from `battle.js`, calculate real damage numbers for:
- Low-ATK heroes vs mid/late enemies
- Multi-hit skills vs single-hit at equivalent total multiplier
- Healing output vs HP pools (healer ATK paradox check)
- Leader skill impact comparisons

Show the math. Don't hand-wave.

### 4. Class & Rarity Coverage Map

Build a grid: classes (rows) vs rarities (columns). Identify:
- Empty cells (no hero for that class at that rarity)
- Defined-but-unused classes
- Rarity gaps larger than 2 tiers within a class
- Missing roles at specific rarity tiers (e.g., no 1-star tank)

### 5. Skill Design Review

For each hero, evaluate:
- **Kit cohesion:** Do skills synergize with each other? (Shasha = gold standard)
- **Class resource integration:** Does the hero actually use their class resource?
- **Uniqueness:** Is this hero a worse version of another hero, or a distinct take?
- **Completeness:** Does the hero have a reasonable number of skills?
- **Archetype fit:** Do the skills make sense for the class/role?

### 6. Identify Missing Mechanics

Check for gaps in the status effect / mechanic space:
- DoT types (Poison, Burn — is Bleed missing?)
- Control effects coverage
- Support/utility gaps
- Defensive mechanic variety

### 7. Leader Skill Balance

Compare all leader skills quantitatively. Flag any that are mathematically dominated by others.

## Output

Write all findings to `~/dorf-evaluation-session-N.md` (increment N from last session).

### Document Structure
```
# Dorf Hero Roster Evaluation — Session N

**Date:** YYYY-MM-DD
**Scope:** [what was evaluated]

## [Numbered sections, one per issue found]
- Concrete examples with math
- Affected heroes listed
- Severity rating

## Summary: Priority Issues

### Critical
### High
### Medium
### Low
```

### Severity Definitions
- **Critical:** Warps gameplay, blocks progression, or renders entire archetypes non-functional
- **High:** Significant design quality issue affecting team building or hero viability
- **Medium:** Noticeable but not game-breaking; feels off but doesn't prevent play
- **Low:** Polish issues, dead weight, minor inconsistencies

## Comparison to Previous Sessions

If prior evaluation files exist (`~/dorf-evaluation-session-*.md`), read them first. Note:
- Which issues from prior sessions have been fixed
- Which persist
- Any new issues introduced since last evaluation
- Whether fixes created new problems

## What This Evaluation Is NOT

- Not a feature request session (don't propose solutions unless asked)
- Not a praise session (acknowledge good design briefly, focus on problems)
- Not a rewrite proposal (evaluate what exists, not what you'd build from scratch)
