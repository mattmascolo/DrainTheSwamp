# Plan: Endgame Rework + Cave Loot Cleanup

## Overview
Three major changes:
1. Rework endgame into a cinematic shotgun march → CIA arrest
2. Strip all tool/stat rewards from caves — caves are lore-only
3. Move camel unlock to Cave 2 (Gator Den) as a findable item (free camel + shop unlock)

---

## Part 1: Endgame Rework — Shotgun March

### Trigger
Atlantic (pool 10) reaches 0% → `_trigger_endgame()`

### New Sequence
1. **Player freeze** — disable input, stop all timers
2. **Shotgun appears** — small gun sprite materializes in player's hand (ColorRect/Polygon2D). Brief dramatic pause (1.5s)
3. **Cinematic pan** — camera detaches from player, player auto-walks right at a steady pace. Camera pans smoothly across the drained Atlantic basin (~8-10 seconds), showing the character marching with shotgun. Background music/ambience should feel tense.
4. **Arrival at island** — player reaches the politicians on their island (right side of Atlantic). Stops walking.
5. **Aim** — player raises shotgun (rotation tween). Brief pause (1.5s). Politicians visible, maybe a subtle shake/reaction.
6. **CIA helicopter swoops in** — same helicopter as current (dark body, CIA label, spinning rotor). Comes from right side, fast.
7. **Helicopter blocks shot** — positions between player and politicians. Screen shake.
8. **CIA agents rappel** — two dark figures drop down.
9. **"ARRESTED" flash** — big red text, screen shake, white flash (keep current).
10. **Player lifted to helicopter** — agents + player tween upward, fade out.
11. **Helicopter flies away** — exits left.
12. **Politicians dust off** — same wobble animation as current.
13. **Credits newspaper** — keep current "DRAINER ARRESTED" newspaper.
14. **Refill cinematic** — keep current pool refill animation.
15. **Final newspaper** — keep current "GOODWELL: IT WAS ALL FAKE" newspaper.
16. **Return to title screen**.

### Key Differences from Current
- **Remove**: Hammer/bonk setup entirely
- **Add**: Shotgun sprite on player, cinematic right-march across Atlantic
- **Keep**: CIA helicopter, agents, arrest, newspapers, refill

### Files Modified
- `scripts/game_world.gd` — rewrite `_trigger_endgame()` steps 1-12

---

## Part 2: Cave Loot Cleanup

### Remove from ALL caves:
- All `reward_tool_unlock` (Spoon, Bucket, Wheelbarrow, Water Wagon)
- All `reward_tool_levels`
- All `reward_stat_levels` (Move Speed, Stamina, Scoop Power, Carrying Cap, Water Value)
- All `reward_upgrades` (Lantern levels)
- All `reward_money`
- All `reward_text` that references rewards

### What stays:
- Cave pool obstacles (must drain to pass) — no loot revealed
- Lore walls (story content)
- Decorative elements (puddles, stalactites, etc.)

### Per-cave changes:

| Cave | Remove | Keep |
|------|--------|------|
| 1. Muddy Hollow | Pool loot ($200, Move Spd +2), Lantern +3 loot, Spoon unlock loot | Lore wall |
| 2. Gator Den | Pool loot ($1K, Stamina +3), Bucket unlock, Lantern +2 loot | Lore wall, **NEW: Camel item** |
| 3. The Sinkhole | Pool 1 loot ($8K), Pool 2 loot (Scoop Pwr +4), Safe ($5K) | Lore wall |
| 4. Collapsed Mine | Pool 1 loot ($40K), Pool 2 loot (Wheelbarrow), Water Value +5 loot | Lore wall |
| 5. The Mire | Pool 1 loot ($200K), Pool 2 loot (Scoop Pwr +5), Treasure ($500K) | Lore wall |
| 6. Sunken Grotto | Pool 1 loot ($2M), Pool 2 loot (Carry Cap +8), Extra ($500K) | Lore wall |
| 7. Coral Cavern | Pool 1 loot ($50M), Pool 2 loot (Water Val +12), Pool 3 loot ($10M, Stamina +5) | Lore walls |
| 8. The Cistern | Pool 1 ($10M), Pool 2 (Water Wagon), Pool 3 (Scoop Pwr +10) | Lore walls |
| 9. The Underdark | Pool 1 ($250M), Pool 2 (Scoop Pwr +15), Pool 3 ($50M, Scoop Pwr +8) | Lore walls |
| 10. Mariana Trench | Pool 1 ($1B), Pool 2 (ALL stats +10), Pool 3 ($500M, Water Val +15) | Lore walls |

### Files Modified
- All 10 cave scripts: remove loot_node instances, clear `loot_data` from `cave_pool_defs`
- `scripts/caves/loot_node.gd` — can potentially be simplified or kept as-is for the camel item

---

## Part 3: Camel Unlock in Cave 2

### Current Mechanic
- Camel unlocks when Marsh (pool 3) is completed via `sell_water()`
- Player then buys camels in the shop for $500+

### New Mechanic
- **Remove** Marsh-completion camel unlock from `game_manager.gd`
- **Add** camel loot node at end of Gator Den (Cave 2)
- Finding it: sets `camel_unlocked = true`, gives 1 free camel, emits `camel_changed`
- Loot text: something like a stray camel found hiding in the cave
- The `_on_swamp_completed` popup about "A stray camel wanders out..." for swamp_index 2 should also be removed

### Files Modified
- `scripts/autoload/game_manager.gd` — remove Marsh camel unlock from `sell_water()`
- `scripts/caves/gator_den.gd` — add camel loot node with custom collect behavior
- `scripts/caves/loot_node.gd` — add `reward_camel_unlock: bool` field
- `scripts/autoload/scene_manager.gd` — remove camel popup for swamp_index 2

---

## Part 4: Existing TODOs to Address

### TODO #25: Consultant reports show only once after cave pool drain
- Track shown reports in GameManager (persist in save)
- Only trigger on first exit after draining a cave pool

### TODO #26: Bog cave terrain ✅ (already fixed in this session)

---

## Execution Order
1. Cave loot cleanup (Part 2) — bulk removal, straightforward
2. Camel unlock (Part 3) — new mechanic in Cave 2
3. Endgame rework (Part 1) — biggest change, rewrite cinematic
4. Consultant reports (Part 4, TODO #25) — minor fix
