"""Native flag policy regression. No device, media playback, or real library writes."""
from pathlib import Path
import platform
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(platform.system() == "Darwin", "Requires Apple Foundation")
class LockScreenFavoriteTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="spoti-favorite-test-")
        cls.addClassCleanup(cls.temp.cleanup)
        cls.binary = Path(cls.temp.name) / "favorite-test"
        src = ROOT / "tweak/Sources"
        result = subprocess.run([
            "xcrun", "clang", "-fobjc-arc", "-fblocks", "-Wall", "-Wextra", "-Werror",
            "-Wno-unused-parameter", "-I" + str(src), "-framework", "Foundation",
            str(ROOT / "tests/lock_screen_favorite_harness.m"),
            str(src / "Core/SGPrefs.m"), str(src / "Core/SGFlagForce.m"),
            str(src / "Shared/LockScreenFavorite/LockScreenFavorite.m"),
            "-o", str(cls.binary),
        ], capture_output=True, text=True)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)

    def scenario(self, name):
        result = subprocess.run([str(self.binary), name], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("PASS " + name, result.stdout)

    def test_fresh_default_without_preference_writes(self): self.scenario("fresh")
    def test_preserves_existing_off_override(self): self.scenario("prior-off")
    def test_preserves_existing_on_override(self): self.scenario("prior-on")
    def test_switch_and_all_flags_share_state(self): self.scenario("toggle")
    def test_auto_uses_mod_default(self): self.scenario("auto")
    def test_reset_restores_stock(self): self.scenario("stock")
    def test_unrelated_flags_and_editability(self): self.scenario("isolation")


if __name__ == "__main__":
    unittest.main()
