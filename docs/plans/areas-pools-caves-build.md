# Areas, Pools & Caves — Build Plan

## Overview
Overhaul terrain for all 5 pools with unique personalities, add cave entrances that crack open as pools drain, build a scene transition system, and implement the first cave (Muddy Hollow) as proof of concept. Everything stays procedural.

## Build Order

### Phase 1: GameManager Cave State
- Add `cave_data` dictionary to GameManager:
  ```
  cave_data: Dictionary = {
    "muddy_hollow": {unlocked: false, entered: false, loot_collected: {}},
    "gator_den": {unlocked: false, entered: false, loot_collected: {}},
    "the_sinkhole": {unlocked: false, entered: false, loot_collected: {}},
    "collapsed_mine": {unlocked: false, entered: false, loot_collected: {}},
    "the_abyss": {unlocked: false, entered: false, loot_collected: {}}
  }
  ```
- Add `in_cave: bool = false` flag — when true, `get_darkness_factor()` returns 1.0
- Add `current_cave: String = ""` for tracking which cave the player is in
- Cave unlock definitions: map each cave to a swamp index and drain threshold (50%)
- Check unlock conditions on `water_level_changed` signal
- Add `cave_unlocked` signal for HUD notification
- Bump save version, save/load cave_data

### Phase 2: Terrain Overhaul
Rework `terrain_points` array in game_world.gd. Each pool gets a unique terrain personality:

**Pool Terrain:**
- **Puddle** — Gentle, worn. Smooth slopes with slight asymmetry, one small crack in basin floor (~6-7 points)
- **Pond** — Stepped, layered. Entry has a shelf/ledge, exit is gradual with a bump, V-dip in basin (~8-9 points)
- **Marsh** — Uneven, organic. Irregular slopes, multiple small bumps/dips, wide and sprawling (~10-12 points)
- **Bog** — Steep, cracked. Near-vertical drop on one side, stair-step ledges on other, deep cracks (~10-12 points)
- **Deep Swamp** — Jagged, raw. Multiple sharp ledges, significant basin variation, broken exit (~12-14 points)

**Ridge Terrain (between pools):**
- Ridge 1 (Puddle→Pond) — Smooth rounded hump, widest
- Ridge 2 (Pond→Marsh) — Narrow with flat top plateau, small crack
- Ridge 3 (Marsh→Bog) — Thin jagged peak
- Ridge 4 (Bog→Deep Swamp) — Flat plateau with crack

**Cave Entrance Positions:**
Each ridge has a cave entrance crack embedded in its terrain wall. The crack is tied to the pool on its left (the pool that unlocks it):
- Muddy Hollow entrance: in Ridge 1 wall (Puddle side)
- Gator Den entrance: in Ridge 2 wall (Pond side)
- The Sinkhole entrance: in Ridge 3 wall (Marsh side)
- Collapsed Mine entrance: in Ridge 4 wall (Bog side)
- The Abyss entrance: in right shore wall (Deep Swamp side)

**Pool geometry indexing:**
- Replace computed `4 * swamp_index` with stored boundary indices per pool
- Dictionary: `pool_bounds[i] = {entry_start: idx, basin_start: idx, basin_end: idx, exit_end: idx}`
- All dependent systems (water polygons, vegetation, detection areas) updated to use new indexing

### Phase 3: Cave Entrance Visuals (Crack System)
Each cave entrance starts as a thin crack in the terrain wall:
- **Sealed (>50% water):** Thin 1-2px dark line in the ridge, barely noticeable
- **Cracking (near 50%):** Visual cue — small particles drift from crack, line gets slightly wider
- **Open (<50% water):** Crack widens to ~12-16px wide opening with rocky edges. Subtle shimmer/glow particle effect. Player can walk into it.
- Animation: when threshold is crossed, a brief "crack open" effect plays — screen shake, dust particles, crack widens over 1-2 seconds
- HUD notification: "A cave entrance has appeared near [Pool Name]!"

**Implementation:**
- Each entrance is a Node2D with crack visual (ColorRects), collision area for interaction, and particle effect
- `_update_cave_entrances()` called when water level changes — checks drain % and transitions crack state
- Entrance interaction: player overlaps Area2D + presses interact → triggers scene transition

### Phase 4: Scene Transition System
Simple fade overlay for moving between main world and caves:
- `TransitionOverlay` — A CanvasLayer with a full-screen ColorRect (black, starts transparent)
- `transition_to_scene(scene_path: String)` function:
  1. Tween ColorRect alpha 0→1 over 0.4s
  2. Store return position (player x in main world)
  3. `get_tree().change_scene_to_packed()`
  4. Tween alpha 1→0 over 0.4s
- Could be an autoload (`TransitionManager`) or utility in GameManager
- Stores `return_position` so exiting a cave puts you back at the entrance

### Phase 5: Base Cave Scene Template
Reusable structure for all caves:
- **CanvasModulate** — Color(0.05, 0.05, 0.1) — near-total darkness
- **Cave terrain** — `cave_terrain_points` array, same polygon/collision generation as main world but with rock colors (grays/browns)
- **Ceiling** — Polygon above terrain for cave roof, with stalactite ColorRects hanging down
- **Player spawn** — Left edge of cave (entrance side)
- **Exit zone** — Area2D at left edge — player walks into it → "Exit cave?" or auto-exit
- **Loot nodes** — Glowing interactive spots (pulsing glow via PointLight2D, Area2D for interaction)
- **Lore walls** — Marked wall sections (shimmer overlay, Area2D for interaction, popup text)
- **Background** — Dark rock color, slightly varied for depth
- Lantern auto-activates (in_cave = true → darkness = 1.0)

### Phase 6: Muddy Hollow (First Cave)
- **Size:** ~2 screens wide (1280px), flat with some stalagmites
- **Terrain:** ~10 points, gentle floor with minor bumps
- **Lighting:** Dim but navigable with Lv1 lantern
- **Loot:**
  - Scrap metal pile (right side) → ~$200
  - Old toolbox (far right) → +1 level to current tool
- **Lore:**
  - Strange carved symbol on wall (center) — geometric pattern, too precise to be natural
  - Text: "A strange symbol is carved into the rock. It looks... deliberate."
- **Decorations:** Mud puddles (brown ColorRects), small stalagmites, dripping water particles from ceiling

---

## Key Technical Decisions
- **All procedural** — no TileMap, no imported assets, everything built from code
- **Separate scene files** — each cave is its own .tscn, clean separation from main world
- **Shared player script** — same player.gd works in caves, lantern auto-activates via `get_darkness_factor()`
- **Cave entrances = crack in terrain** — starts as thin line, widens when pool hits 50% drained
- **Loot is one-time** — tracked in cave_data, appears dim/empty on revisit

## Cave Lineup Reference (from caves-v2.md)
1. Muddy Hollow (Puddle, 50%) — tutorial cave, "huh that's odd"
2. Gator Den (Pond, 50%) — darker, animal bones, military dog tag
3. The Sinkhole (Marsh, 50%) — partially flooded look, government document
4. Collapsed Mine (Bog, 50%) — industrial, containment cells, monitoring equipment
5. The Abyss (Deep Swamp, 50%) — alien cavern, bioluminescent, alien tech
6. The Base (Deep Swamp, 90%) — endgame government facility, full conspiracy reveal
