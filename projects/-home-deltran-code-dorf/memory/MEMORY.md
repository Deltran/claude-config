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

## Future Features
- **Colosseum Legends Mode**: Unlocks after bout 50 clear. Endless mode starting at bout 51. Every 10 bouts adds a modifier (enemies start with buffs, heroes start with debuffs, double enemies, all boss waves, etc.). Leaderboard tracks highest bout cleared. Cosmetic rewards every 10 bouts (titles, portrait frames, hero skins — prestige signaling). Turns Colosseum from "beat it once" into "chase the high score" flex zone.
- **10-pull constellation reveal**: All 10 cards slam down face-down at once, subtle glow hints for high rarity, then cascade flip sorted by rarity (commons first, legendary last). High-rarity cards get dramatic pauses and bigger presentation. Replaces current one-at-a-time tap-to-advance.
- **Custom 5-star hero reveal animations**: Each 5-star gets a unique spotlight entrance (Aurora descends in light beam, Shadow King emerges from smoke, etc.) instead of generic rarity-scaled template.
- **Black Market unique ritual**: Distinct summon animation for Black Market pulls (blood sacrifice, shadowy figures, ominous chanting) to make it feel mechanically different from normal altar.
- **Gem burst on spend**: Gem icons fly from header display toward altar (0.3s) before the ritual animation starts. Makes the spend feel like a sacrifice, not just a number decrement.
- **World map overview**: Connected region visualization showing how regions relate geographically. Scrollable strip or canvas with regions as connected zones, gray out locked ones. Orientation layer above the node-level maps.
- **Node challenge system**: Optional per-node objectives (under 5 turns, no deaths, mono-class party) with bonus rewards and completion badges on node markers. Orthogonal to hard mode.
- **Milestone celebration screens**: Full-screen moments for region clears, super-region unlocks, first GL kill. Reuse HeroSpotlight pattern — flash, badge, reward cascade.
- **Hard mode persistent toggle + unlock splash**: Move toggle to region list header (always accessible). On first unlock, trigger "Hard Mode Unlocked" full-screen modal explaining the feature.
- **Battle: Turn order redesign**: Enlarge portraits to 40-48px, move to horizontal strip or "Next 3" compact display. Turn order is strategic core — should be a first-class UI element, not a sidebar detail.
- **Battle: Status effect hierarchy overhaul**: Sort by type (protection → stat buffs → debuffs → DoTs → control), size by importance, compact+expanded mode. Divine Sacrifice should be HUGE; minor ATK buff can be small.
- **Battle: Enemy threat assessment system**: Threat auras (red/orange/green glow by danger), mini stat overlays, skill readiness badges. Make threat assessment subconscious instead of requiring long-press inspection.
- **Battle: Lifesteal particle trail**: Red-to-green particle trail from target to attacker on lifesteal heals. Make it feel vampiric.
- **Reference: Flatten Codex into tabbed ReferenceScreen**: Major IA restructure — replace Codex → Compendium → sub-screens with a single tabbed Reference screen (Heroes/Enemies/Regions/Field Guide/Logs). Cuts 2 taps from every lookup.
- **Reference: In-context Field Guide triggers**: Tap status effects in battle → opens Field Guide article. Add ? icons on screens. Make help ambient, not buried.
- **Reference: Post-battle analysis in Combat Logs**: Damage breakdown, turn efficiency, survivability stats, actionable suggestions ("try bringing a tank"). Turn data into coaching.
- **Reference: Repeating gem rewards for codex**: Weekly challenges ("Read 10 entries → 50 gems") for re-engagement after initial completion.
- **Explorations: Rank enhancement narrative framing**: Lore snippets per rank, contextual descriptions instead of bare "+5%". "Scouts have charted safer paths" instead of "+5% reward bonus."
- **Explorations: Failure states**: 5-10% chance of partial rewards + hero injuries for tension. Party Requests become critical, not just bonus.
- **Explorations: Home screen mini-expedition cards**: See active expeditions without navigating to full screen. Hero portraits + closest-to-completion node.
- **Explorations: Flavor text per node**: Single-line atmospheric description on each card. "The caverns whisper secrets to those who dare enter."
- **Explorations: Route Log narrative system**: 2-3 sentence updates per rank telling a story of the world changing. E→S progression from "Uncharted" to "A pilgrim's road."
- **Shops: Promote Markets to economy hub**: Move Gem Shop, Laurel Shop, Blacksmith, Dregs Shop off the mega-tab-bar onto Markets as category buttons. Shops becomes a clean 3-tab screen (Gold/Gems/Crest).
- **Shops: Blacksmith set grouping**: Group equipment by upgrade family (Bronze → Iron → Steel), show all tiers horizontally with owned counts.
- **Shops: Context-specific purchase modals**: Different modal styling per shop type (Daily Deal header for Gem Shop, set progress for Crimson Forge).
- **Shops: "Coming Soon" teaser expansion**: Expand beyond Laurel Shop to Crest Shop locked boss sections, Gem Shop rotation previews.
- **Party: Locked progression preview**: Show preview mockup of what Shards/Attunement do instead of just a lock icon. Taglines like "Turn duplicates into permanent stat boosts."
- **Party: Consolidate Shards + Attunement**: Single "Hero Enhancement" screen with tabs instead of separate screens.
- **Party: Merge path silhouettes**: Show merge requirements for heroes you don't own yet — creates aspiration and teaches merge costs.
- **Heroes: Gear equip animation**: Gear icon flies to slot, slot glows, stats count up with animation.
- **Heroes: Shard tier upgrade particles**: Shard explodes into particles, tier badge animates (shake + color shift), portrait gets rarity glow.
- **Heroes: Equipment as separate screen**: Dedicated loadout builder with set bonuses, upgrade paths. Current implementation is buried in detail panel.
- **Heroes: Two-step hero selection**: Tap to select/highlight, floating "View Details" button, enables multi-select for comparison/bulk operations.
- **Tavern: Hero roster panel**: Bottom slide-up panel with large tap-friendly hero portraits + event indicators. Diorama becomes decorative, roster becomes functional.
- **Tavern: Tavern Tales log**: Book icon near help button, stores last 10 resolved events with hero portraits, choice made, outcome. Pure flavor, no mechanical benefit.
- **Tavern: Celebration state after boss kills**: Special state for ~1 hour after GL clear — more lights, faster tip jar, victory emotes. Dejected state after wipes.
- **Tavern: Interactive Fellowship Hall**: Tap map table → World Map, weapon rack → Heroes, forge → Fusion, rune circle → Attunement. Trades discoverability for immersion.
- **Tavern: Hero roles**: Assign heroes to bartender/bouncer/bard roles affecting event types, tip jar rates, mini-narratives.
- **Home: Party breathing animation**: Subtle parallax or 2-3px vertical shift loop on hero sprites (FF-inspired life).
- **Home: Party spotlight effect**: Radial gradient stage lighting behind party grid for theatrical framing.
- **Home: Quick action menu on hero tap**: Tap hero in party preview → equip, level up, swap, view details.
- **Home: Contextual party naming**: Campaign Party, Boss Party, Arena Party instead of generic Alpha/Bravo/Charlie.
- **Home: Currency count-up animation**: Animated counter when gem/gold values change (returning from battle, etc.).

## Dev Notes / Backlog
- **Inventory screen filter**: Add filtering/sorting to the Inventory screen (by item type, rarity, etc.)
- **Goods & Markets title on mobile**: Fixed with flex constraints but worth monitoring on smaller screens


## Design Process Notes
- Use /dorf-ideation, /dorf-hero-evaluation, /dorf-cynic in parallel for hero design
- Agents sometimes assume mechanics exist that don't (e.g., baseline crit for Rangers) — always verify against code
- Test hero data shape separately from battle integration — data tests catch structure, integration tests catch runtime
