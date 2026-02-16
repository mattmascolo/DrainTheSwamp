# Terrain Overhaul + Jump Mechanic — Design Plan

## Overview
Replace the current symmetric V-shaped pools and smooth ridges with complex, asymmetric terrain that gives each pool a distinct personality. Add a small hop mechanic so the player can traverse ledges and cracks.

## Current State
- 24 terrain points total (2 per pool slope + basin, 2 per ridge, shores)
- Pools are symmetric: straight slope in, flat basin, straight slope out
- Ridges are simple smooth peaks
- No jumping — player only walks and slides on gravity

## Goals
- Each pool has unique terrain character (gentle → jagged as you go deeper)
- Ridges between pools have variety (humps, plateaus, jagged peaks)
- All terrain remains walkable (slopes ≤45 degrees) — no jump mechanic needed
- Total terrain points increase from 24 to ~60-80
- World dimensions and overall shape stay the same
- Mobile-friendly: no extra buttons or airborne states to manage

---

## Pool Terrain Personalities

### Puddle — "Gentle, worn"
- Smooth slopes with slight asymmetry (steeper entry, gradual exit)
- One small crack/notch in the basin floor
- Feels like natural erosion over time
- ~6-7 points

### Pond — "Stepped, layered"
- Entry side has a shelf/ledge partway down (layered sediment look)
- Exit slope is more gradual with a bump
- Basin floor has a slight V-dip off-center
- ~8-9 points

### Marsh — "Uneven, organic"
- Irregular slopes — neither side is a straight line
- Multiple small bumps and dips in the basin
- Wide and sprawling, soft/shifting feel
- ~10-12 points

### Bog — "Steep, cracked"
- One side has a near-vertical drop (cliff face)
- Other side has stair-step ledges
- Deep cracks in the basin floor
- Feels industrial, like something dug this out
- ~10-12 points

### Deep Swamp — "Jagged, raw"
- Jagged entry with multiple sharp ledges
- Uneven basin with significant terrain variation
- Exit side has a rough, broken feel
- Deepest and most intimidating visually
- ~12-14 points

## Ridge Personalities

### Ridge 1 (Puddle → Pond)
- Smooth rounded hump, widest ridge
- Minor asymmetry

### Ridge 2 (Pond → Marsh)
- Narrow with a flat top (small plateau)
- Slight crack/dip in the middle

### Ridge 3 (Marsh → Bog)
- Thin jagged peak
- Sharp angles on both sides

### Ridge 4 (Bog → Deep Swamp)
- Flat plateau with a crack running through it
- Wide enough to stand on comfortably

---

## Jump Mechanic

**REMOVED** — Jump adds complexity without serving the core loop. Terrain is designed to be walkable (all slopes ≤45 degrees) so `move_and_slide()` handles everything. Mobile-friendly: no extra buttons needed.

---

## Technical Approach

### Terrain Points
- Replace `terrain_points` array in `game_world.gd` with expanded array (~60-80 points)
- Each pool defined by more points, but same structure: entry slopes → basin → exit slopes
- `_get_swamp_geometry()` needs rework to handle variable points per pool
  - Store pool boundary indices instead of computing `4 * swamp_index`
  - Dictionary mapping: `{pool_id: {entry_start: idx, basin_start: idx, basin_end: idx, exit_end: idx}}`
- All systems that reference terrain_points (terrain building, vegetation placement, water detection, terrain Y lookup) need to work with new point count
- `_build_terrain()` SegmentShape2D generation should work as-is (iterates consecutive points)
- `_get_terrain_y_at()` interpolation should work as-is (finds segment at x, interpolates y)

### Water Polygon Adjustments
- Water polygon generation needs to follow the new basin floor shape (not just 2 flat points)
- Water fill should still work as a fraction, but the polygon traces the actual basin contour
- May need to generate water polygon from all basin points, not just left/right corners

### Water Detection Areas
- Detection areas need to match new basin geometry
- May need more collision shapes per pool to cover irregular basins

### Jump Implementation
- Add jump input action in project settings (space, up arrow)
- In `player.gd` `_physics_process()`:
  - Check `is_on_floor()` and jump input
  - Apply `velocity.y = JUMP_VELOCITY`
- Add jump animation to procedural animation system
- Add dust puff on takeoff/landing

### Vegetation & Detail Placement
- Existing vegetation placement uses `_get_terrain_y_at()` which should still work
- May need to re-tune some hardcoded placement positions if terrain shape changes significantly

---

## Implementation Order
1. Design new terrain points array (on paper / in code comments first)
2. Update `terrain_points` and pool geometry indexing
3. Adjust water polygon generation for irregular basins
4. Adjust water detection areas
5. Test terrain visually — verify nothing breaks
6. Tune terrain shape through playtesting (ensure all slopes walkable)
7. Adjust vegetation/detail placement if needed

---

## Risks & Notes
- Changing terrain points affects many systems (water, vegetation, collision, camera limits)
- Need to be careful with water fill math — currently assumes flat basin between 2 points
- Jump should feel optional for basic traversal — player can still walk most terrain without jumping
- Terrain changes may shift where the pump/sell area is — verify left shore stays accessible
- Save compatibility: terrain is not saved (rebuilt from code), so no save version bump needed
