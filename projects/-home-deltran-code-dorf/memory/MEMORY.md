# Dorf Development Memory

## Stack System (2026-02-04)
- Counter-based stacking implemented via `maxStacks` on effect definitions
- `applyEffect` has early-return branch for maxStacks effects (before existing stackable/non-stackable logic)
- `getEffectiveStat` uses `effect.value * (effect.stacks || 1)` for backwards compat
- `getStacks(unit, effectType)` helper exported from battle store
- SWIFT_MOMENTUM is type `swift_momentum` — doesn't contain `_up`, so `getEffectiveStat` also checks `def.isBuff` alongside `type.includes('_up')` to handle it
- Cleanses remove all stacks at once (future item could strip one at a time)
- UI: effects with `stacks` show count badge instead of duration, always (even at 1)

## Swift Arrow Redesign (2026-02-04)
- Redesigned from Korrath clone to "Tempo Archer / The Skirmisher"
- Kit: Quick Shot (SPD_DOWN), Pinning Volley (conditional DEF_DOWN), Nimble Reposition (DEBUFF_IMMUNE + SPD_UP), Precision Strike (bonusIfTargetHas), Flurry of Arrows (onHitDebuffedTarget → SWIFT_MOMENTUM)
- Three new skill properties added to battle engine:
  - `bonusIfTargetHas` — array of `{effectType, ignoreDef?, damagePercent?}`, checked before damage calc
  - `conditionalEffects` — array format with `condition: 'target_has_debuff'`, applied after damage in both AoE and single-target paths. Uses `Array.isArray()` to distinguish from Mara's object-style format
  - `onHitDebuffedTarget` — `{applyToSelf: {type, value, duration}}`, checked per-hit inside multi-hit loop

## Battle.js Patterns
- Debuff check pattern: `(target.statusEffects || []).some(e => { const def = e.definition || getEffectDefinition(e.type); return def && !def.isBuff })`
- ignoreDef pattern: `const defReduction = skill.ignoreDef ? (skill.ignoreDef / 100) : 0`
- Effect application uses `applyEffect(unit, effectType, {duration, value, sourceId})`
- Rangers lose Focus on hit or debuff, regain from ally buffs or focus_on_crit equipment
- Crit is equipment-only (NOT a Ranger baseline) — don't design skills around crit
- All Ranger skills require Focus — no "usable without Focus" exceptions

## Testing Patterns
- `setActivePinia(createPinia())` in beforeEach for fresh store per test
- Hero setup: `heroesStore.addHero(id)` → `setPartySlot(0, instanceId)` → `initBattle(null, enemyIds)`
- Battle hero access: `battleStore.heroes[0]`, enemies: `battleStore.enemies[0]`
- Skill execution: `battleStore.executeHeroSkill(hero, skill, target)` (exported from store)
- Effect checking: `battleStore.hasEffect(unit, type)`, `battleStore.getStacks(unit, type)`
- Test runner: `npx vitest run` (all) or `npx vitest run path/to/test.js` (specific)

## Codebase Notes
- Hero data in `src/data/heroes/{rarity}star/{hero_id}.js`, indexed in `{rarity}star/index.js`
- Status effects in `src/data/statusEffects.js` — EffectType enum + effectDefinitions + createEffect helper
- Battle store is massive (~5500 lines) — skill execution starts around line 2925
- Effect icons rendered in HeroCard, EnemyCard, StatusOverlay, HeroDetailSheet, EnemyDetailSheet, BattleScreen
- `conditionalEffects` has two formats: object (Mara's Heartbreak) and array (Swift Arrow) — use `Array.isArray()` to distinguish

## Battle Animations (2026-02-06)
- **Battle transition**: BattleTransitionOverlay.vue — doors close/open pattern. App.vue calls `transitionToBattle()`, overlay emits `screenSwap` (switch screen) and `complete` (signal battle store). Battle store uses `waitingForTransition` ref + `signalTransitionComplete()` instead of setTimeout.
- **Enemy entrance**: CSS animation on `.enemy-wrapper` using `--entrance-x`/`--entrance-y` CSS vars for random direction. `battleInstance` ref in BattleScreen increments per wave to force fresh DOM keys and re-trigger animations.
- **Boss entrance**: `.boss-entrance` class on solo enemies (`isSoloEnemy` computed) — ominous materialization (scale from 0, desaturated→color, brightness glow, screen shake at end). 0.5s delay before boss appears for dread buildup. Full-screen vignette via `::before` on `.battle-screen.boss-vignette` (not per-section — avoids overlap issues).
- **Enemy death**: `enemyDeathDramatic` keyframe (2s) — flash, shake, fade. Boss death (`bossDeathDramatic`, 3s) is more intense with triple flash, longer shake, screen-wide white flash via `::after`. Victory delay: 600ms between waves, 2s final wave, 3.5s solo enemy final wave.
- **Key lesson**: Don't set both a static CSS property AND an animation for the same property — the static value applies first, then animation starts from its 0% keyframe, causing a visible pop.
- **Key lesson**: Full-screen vignettes should go on `.battle-screen::before` (position: fixed), not on individual sections — avoids overlap/gap issues between sections.

## Design Process Notes
- Use /dorf-ideation, /dorf-hero-evaluation, /dorf-cynic in parallel for hero design
- Agents sometimes assume mechanics exist that don't (e.g., baseline crit for Rangers) — always verify against code
- Test hero data shape separately from battle integration — data tests catch structure, integration tests catch runtime
