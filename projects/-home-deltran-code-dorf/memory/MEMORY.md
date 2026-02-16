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
- Skill execution: `selectAction('skill_N')` + `selectTarget(enemyId, 'enemy')` — requires manual setup: push hero/enemy to store arrays, set turnOrder, currentTurnIndex=0, state=BattleState.PLAYER_TURN. No `executeHeroSkill` export exists.
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

## Admin Tooling / Asset Pipeline (2026-02-11)
- Sprite inpainting: flatten transparency → Gemini edit → restore transparency
- ImageMagick endpoints in `vite-plugin-admin.js`: `/__admin/flatten-for-inpaint`, `/__admin/restore-transparency`
- Frontend helpers in `src/lib/inpaint.js`: `flattenForInpaint`, `restoreTransparency`, `imageUrlToDataUrl`
- **Key lesson**: Vite asset URLs (e.g. `/assets/foo-abc123.png`) are NOT data URLs. Any function sending image data to the server must convert via `imageUrlToDataUrl()` first. `flattenForInpaint` now does this automatically.
- **Key lesson**: Mock at I/O boundaries (fetch, fs), not module boundaries. Mocking entire modules hides integration bugs at the seams. The asset-path-vs-data-URL bug slipped through because modal tests mocked all of `inpaint.js`.
- InpaintCanvas.vue has `image-rendering: pixelated` for crisp pixel art zoom
- BackgroundAssetModal is the reference implementation for inpaint flows
- Future: Add Playwright e2e tests for admin tools — would catch URL format mismatches that unit tests miss

## Title Text Renderer (2026-02-14)
- Script: `scripts/render-title-text.sh` — renders styled DORF title text as transparent PNG
- Font: **Cinzel Decorative Bold** (SIL OFL, free for commercial use), installed at `~/.local/share/fonts/cinzel/`
- Style: dark brown fill + muted gold/amber outline, matching the original `src/assets/dorf-logo-1.png`
- Usage: `./scripts/render-title-text.sh "TEXT" output.png [font_size] [max_width] [pixel_scale]`
  - Multi-line: use `\\n` in the string (or `$'...\n...'` syntax)
  - Defaults: font_size=64, max_width=640, pixel_scale=3
  - pixel_scale controls chunkiness: 2=fine, 3=default, 4+=blocky
  - `--smooth` flag skips pixelation for anti-aliased output
  - Renders at 4x then pixelates down via nearest-neighbor
- Colors are tunable at the top of the script (FILL_COLOR, OUTLINE_COLOR, SHADOW_COLOR, HIGHLIGHT_COLOR)
- Summon screen banner size: 640x360 (16:9, displayed at max 360px wide for 2x retina)

## CLI Scripts
- `npm run sim:region -- list` — list all quest regions
- `npm run sim:region -- sim "Region Name"` — run combat simulation for a region (all nodes), shows min-clear-level per rarity
  - `--runs <n>` (default 20) — simulation runs per level search
  - `--multiplier <n>` (default 1.0) — enemy stat multiplier
- `npm run adjust:region -- list` — list all quest regions
- `npm run adjust:region -- preview "Region Name"` — preview stat changes without writing
- `npm run adjust:region -- apply "Region Name"` — apply stat changes to enemy source files
  - `-u, --uniform <percent>` — uniform adjustment for all stats (e.g. `--uniform 10` = +10%)
  - `--hp <percent>`, `--atk <percent>`, `--def <percent>`, `--spd <percent>` — per-stat adjustments
- Scripts use `register-loader.js` to stub image imports for Node.js ESM
- Existing asset scripts: `npm run generate-assets`, `npm run generate-battle-backgrounds`, `npm run generate-region-maps`

## Open Bugs
- **Tavern table/bar micro-jitter**: Tables and bar assets shift ~1px intermittently. Hearth and rug unaffected. Tried: `will-change: transform`, `backface-visibility: hidden`, `box-sizing: border-box`, `border-color: transparent` instead of `border: none` — none fixed it. Likely a deeper sub-pixel rendering issue with CSS `transform: scale()` on the diorama container. Only affects elements with `useTableImg`/`useBarImg`. Needs further investigation.
- **Hard mode miniboss music**: When hard mode node overrides add extra enemies to formerly-solo miniboss waves (e.g. dire_wolf in forest_02 now has goblin_chieftain + goblin_warrior alongside it), the miniboss music no longer triggers because `isSoloEnemy` is false. All miniboss fights across all regions need the music trigger updated — probably check for presence of a miniboss-flagged enemy in the wave rather than wave size.

## Dev Notes / Backlog
- **Inventory screen filter**: Add filtering/sorting to the Inventory screen (by item type, rarity, etc.)
- **Remove enemy tap highlight**: Remove the enemy tap feature that highlights the enemy and displays their name above their head
- **Map Room "Exploration" text**: The word "Exploration" is too big for the button
- **Field Guide Status Effects formatting**: Needs a formatting pass
- **Valinar battle bg**: Use Valinar's battle background as the button background image


## Design Process Notes
- Use /dorf-ideation, /dorf-hero-evaluation, /dorf-cynic in parallel for hero design
- Agents sometimes assume mechanics exist that don't (e.g., baseline crit for Rangers) — always verify against code
- Test hero data shape separately from battle integration — data tests catch structure, integration tests catch runtime
