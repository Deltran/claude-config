# Dorf Development Memory

## Critical Patterns

### Status Effect Duration Off-by-One
Effect durations tick down at the **end of each unit's own turn** via `processEndOfTurnEffects`. To make an effect last N full rounds, set `duration: N+1`. Setting `duration: 1` means the effect expires after the unit's first action — before enemies may even get to act if the unit is fast.

- **Pattern**: `duration: 2` = lasts 1 full round (confirmed by Seat of Power tests)
- **Anti-pattern**: `duration: 1` = expires immediately on the unit's turn, effectively 0 rounds
- **Where it ticks**: `src/stores/battle/turns.js` in `processEndOfTurnEffects` (lines ~145-163)
- **Known fix**: Rosara leader skill taunt changed from `duration: 1` to `duration: 2`
- **Audit risk**: Any `battle_start_*` leader effect or buff applied at init with `duration: 1` likely has this bug

See also: `docs/patterns/duration-off-by-one.md` (if created)

### Browser Testing: Seed Heroes via Console
To seed heroes when previewing in browser (Playwright or manual), inject via Pinia store after app loads:
```js
const pinia = document.querySelector('#app').__vue_app__.config.globalProperties.$pinia
const heroesStore = pinia._s.get('heroes')
const templates = ['aurora_the_dawn', 'shadow_king', 'sir_gallan', 'ember_witch', ...]
for (const tid of templates) { try { heroesStore.addHero(tid) } catch(e) {} }
// Party: heroesStore.setPartySlot(0, heroesStore.collection[0].instanceId)
// Leader: heroesStore.setPartyLeader(heroesStore.collection[0].instanceId)
```
- Store access pattern: `pinia._s.get('storeName')` for any store
- Must click through intro sequence first (or `endBattle()` if auto-battle starts)

### VFX Editor / Admin: @/ Path Alias
The VFX editor uses `@/` imports. Vite needs `resolve.alias` in vite.config.js to map `@` to `src/`.
