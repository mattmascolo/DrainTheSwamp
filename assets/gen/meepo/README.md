# Meepo character animation sources

Humphrey, Forg, and Piggy come from Matt's Meepo character collection in
`calcryx-auto-battler/public/characters`. These sheets were generated with
the built-in imagegen tool using each character's `Idle_00.png` as a reference.
The original Meepo files were left unchanged.

Each transparent sheet has four columns and three rows: walk, scoop, and jump.
Tools are rendered separately in the game. Forg's music notes and boombox are
omitted so he can carry the game's tools.

Run `python3 tools/bake/bake_meepo.py` to reproduce the 128px game strips in
`assets/art/characters`. The first walking pose is also used for idle, with
the player's existing breathing motion. Character selection is cosmetic;
all characters share the same movement, tools, and economy.
