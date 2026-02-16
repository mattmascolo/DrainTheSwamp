# Cave Overhaul v3 — Visual + Gameplay Upgrade

## Core Concept
Caves become mini-draining levels. Wavy terrain creates valleys that fill with water pools.
Pools physically block movement — drain them to progress deeper and reveal loot underneath.
Each cave has a distinct visual identity with unique stone colors, themed decorations, and atmosphere.

## Gameplay: Cave Pools as Barriers

### How it works
1. Cave terrain is dramatically wavy — hills and valleys instead of flat-ish floor
2. Valleys fill with small water pools that physically block the player
3. Player scoops water from the pool edge (same mechanic as overworld)
4. Water level visually drops as you drain
5. At 0%, pool "shatters" with sparkle effect, revealing a loot node at the bottom
6. Player can now walk through the drained valley to continue deeper
7. Caves become a sequence: drain pool 1 → collect loot → reach pool 2 → drain → repeat
8. Pool drain state persists in save data (can leave and come back)

### Pool scaling per cave
| Cave | # Pools | Gallons Each | Hidden Loot Examples |
|------|---------|-------------|---------------------|
| Muddy Hollow | 1 | 2 gal | $200 + move speed +2 |
| Gator Den | 1 | 15 gal | $1,000 + stamina +3 |
| The Sinkhole | 2 | 80 gal | $8,000 / scoop power +4 |
| Collapsed Mine | 2 | 500 gal | $40K / tool unlock |
| The Mire | 2 | 3K gal | $200K / drain mastery +5 |
| Sunken Grotto | 2 | 20K gal | $2M / carrying cap +8 |
| The Cistern | 3 | 150K gal | $10M / water wagon / scoop power +10 |
| Coral Cavern | 3 | 1M gal | $50M / water value +12 |
| The Underdark | 3 | 8M gal | $250M / drain mastery +15 |
| Mariana Trench | 3 | 50M gal | $1B / ALL stats +10 |

### Implementation notes
- Cave pools are separate from overworld swamp_states — need `cave_pool_states` in GameManager
- Each pool: `{cave_id, pool_index, total_gallons, gallons_drained, completed}`
- Water polygon built like overworld pools but using cave terrain points for the valley shape
- Collision body blocks player when pool has water (Area2D or StaticBody2D)
- Remove collision when pool is fully drained
- money_per_gallon for cave pools: use the associated overworld pool's rate (or higher)
- Loot node spawns hidden (invisible/no collision) until pool is drained, then activates

## Visuals: Per-Cave Themes

### Unique stone/atmosphere per cave
| Cave | Stone Color | Crystal Color | Atmosphere | Signature Feature |
|------|-----------|--------------|-----------|------------------|
| Muddy Hollow | Warm brown | Amber | Dusty, roots from ceiling | Mud puddles, earthworms |
| Gator Den | Dark olive | Yellow-green | Humid, mossy | Gator tooth fossils, algae |
| The Sinkhole | Grey-blue | Blue-green | Wet, dripping everywhere | Stalactite waterfalls, eroded stone |
| Collapsed Mine | Rusty brown | Orange | Dusty, debris | Mine cart tracks, timber supports, metal scraps |
| The Mire | Dark green-brown | Dark green | Thick fog/spores | Hanging vines, bioluminescent fungi |
| Sunken Grotto | Teal-grey | Teal | Flooded feel, echoing drips | Flowstone formations, mineral veins |
| The Cistern | Slate grey | Steel blue | Industrial, angular | Concrete pillars, pipe fragments, brick |
| Coral Cavern | Pinkish stone | Coral pink | Warm, organic | Coral branches, sea shells, anemone blobs |
| The Underdark | Purple-black | Deep purple | Oppressive, ancient | Rune markings (glowing), alien pillars |
| Mariana Trench | Deep blue-black | Blue bioluminescent | Crushing depth, eerie | Whale bones, kelp, shipwreck debris |

### Override cave_base colors in each subclass
- `GROUND_COLOR`, `CEILING_COLOR`, `WALL_COLOR` become vars instead of consts in cave_base
- Each subclass sets its own palette in `_init()`

### Shared visual upgrades (all caves via cave_base)

#### Parallax background
- Faint distant rock formations behind the cave (z_index = -5)
- Shifts slightly with camera movement for depth
- Color matches cave stone palette but darker/more muted

#### Ceiling light shafts
- 2-3 per cave: beams of light from cracks in ceiling
- Line2D with low-alpha white/warm color, slight width taper
- PointLight2D at the crack source for local illumination
- Later caves: fewer/dimmer light shafts (deeper = darker)

#### Floating particles
- Theme-appropriate particles floating in the air
- Muddy Hollow: dust motes (already exists, keep)
- Sinkhole: water droplets
- The Mire: green spores
- Coral Cavern: tiny bubbles
- Mariana Trench: bioluminescent specks
- Reuse dust_motes system from cave_base, just change color/behavior per cave

#### Pool water glow
- Cave pools emit faint light matching crystal color
- PointLight2D under water surface, pulses gently
- Brighter when full, dims as pool drains

#### Waterfalls (later caves only)
- Sunken Grotto and beyond: vertical water streams from ceiling
- Line2D with animated position wobble
- Splash particles at floor contact
- Purely decorative (no gameplay effect)

## Terrain Shape Changes
- Replace gentle terrain_points with dramatic hills and valleys
- Valley floors: where pools form (lowest points)
- Hill peaks: walkable ridges between pools
- ~30-50px height variation (currently ~10px)
- Later caves: deeper valleys, steeper slopes
- Ceiling follows similar waviness but inverted (lower over valleys for claustrophobia)

## Hidden Rooms (Future — not in this build)
- Subtle wall cracks that can be broken open
- Reveal secret chambers with bonus loot
- Saved separately from main cave progression
- Can be added in a follow-up pass

## Technical Notes
- Save version bump needed for cave_pool_states
- Cave pool water uses same shader as overworld pools
- Player `near_water` detection needs to work with cave pools
- Scoop action in caves: check cave pools first, then fall back to existing behavior
- `cave_base.gd` needs new methods: `_build_cave_pools()`, `_update_cave_pool()`
