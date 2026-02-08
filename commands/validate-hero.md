---
description: Validate a hero's data against the battle engine. Finds unhandled properties, missing effect types, and implementation mismatches.
allowed-tools: Read, Glob, Grep, Bash(git rev-parse:*), Bash(git branch:*)
---

Validate the hero specified by the user: $ARGUMENTS

## Core Rules

- Report ONLY implementation mismatches: properties the engine doesn't handle, effect types that don't exist, conditions that aren't checked
- DO NOT comment on whether the hero is good, bad, balanced, or fun
- DO NOT suggest design changes or improvements
- Every issue must reference the specific hero data line AND the engine code that should (but doesn't) handle it
- If everything checks out, say so clearly

## What To Validate

For each hero, check these categories:

### 1. Skill Properties
- Every property on each skill (damagePercent, healSelfPercent, targetType, effects, etc.) must be handled in `src/stores/battle.js` skill execution logic
- Custom/novel properties (bonusIfTargetHas, conditionalEffects, onHitDebuffedTarget, etc.) must have explicit handling
- Resource costs (mpCost, rageCost, essenceCost, valorRequired) must match the hero's class resource system

### 2. Status Effects
- Every effect type referenced in skills must exist in `src/data/statusEffects.js` EffectType enum
- Every effect type must have a definition in effectDefinitions
- Effect properties (duration, value, custom fields) must be handled where the effect is processed in battle.js

### 3. Class Mechanics
- Hero's class must exist in `src/data/classes.js`
- Resource system properties must match class expectations (e.g., Bards shouldn't have mpCost, Berserkers need rageCost)
- Class-specific battle logic (Verse building, Rage gain, Focus checks) must handle this hero's skills

### 4. Conditional Logic
- useCondition values must be checked in executeEnemyTurn or relevant execution path
- conditionalEffects conditions must be handled
- bonusIfTargetHas effect types must be checkable at runtime

### 5. Data Shape
- Required fields present (id, name, class, stats, skills)
- Stats have expected properties (hp, atk, def, spd)
- Skills have required fields (name, damagePercent or noDamage, targetType)

## Investigation Process

1. Find and read the hero's data file (check `src/data/heroes/` by rarity folders)
2. Identify every skill property, effect type, and condition the hero uses
3. For each one, Grep for the property name in battle.js to find handling code, then Read the relevant section
4. Check statusEffects.js for all referenced effect types
5. Check classes.js for class compatibility
6. Report findings using the format below

## Output Format

Report issues like this:

    ## Hero Validation: [Hero Name]

    **File**: [path to hero data file]
    **Class**: [class] | **Rarity**: [N]-star

    ### Issues Found

    #### [ISSUE-1] [Brief description]
    - **Hero data**: property: value at [hero_file:line]
    - **Expected handler**: [where in battle.js this should be processed]
    - **Actual**: [what actually happens — missing, wrong, etc.]

    ### Verified OK
    - [List of things that checked out]

If no issues found, report a clean PASS.

## Tips

- battle.js is huge (~5500 lines). Skill execution starts around line 2925. Use Grep to find specific property handling.
- conditionalEffects has two formats: object (Mara) and array (Swift Arrow). Verify the right branch handles the hero's format.
- Check both single-target and AoE code paths — a property might be handled in one but not the other.
