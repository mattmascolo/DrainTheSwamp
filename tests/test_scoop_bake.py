"""Scoop frames must translate body parts without leaving standing duplicates."""
import importlib.util
from pathlib import Path
import unittest

from PIL import Image

spec = importlib.util.spec_from_file_location(
    "scoop_baker", Path(__file__).resolve().parents[1] / "tools/bake/build_scoop_from_idle.py"
)
baker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(baker)


class ScoopBakeTests(unittest.TestCase):
    def test_body_and_arm_move_once_and_boots_stay_planted(self):
        source = Image.new("RGBA", (19, 41))
        head, arm, boot = (255, 0, 0, 255), (0, 255, 0, 255), (0, 0, 255, 255)
        source.putpixel((12, 5), head)
        source.putpixel((6, 20), arm)
        source.putpixel((12, 36), boot)
        for dx, dy, ax, ay in baker.FRAMES[1:]:
            with self.subTest(frame=(dx, dy, ax, ay)):
                result = baker.build_frame(source, dx, dy, ax, ay)
                self.assertEqual(result.getpixel((12 + dx, 5 + dy)), head)
                self.assertEqual(result.getpixel((6 + dx + ax, 20 + dy + ay)), arm)
                self.assertEqual(result.getpixel((12, 36)), boot)
                self.assertEqual(sum(result.getpixel((x, y))[3] > 0 for y in range(result.height) for x in range(result.width)), 3)

    def test_transition_is_identical_to_idle(self):
        source = Image.new("RGBA", (19, 41), (40, 60, 80, 255))
        self.assertEqual(baker.build_frame(source, *baker.FRAMES[0]).tobytes(), source.tobytes())


if __name__ == "__main__":
    unittest.main()
