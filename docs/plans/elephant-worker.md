# Elephant Worker — Design Plan

## Overview
A single hireable elephant companion that autonomously scoops water from pools, walks to the shop, sells, and repeats. Fully independent money-maker — unlike the camel which needs the player to fill it.

## Core Stats

| Property | Value |
|----------|-------|
| **Purchase Cost** | $75,000 |
| **Max Count** | 1 |
| **Unlock** | Available in shop once player can afford it (mid-game, Swamp/Lake tier) |
| **Behavior** | Walk to nearest undrained pool → scoop until full → walk to shop → sell → repeat |

## State Machine
Same pattern as the existing camel (`camel_states` in GameManager):

1. **`to_water`** — Walks right toward nearest undrained pool. Speed = trot speed.
2. **`scooping`** — At water edge, pauses and scoops repeatedly (once per ~0.5s) until trunk capacity is full or pool is drained. Trunk animation plays each scoop.
3. **`to_shop`** — Walks left back to shop (x ≈ 30). Speed = trot speed.
4. **`selling`** — Brief 0.5s pause at shop, money earned = water × money_per_gallon of the source pool × Water Value multiplier. Then transitions to `to_water`.

### Pool targeting
- Targets the **nearest undrained** overworld pool (by x-distance from elephant)
- If all pools are drained, idles at shop
- Does NOT enter caves or drain cave pools (overworld only)

## Upgrades (3 total)

| Upgrade | Base Cost | Cost Exponent | Effect | Base Value | Growth |
|---------|-----------|---------------|--------|------------|--------|
| Trunk Capacity | $100,000 | 1.30 | Water carried per trip | 1.0 gal | `1.0 * pow(1.25, level)` |
| Trot Speed | $100,000 | 1.30 | Walk speed (px/s) | 30.0 | `30.0 * pow(1.20, level)` |
| Trunk Strength | $150,000 | 1.35 | Gallons scooped per action | 0.02 | `0.02 * pow(1.30, level)` |

## Visual Design
Built with ColorRects (same approach as player character):

- **Body**: round gray rectangle ~12x10px, Color(0.55, 0.55, 0.58)
- **Head**: smaller gray rect ~6x6px, slightly lighter
- **Ears**: 2 floppy dark gray rects, ~4x5px each, slight wobble while walking
- **Legs**: 4 stubby rects ~2x4px, animated in pairs (front/back) while walking
- **Trunk**: Line2D or chain of small rects, ~1-2px wide
  - Hangs down when idle
  - Curls up when carrying water (visual indicator)
  - Dips into water during scoop animation
- **Tail**: tiny 1px line off the back

### Animations
- **Walking**: leg pairs alternate (like player boots), body bobs 1-2px, ears flop
- **Scooping**: trunk dips down, brief pause, trunk curls back up. Small splash particles.
- **Carrying water**: trunk stays curled up, small water drip particles trail behind
- **Selling**: brief squirt animation at shop, trunk straightens
- **Idle**: gentle breathing bob, ear twitch every few seconds

### Size relative to player
- About 2/3 the player's height, but wider. Chunky and cute.
- z_index = 3 (same layer as player, behind UI)

## GameManager State

```gdscript
# Elephant state
var elephant_owned: bool = false
var elephant_trunk_capacity_level: int = 0
var elephant_trot_speed_level: int = 0
var elephant_trunk_strength_level: int = 0
var elephant_state: Dictionary = {
    "state": "idle",  # idle, to_water, scooping, to_shop, selling
    "x": 30.0,
    "water_carried": 0.0,
    "source_swamp": 0,
    "state_timer": 0.0,
    "scoop_timer": 0.0,
}
```

### Methods
- `get_elephant_cost() -> float` — $75,000
- `buy_elephant() -> bool`
- `get_elephant_trunk_capacity() -> float` — `1.0 * pow(1.25, level)`
- `get_elephant_trot_speed() -> float` — `30.0 * pow(1.20, level)`
- `get_elephant_trunk_strength() -> float` — `0.02 * pow(1.30, level)`
- `get_elephant_*_upgrade_cost() -> float` — base × pow(exponent, level)
- `upgrade_elephant_*()`  — standard buy pattern

### Process tick (in GameManager._process or game_world)
Each frame, advance the elephant state machine:
- `to_water`: move x toward target pool. On arrival → `scooping`
- `scooping`: scoop_timer counts down. Each tick, drain pool + fill belly. When full → `to_shop`
- `to_shop`: move x toward shop (x≈30). On arrival → `selling`
- `selling`: brief timer, then sell water, earn money → `to_water`

## Save/Load
- Add to `get_save_data()` / `load_save_data()`:
  - `elephant_owned`, `elephant_trunk_capacity_level`, `elephant_trot_speed_level`, `elephant_trunk_strength_level`
  - `elephant_state` (position, water carried, current state)
- Bump save version (or handle missing fields gracefully like other upgrades)

## Shop UI
- New section in shop panel: "Elephant Worker"
- Buy button ($75K) → once purchased, shows 3 upgrade buttons
- Small elephant icon/preview next to the section

## Visual rendering
- Rendered in `game_world.gd` (like camel) — a Node2D child that moves along the terrain
- Uses `_get_terrain_y_at(x)` to stay on ground
- Faces left/right based on movement direction

## Implementation Order
1. GameManager: elephant state, computed properties, buy/upgrade methods
2. GameManager._process: state machine tick
3. game_world.gd: elephant visual node (ColorRect body parts + animations)
4. Shop panel: buy + upgrade UI
5. Save/load integration
6. Polish: particles, animations, idle behavior
