# Draining the Swamp - Game Design Document

## Overview

**Title:** Draining the Swamp
**Genre:** Incremental / Idle Hybrid
**Engine:** Godot (with HTML5 export for browser version)
**Perspective:** Side-view cross-section (ant-farm style)
**Art Style:** Lo-fi pixel art (free asset packs)
**Tone:** Satisfying incremental grind + eerie atmosphere + political satire
**Inspirations:** Lumberjacked, A Game About Digging a Hole, Cookie Clicker

**Premise:** You start with a spoon and try to drain an entire swamp. As the water level drops, you discover caves, strange artifacts, and a conspiracy that goes all the way to the top. Turns out all politicians are lizard people.

**Endgame:** One-and-done story. Drain the swamp, expose the lizards, credits roll.

---

## Core Gameplay Loop

### Hybrid Active/Idle Model

- **Early game (Manual Tier):** Player actively clicks/holds to scoop water. Hands-on, grindy. The spoon feels pathetic on purpose -- makes upgrades feel incredible.
- **Mid game (Semi-Auto Tier):** Tools require periodic interaction (refueling, priming) but do the heavy lifting. Player starts splitting time between draining and cave exploration.
- **Late game (Idle Tier):** Pumps run on their own. Player manages upgrades and focuses on exploration, lore discovery, and boss encounters.

### The Loop
1. Scoop/pump water -> earn money
2. Spend money on tool upgrades + stat upgrades
3. Water level drops -> new areas/caves revealed
4. Explore caves -> find loot, lore, equipment
5. Hit a boss milestone -> beat the minigame
6. Repeat with better tools at deeper levels

---

## Water Removal Tools (18 Tiers)

### Manual Tier (Active Scooping)
| # | Tool | Output | Est. Cost |
|---|------|--------|-----------|
| 1 | Spoon | 0.001 gal/scoop | Free (starting tool) |
| 2 | Ladle | 0.005 gal/scoop | $5 |
| 3 | Cup | 0.02 gal/scoop | $25 |
| 4 | Bowl | 0.05 gal/scoop | $100 |
| 5 | Bucket | 0.2 gal/scoop | $500 |
| 6 | Trash Can | 1 gal/scoop | $2,500 |
| 7 | Wheelbarrow | 5 gal/scoop | $15,000 |

### Semi-Auto Tier (Periodic Interaction)
| # | Tool | Mechanic | Est. Cost |
|---|------|----------|-----------|
| 8 | Garden Hose Siphon | Slow drain, click to prime | $50,000 |
| 9 | Hand-Crank Pump | Hold to pump | $150,000 |
| 10 | Gas-Powered Pump | Runs for a duration, click to refuel | $400,000 |
| 11 | Solar Pump | Runs during daytime automatically | $1,000,000 |

### Idle Tier (Runs On Its Own)
| # | Tool | Mechanic | Est. Cost |
|---|------|----------|-----------|
| 12 | Electric Sump Pump | Needs generator, costs $/hr to run | $3,000,000 |
| 13 | Industrial Pump | Faster, more expensive to operate | $10,000,000 |
| 14 | Pump Network | Multiple connected pumps | $30,000,000 |
| 15 | Excavator | Removes mud AND water | $100,000,000 |
| 16 | Government Prototype Pump | Found/repaired in the base | Repair cost |

### Wild Card / Late Game
| # | Tool | Mechanic | Est. Cost |
|---|------|----------|-----------|
| 17 | Alien Tech Siphon | Found in caves, weird visual effects | Repair cost |
| 18 | Portal Drain | Opens a portal to dump water elsewhere | Repair cost |

**Upgrade scaling within tiers:** Each tool can be upgraded (I, II, III, etc.) using formula: `base_cost * 1.15^level`

**Found equipment** (tiers 16-18) must be discovered in caves and repaired with money. Acts as both a money sink and a gating mechanism.

---

## Economy

### Income
- Every gallon of water removed earns ~$0.01
- Flat-ish rate -- income scales through volume, not value per gallon
- Players earn more by draining faster (better tools + stats), not by finding "better" water

### Cost Scaling
- **Costs scale exponentially, income does not** (classic incremental model)
- Tool upgrade costs: `base_cost * 1.15^level`
- Tier jumps are large (see pricing table above)
- Stat upgrades follow similar exponential curves

### Money Sinks
- Tool purchases and upgrades (primary)
- Stat upgrades
- Equipment repairs (found gear from caves)
- TNT / explosives for sealed caves
- Diving equipment
- Vehicles (airboat, swamp buggy -- faster travel)
- Base camp upgrades (storage, rest area for stamina recovery)
- Generator fuel costs (idle pumps)

---

## Player Stats (7 Stats)

All stats are upgradeable with money. Each follows an exponential cost curve.

| Stat | Effect | Early Game Pain Point |
|------|--------|----------------------|
| **Carrying Capacity** | More water per trip | Barely carrying anything |
| **Movement Speed** | Faster walking/running | Slogging through swamp |
| **Stamina** | More scoops before resting | Exhausted after 5 scoops |
| **Mud Resistance** | Move through mud without slowdown | Stuck in the muck constantly |
| **Swim Speed** | Faster movement in water | Doggy-paddling pathetically |
| **Lung Capacity** | Hold breath longer underwater | Can barely dive at all |
| **Night Vision** | See further in dark caves | Can't see 2 feet ahead |

Each stat starts painfully low to make upgrades feel impactful. Late game, you're a swamp-conquering machine.

---

## Swamp Structure (Side-View Cross-Section)

The swamp is viewed in cross-section. The water level visibly drops as the player drains, revealing layers:

```
[Sky / Trees / Fog]              <- Atmospheric backdrop, day/night cycle
====================================  <- Ground level / shore
[Swamp Water ~~~~~~~~~~~~~~~~~~~~]   <- Water surface (drops over time)
[  Player character on shore     ]
[  Mud layer    [CAVE]-->        ]   <- Cave entrances in walls
[  Rock layer                    ]
[  Deep water   [CAVE]-->        ]
[  Sealed cave  [TNT REQUIRED]  ]
[  Deep cavern  [DIVE GEAR]     ]
[  Government Base               ]   <- Bottom of the swamp
====================================
[UI: Money | Stats | Tools | Inv ]   <- HUD
```

### Water Level Milestones

| Water Level | Event |
|-------------|-------|
| 100% | Game start. Spoon in hand. Good luck. |
| 90% | Muddy Hollow cave revealed |
| 80% | Gator Den cave revealed |
| 70% | The Sinkhole cave revealed (flooded, shallow) |
| 60% | Collapsed Mine revealed (sealed, needs TNT) |
| 50% | **Boss Fight: Politician #1** |
| 45% | The Grotto cave revealed (flooded, deep) |
| 35% | Sealed Chamber revealed (sealed, needs TNT) |
| 25% | **Boss Fight: Politician #2** |
| 20% | The Abyss cave revealed (deep cavern) |
| 15% | Subterranean Lake cave revealed (deep cavern) |
| 10% | **Boss Fight: Politician #3** |
| 5% | The Base entrance revealed (government facility) |
| 0% | **GAME COMPLETE** |

---

## Cave System

### Key Rule: Caves don't drain when the main quarry drains.
Caves are separate, self-contained water pockets. They must be explored as-is (swim, dive, etc.).

### How Caves Are Discovered
- Cave entrances appear in the cross-section walls as water drops
- Some are open and accessible immediately
- Some are blocked (need TNT to blast open)
- Some are flooded (need diving gear + lung capacity stat)

### Cave Types

| Type | Access Requirement | Contents |
|------|-------------------|----------|
| **Mud Caves** | Flashlight only | Junk, scrap metal, old tools. Minor money. |
| **Flooded Caves** | Diving equipment + lung capacity | Better loot, first military markings, strange carvings |
| **Sealed Caves** | TNT | Abandoned equipment (repairable), government documents |
| **Deep Caverns** | Max diving stats + best equipment | Alien/cryptid artifacts, strange machinery, glowing minerals |
| **The Base** | Multiple keycards from other caves | Full government facility. Multi-room. Conspiracy payoff. |

### Cave Gameplay
- Caves are **exploration & loot zones** (not draining mini-games)
- Walk/swim through, find loot nodes, interact to pick up items
- Limited by lung capacity (underwater sections) and night vision (dark areas)
- Return to surface before running out of air/stamina

### Cave Progression Map

| Cave | Type | Key Finds |
|------|------|-----------|
| Muddy Hollow (90%) | Mud | Scrap metal, old tools |
| Gator Den (80%) | Mud | Better flashlight, animal bones |
| The Sinkhole (70%) | Flooded (shallow) | First diving gear (broken), strange carvings |
| Collapsed Mine (60%) | Sealed | Generator parts, old mining equipment |
| The Grotto (45%) | Flooded (deep) | Military crate, first lore document |
| Sealed Chamber (35%) | Sealed | Alien mineral samples, weird machinery |
| The Abyss (20%) | Deep cavern | Advanced tech, cryptid evidence, Keycard A |
| Subterranean Lake (15%) | Deep cavern | Government logs, containment specs, Keycard B |
| The Base (5%) | Government facility | Full conspiracy reveal, endgame equipment |

### Loot Categories

| Category | Examples | Purpose |
|----------|----------|---------|
| **Junk/Sellables** | Old coins, scrap metal, fossils | Pure money |
| **Equipment** | Broken pumps, generators, diving gear | Repair for tool upgrades |
| **Lore Items** | Documents, tapes, photos | Story progression |
| **Key Items** | Keycards, TNT, cave maps | Gate access to new areas |
| **Weird Stuff** | Glowing rocks, alien tech, cryptid samples | Late-game mystery items |

---

## Boss Fights (Politician Minigames)

### Design Philosophy
- NOT traditional combat -- simple minigames themed around political satire
- Each politician is a **thinly veiled parody** of a real politician (both parties)
- Boss fights trigger at specific water level milestones
- Cannot progress past that water level until the boss is defeated

### Boss Mechanics

| Boss | Minigame | Mechanic |
|------|----------|----------|
| **Politician #1 (50%)** | "The Filibuster" | Politician generates water that floods back in. Out-pump their flood while dodging "subpoenas" that disable your pumps temporarily. |
| **Politician #2 (25%)** | "The Lobbyist" | Throws money bags that slow you down. Keep scooping while avoiding bribe projectiles. Getting hit = "bribed" (can't scoop for 3 seconds). |
| **Politician #3 (10%)** | "The Spin Doctor" | Screen rotates/distorts. Keep draining while your controls are being "spun" -- left becomes right, etc. |

### Boss Rewards
- Big cash payout
- Unlock the next depth tier
- Occasionally drop equipment or lore documents
- Later bosses drop keycards for the government base

---

## Atmosphere & Eerie Vibes

### Tone: "Something's Off" -- NOT Horror
- Curiosity-driven, not fear-driven
- Weird things pull the player deeper, not push them away
- No jump scares, no fear mechanics, no punishment for encountering strange things
- Eerie events are **lore breadcrumbs** that reward observant players

### Eerie Events (Visual/Atmospheric Only)
- Strange tracks in the mud after draining an area
- Weird noises at night (ambient, no gameplay effect)
- Objects that shouldn't be there (military crate half-buried in muck)
- Shadow of something large moving underwater
- Bioluminescent mushrooms/moss in caves
- Scratches on cave walls that get more organized deeper in (natural -> carved -> scientific markings)
- Evidence something else has been down here recently (fresh footprints, moved equipment)
- Glowing eyes in the reeds that vanish when you look directly
- Something running off screen at the edge of your vision

### Atmosphere Escalation
- Early game: Normal swamp. Maybe a weird sound here and there.
- Mid game: Clearly something is going on. Military gear in caves, strange carvings.
- Late game: Can't ignore it anymore. Alien tech, cryptid evidence, government documents.
- Endgame: Full confirmation. The base. The truth. Lizard people.

---

## Day/Night Cycle

### Atmospheric Only -- No Gameplay Impact
- Sky shifts from hazy daylight -> dusk -> foggy night -> dawn
- Visual changes: lighting, color palette, ambient effects
- Night additions: fireflies, moonlight on water, owl sounds, fog
- No time-gating of content or mechanics
- Just makes the swamp feel alive

---

## Narrative / Lore Thread

### The Conspiracy (Revealed Through Cave Lore Items)

**Layer 1 -- "That's Weird" (Caves 1-3)**
- Old equipment that seems too advanced for a swamp
- Carvings that don't match any known culture
- A broken piece of tech with a government serial number

**Layer 2 -- "Something Happened Here" (Caves 4-6)**
- Government documents referencing "Project Wetland"
- Containment cell designs
- References to "specimens" and "extraction protocols"

**Layer 3 -- "Oh Shit" (Caves 7-8)**
- Alien technology clearly not of this world
- Cryptid biological samples in sealed containers
- Communication logs between politicians and base personnel

**Layer 4 -- "The Truth" (The Base)**
- Full government facility dedicated to studying cryptids/aliens
- Evidence that politicians are literally lizard people
- Containment breach caused the base to be abandoned
- The cryptids you've been glimpsing are escaped specimens
- The swamp was flooded intentionally to hide the base

---

## Endgame

### One-and-Done Story
- No prestige system, no New Game+, no endless mode
- The game has a definitive ending
- Drain the swamp -> expose the lizards -> credits

### Ending Sequence
1. Drain the final 5% of water
2. Beat Politician #3
3. Enter the government base (requires Keycards A + B)
4. Explore rooms, piece together the full conspiracy
5. Final reveal sequence -- the lizard people truth
6. Credits with fun stats: "Total gallons drained: 14,382,091" / "Spoons used: 1" / "Politicians defeated: 3"
7. Post-credits joke: News ticker -- "Local man drains entire swamp, discovers government conspiracy. Politicians deny allegations, shed skin during press conference."

---

## Visual Layout

### Screen Composition
```
+------------------------------------------+
|  [Sky - day/night cycle, trees, fog]     |
|==========================================|
|  [Ground/Shore - player, base camp]      |
|------------------------------------------|
|  [Water ~~~~~~~~~~~~] <- drops over time |
|  [Mud layer  [CAVE]->]                   |
|  [Rock layer        ]                    |
|  [Deep area  [CAVE]->]                   |
|  [Base level        ]                    |
|==========================================|
|  [UI: $ Money | Stats | Tools | Items ]  |
+------------------------------------------+
```

### Art Direction
- Lo-fi pixel art from free asset packs
- Swampy color palette: murky greens, browns, dark blues
- Water should look satisfying to watch drain
- Caves should feel distinct from the main swamp (darker, different palette)
- Government base should feel sterile and out-of-place (grays, clinical lighting)

---

## Development Phases

### Phase 1 -- Core Loop (MVP)
- Side-view swamp with dropping water level
- 3-4 tools (spoon, bucket, pump, industrial pump)
- Basic economy (earn money, buy upgrades)
- 2-3 stats (carry capacity, speed, stamina)
- Simple UI
- No caves, no bosses, no lore
- **Goal: Playable incremental game**

### Phase 2 -- Depth
- Full tool progression (all 18 tiers)
- All 7 stats
- First 3-4 caves with loot
- Eerie atmospheric effects
- Day/night visual cycle

### Phase 3 -- Content
- All 9 caves + the base
- 3 boss fight minigames
- Lore items and full narrative
- Government base finale
- Ending sequence and credits

### Phase 4 -- Polish
- Sound design and music
- Art replacement/improvement
- Balance tuning
- Browser export (HTML5)
- Bug fixes and QA

---

## Technical Notes

- **Engine:** Godot 4.x
- **Language:** GDScript
- **Target Platforms:** Desktop (Windows/Linux/Mac) + Browser (HTML5 export)
- **Save System:** Local save file, auto-save on interval
- **Resolution:** TBD based on asset pack selection (likely 320x180 or 640x360 native, scaled up)
