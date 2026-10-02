"""Slice reviewed 4x3 Meepo sheets into aligned game animation strips.

Sources are kept in assets/gen/meepo so the bake is reproducible without an API.
Run: python3 tools/bake/bake_meepo.py (requires Pillow).
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CELL = 128
BASELINE = 120


def bake(name):
    source = Image.open(ROOT / f"assets/gen/meepo/{name}.png").convert("RGBA")
    frames = []
    boxes = []
    for row in range(3):
        for col in range(4):
            frame = source.crop((round(col * source.width / 4), round(row * source.height / 3),
                                 round((col + 1) * source.width / 4), round((row + 1) * source.height / 3)))
            box = frame.getchannel("A").point(lambda a: 255 if a > 80 else 0).getbbox()
            if box is None:
                raise ValueError(f"{name}: empty frame {row},{col}")
            frames.append(frame)
            boxes.append(box)
    # One scale for every pose; don't inflate a crouching character to idle height.
    standing_height = max(b[3] - b[1] for b in boxes[:4])
    scale = min(78 / standing_height, 108 / max(b[2] - b[0] for b in boxes))
    row_baselines = [max(b[3] for b in boxes[row * 4:row * 4 + 4]) for row in range(3)]
    baked = []
    for index, (frame, box) in enumerate(zip(frames, boxes)):
        crop = frame.crop(box)
        crop = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.NEAREST)
        cell = Image.new("RGBA", (CELL, CELL))
        # Walking/scooping feet stay grounded. Airborne jump poses keep their lift.
        lift = round((row_baselines[2] - box[3]) * scale) if index >= 8 else 0
        cell.alpha_composite(crop, ((CELL - crop.width) // 2, BASELINE - crop.height - lift))
        baked.append(cell)
    destination = ROOT / "assets/art/characters"
    destination.mkdir(parents=True, exist_ok=True)
    for row, animation in enumerate(("walk", "scoop", "jump")):
        strip = Image.new("RGBA", (CELL * 4, CELL))
        for col in range(4):
            strip.alpha_composite(baked[row * 4 + col], (CELL * col, 0))
        strip.save(destination / f"{name}_{animation}.png")
    baked[0].save(destination / f"{name}_idle.png")


if __name__ == "__main__":
    for character in ("humphrey", "forg", "piggy"):
        bake(character)
