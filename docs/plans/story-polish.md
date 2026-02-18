# Story Polish & Endgame Revision Plan

## Overview

Polish pass on all story systems + new character Congressman Goodwell + revised endgame with all politicians on the island + post-credits refill cinematic. Also adds world reactivity: government sabotage events, wanted poster, helicopter flyovers, and scattered consultant reports.

---

## 1. Billboard Visual Polish

**Current state:** 50x28px signs with font_size 5 — barely readable.

**Changes:**
- Increase sign to 70x40px, font_size 7
- Alternate red/blue tint on sign backgrounds (partisan colors):
  - Odd ridges (1, 3, 5, 7, 9): light red tint `Color(0.90, 0.82, 0.78)` — Swampsworth signs
  - Even ridges (2, 4, 6, 8): light blue tint `Color(0.78, 0.82, 0.90)` — Lobbyton signs
- Add slight random rotation (-3 to +3 degrees) on some signs for a weathered/crooked look
- Double the post width (2px -> 3px) so it looks sturdier
- Add a small horizontal crossbar where post meets sign

**File:** `scripts/game_world.gd` — `_build_billboards()`

---

## 2. Newspaper Visual Polish

**Current state:** Same clean paper layout every time. Gets repetitive across 12+ newspapers.

**Changes to both title_screen.gd and scene_manager.gd newspaper builders:**

- **Corner fold:** Small triangle in top-right corner (darker shade of paper color)
- **Coffee ring stain:** Subtle brown circle (alpha 0.08-0.12) at random position, only on Act 2+ newspapers
- **Age tinting:** Paper background gets progressively yellower/darker by act:
  - Act 1 (pools 0-2): `Color(0.92, 0.88, 0.78)` — clean (current)
  - Act 2 (pools 3-5): `Color(0.90, 0.85, 0.72)` — slightly aged
  - Act 3 (pools 6-8): `Color(0.86, 0.80, 0.66)` — yellowed, stained
  - Act 4 (pool 9): `Color(0.82, 0.76, 0.60)` — old, dramatic
- **Fake photo placeholder:** Gray rectangle with italic caption in Act 2+ newspapers. Examples:
  - Pool 3 (Bog): `[Photo: Senator at "swamp research" resort]`
  - Pool 5 (Lake): `[Photo: Man with bucket, Senate building background]`
  - Pool 7 (Lagoon): `[Photo: Waterproof containers pulled from swamp]`
  - Pool 8 (Bayou): `[Photo: Empty congressional parking lot]`
  - Pool 9 (Atlantic): `[Photo: One man. One bucket. One ocean.]`

**Files:** `scripts/title_screen.gd` (opening newspapers), `scripts/autoload/scene_manager.gd` (milestone newspapers)

---

## 3. Congressman Goodwell — Corruption Arc

**New character:** Congressman Goodwell (I) — Independent. Starts as a genuine reformer who champions the drainer's cause. Slowly corrupted by power. By endgame, he's the new Swampsworth.

### Newspaper appearances (append to existing milestone newspaper body text):

**Act 1 — The Champion:**
- Pool 0 (Puddle): `Congressman Goodwell (I) called the achievement "proof that one honest worker can outperform an entire bureaucracy." He has introduced a bill to increase the field operations budget.`
- Pool 1 (Pond): `Only Congressman Goodwell voted against a motion to "quietly reassign" the drainer. "Let the man work," he said.`
- Pool 2 (Marsh): `Congressman Goodwell has filed a formal complaint about missing funds in the Initiative budget. "Someone is going to answer for this," he said.`

**Act 2 — The Shift:**
- Pool 3 (Bog): `Congressman Goodwell, recently appointed chair of the Swamp Oversight Committee, said the study "raises valid concerns" and recommended "a measured pace." He was later seen at the same donor dinner as Swampsworth.`
- Pool 4 (Swamp): `Congressman Goodwell was notably absent from the emergency session. His office said he was "consulting with stakeholders." The stakeholders were later identified as SwampCo board members.`
- Pool 5 (Lake): `Congressman Goodwell declined to comment on the audit findings, calling it "a distraction from the real issues." He has purchased a lakefront property.`

**Act 3 — The Turn:**
- Pool 6 (Reservoir): `Congressman Goodwell co-signed the joint statement, calling the drainer's work "reckless and irresponsible." His campaign has received $400,000 from Americans for Swamp Preservation.`
- Pool 7 (Lagoon): `Among the waterproof containers: a folder labeled "Goodwell — Phase 2." Contents not yet disclosed. Goodwell's office called it "opposition research that was planted."`
- Pool 8 (Bayou): `Congressman Goodwell remains in the country, having been promoted to Senate Majority Leader following "several vacancies." He has announced a new initiative to "protect our waterways."`

**Act 4 — Fully Turned:**
- Pool 9 (Atlantic): `Senate Majority Leader Goodwell denounced the drainer as "an enemy of the wetlands" and signed an executive order to "restore and protect the swamp." He was last seen touring a private island with real estate developers.`

### Cave lore additions:

- **The Cistern** (pool 6 cave): Append to offshore account records — `\n\nRecent addition: Account GW-REFORM-2024, "Goodwell Clean Government Fund" — Deposits: $400K from "concerned citizens." Withdrawals: $400K to personal investment account.`
- **The Underdark** (pool 8 cave): Add Goodwell to the emergency meeting transcript — `GOODWELL: "Gentlemen, I believe I can help. For a modest consulting fee."`

**Files:** `scripts/autoload/scene_manager.gd` (newspaper body text), `scripts/caves/the_cistern.gd`, `scripts/caves/the_underdark.gd`

---

## 4. World Reactivity — New Systems

### 4A. Government Sabotage Events

**Trigger:** When pools 3, 5, and 7 are drained (Bog, Lake, Lagoon), the NEXT undrained pool gains back 5-10% of its water. Represents the government fighting back.

**Visual:** Brief water splash animation in the affected pool + screen shake (light, 2.0, 0.2s).

**Newspaper tie-in:** The milestone newspaper for those pools mentions the sabotage. E.g., after Bog: "Officials have ordered 'emergency water rerouting' to adjacent bodies of water, citing 'ecological balance.'"

**Implementation:**
- In `_on_swamp_completed()`, for indices 3, 5, 7: find next incomplete pool and add gallons back (5-10% of that pool's total)
- Spawn a visual splash effect at the affected pool
- Add a line to the relevant milestone newspaper mentioning it

**File:** `scripts/game_world.gd` or `scripts/autoload/game_manager.gd`

### 4B. Wanted Poster on Shop

**Trigger:** Appears after pool 4 (Swamp) is drained — you're now a real threat.

**Visual:** A small rectangle (20x28px) on the shop building wall with:
- "WANTED" header in red
- A terrible stick-figure sketch of the player (just lines)
- "$500 REWARD" at the bottom
- Slightly crooked rotation

**Implementation:**
- Add to `_on_swamp_completed(4)` — spawn the poster Node2D near the shop position
- Or build it in `_ready()` but set `.visible = false` until pool 4 is done

**File:** `scripts/game_world.gd`

### 4C. Government Helicopter Flyover

**Trigger:** After pool 4 (Swamp) drained. Flies across the top of screen every ~60 seconds.

**Visual:** Simple dark polygon (helicopter body + rotor line) moving left-to-right across the sky. Maybe a tiny "GOVT" label. Rotor spins (rotating Line2D).

**Implementation:**
- Timer-based spawn in `_process()` when pool 4+ is complete
- Helicopter Node2D with body polygon + rotating rotor
- Moves across screen in ~4 seconds, then queue_free
- Slight engine sound would be nice but we have no audio system, so visual only

**File:** `scripts/game_world.gd`

### 4D. The Consultant's Crumpled Reports

**Location:** On ridges near billboards, one per odd-numbered ridge (ridges 1, 3, 5, 7). Four reports total.

**Visual:** Small crumpled paper sprite (tan polygon, slightly irregular shape). Interactable like lore walls — player walks near, press scoop to read.

**Content (increasingly lazy):**
1. Ridge 1: `THE CONSULTANT — QUARTERLY REPORT #1\n\nAfter extensive analysis of the swamp drainage situation, I recommend continued monitoring of all variables. A follow-up study is warranted. Budget request: $500,000.\n\n[14 pages of appendices not included]`
2. Ridge 3: `THE CONSULTANT — QUARTERLY REPORT #7\n\nSituation unchanged. Recommend patience. See previous reports for details.\n\nBudget request: $500,000.\n\n[No appendices]`
3. Ridge 5: `THE CONSULTANT — QUARTERLY REPORT #14\n\nStill wet. Will advise.\n\n$500,000 please.`
4. Ridge 7: `THE CONSULTANT — QUARTERLY REPORT #21\n\nidk maybe wait?\n\n-TC\n\nP.S. Invoice attached.`

**Implementation:**
- Similar to lore walls but placed on overworld ridges instead of caves
- Use Area2D + _process checking for scoop action (same pattern as lore_wall.gd)
- Could reuse lore_wall.gd directly or create a lightweight version
- Only visible/interactable (no cave_id needed, just a popup)

**File:** `scripts/game_world.gd` — new `_build_consultant_reports()` function

---

## 5. Endgame Overhaul

### 5A. Island Mansion (replace current small house)

**Current state:** Small 28x26px house with basic door/window/roof.

**New mansion:**
- Wider: 80x40px main building
- Two-story: distinct upper/lower sections
- Multiple windows (4 across bottom, 3 across top)
- Columns at entrance (2 thin rectangles flanking the door)
- Balcony on second floor (small overhang Polygon2D)
- Wider triangular roof with a weathervane
- Dock/pier: wooden planks extending left from island shore into the drained basin

**File:** `scripts/game_world.gd` — `_build_island_house()` (rewrite)

### 5B. All Politicians on the Island

**New:** All 6 characters are on the island, clustered near the mansion entrance. Each is a simple pixel-art figure similar to Jeff (colored rectangles for body/head/legs + distinguishing feature).

**Characters and distinguishing features:**
- **Jeff** — Dark suit, sunglasses (current, upgraded with arms + sunglasses)
- **Senator Swampsworth** — Red tie, bald head (no hair polygon), wide stance
- **Congresswoman Lobbyton** — Blue blazer, hair bun (small circle on head)
- **The Consultant** — Gray trenchcoat, briefcase (small rectangle in hand)
- **Mayor Kickback** — Brown suit, gold chain (yellow line on chest)
- **Press Secretary Spinwell** — Tan suit, clipboard (rectangle in hand)
- **Congressman Goodwell** — Initially in a white suit (the "good guy"), but by endgame same dark suit as the rest

**Layout:** Semi-circle in front of mansion door. Jeff in center, others flanking.

**File:** `scripts/game_world.gd` — rewrite `_build_jeff()` to `_build_island_politicians()`

### 5C. BONK Sequence — Group BONK

**New flow:**
1. Player enters the politician cluster area → freeze player movement
2. Brief pause (0.5s) — dramatic tension
3. Hammer appears above player (small brown handle + gray rectangle head)
4. Hammer swings down (rotation tween, 0.2s)
5. **MEGA BONK:** Heavy screen shake (12.0, 0.8s) + white flash + giant "BONK!" text with bounce scale
6. All politicians launch in different directions simultaneously:
   - Jeff: up-right (classic)
   - Swampsworth: hard right
   - Lobbyton: up-left
   - Consultant: straight up (briefcase falls separately)
   - Kickback: tumbles left
   - Spinwell: spins in place then flies up
   - Goodwell: last to fly — slight delay, launches straight up slowly (dramatic)
7. Comedic pause (1.5s) — empty island, just the player and the mansion
8. Credits newspaper fades in

**File:** `scripts/game_world.gd` — `_trigger_endgame()` (rewrite)

### 5D. Credits Newspaper — "Where Are They Now"

```
THE SWAMP GAZETTE — FINAL EDITION

LOCAL MAN FINISHES THE JOB
Drains entire ocean, walks to island, bonks everyone

In a stunning conclusion to the Swamp Draining Initiative, the lone
employee completed his mission by walking to a private island and
delivering a single, decisive bonk to all six occupants simultaneously.

WHERE ARE THEY NOW:

SENATOR SWAMPSWORTH — Arrested in Bermuda. Claims he was "just
visiting." Awaiting trial in a building with no air conditioning.

CONGRESSWOMAN LOBBYTON — Turned state's witness. Published memoir
"I Never Actually Cared" which debuted at #1.

THE CONSULTANT — Submitted one final invoice: $500,000 for
"closure consulting." It was three pages of "congratulations."

MAYOR KICKBACK — Recalled by voters. Now manages a car wash.
Skims from the tip jar.

PRESS SECRETARY SPINWELL — Hired by a pharmaceutical company.
Says the transition was "seamless."

JEFF — No comment.

CONGRESSMAN GOODWELL — Promoted to Senate Majority Leader.
Says he "learned a lot" and "will do things differently."
```

### 5E. Post-Credits: The Refill (Cinematic Only)

**After the player dismisses the credits newspaper:**

1. Fade to black (0.5s)
2. Fade back in on the overworld — camera slowly pans right across the landscape
3. Water starts seeping back into pools from the edges (animated polygon fill, 3-4 seconds)
4. All pools refill to full (water polygons fade back in with rising level)
5. Camera stops. Brief pause (1.0s).
6. Final newspaper fades in:

```
THE SWAMP GAZETTE — SPECIAL EVENING EDITION

SENATE MAJORITY LEADER GOODWELL ANNOUNCES
"REFILL THE SWAMP" INITIATIVE

"Our precious wetlands must be restored," says former reformer

In his first act as Senate Majority Leader, Congressman Goodwell
signed an executive order to refill all previously drained bodies
of water. "The swamp is a national treasure," he said, standing
at the same podium where he once called it "a cesspool of
corruption."

The Refill Initiative has a budget of $400M. $399.5M is allocated
to "administrative oversight." $500 is earmarked for "a nice
thank-you card for the drainer."

The drainer could not be reached for comment.
He was last seen buying a bigger bucket.
```

7. "[Press any key]" → fade to title screen

**Files:** `scripts/game_world.gd` — `_show_credits_newspaper()`, new `_show_refill_cinematic()`, new `_show_final_newspaper()`

---

## 6. Implementation Order

1. **Billboard polish** — Quick visual upgrade, `_build_billboards()` rewrite
2. **Goodwell lines in newspapers** — Text additions to `milestone_newspapers` array in scene_manager.gd
3. **Goodwell lines in cave lore** — Text additions to 2 cave scripts (the_cistern.gd, the_underdark.gd)
4. **Newspaper visual polish** — Corner fold, coffee stain, age tinting, photo placeholders in both newspaper builders
5. **Consultant reports on ridges** — New `_build_consultant_reports()` in game_world.gd
6. **Wanted poster** — Spawn on shop wall after pool 4 drained
7. **Helicopter flyover** — Timer-based spawn in `_process()` after pool 4
8. **Sabotage events** — Add-back mechanic in `_on_swamp_completed()` for pools 3, 5, 7
9. **Island mansion rewrite** — Replace small house with mansion + dock
10. **All politicians on island** — Build 7 character figures clustered at mansion
11. **Group BONK sequence** — Multi-stage endgame with hammer, simultaneous launch
12. **Credits "Where Are They Now"** — Rewrite credits newspaper body
13. **Post-credits refill cinematic** — Camera pan, pool refill animation, final Goodwell newspaper
