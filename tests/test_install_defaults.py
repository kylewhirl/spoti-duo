"""Run real NSUserDefaults persistence checks without touching the application/device domain."""
import pathlib
import platform
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

@unittest.skipUnless(platform.system() == "Darwin", "Foundation fixture requires macOS")
class InstallDefaultsTests(unittest.TestCase):
    def test_fresh_and_existing_profiles(self):
        with tempfile.TemporaryDirectory() as directory:
            executable = str(pathlib.Path(directory) / "defaults-test")
            subprocess.run([
                "xcrun", "clang", "-fobjc-arc", "-fblocks", "-DSG_INSTALL_DEFAULTS_TEST",
                "-framework", "Foundation", "-I" + str(ROOT / "tweak/Sources/Core"),
                str(ROOT / "tests/fixtures/install_defaults.m"),
                str(ROOT / "tweak/Sources/Core/SGInstallDefaults.m"), "-o", executable,
            ], check=True, capture_output=True, text=True)
            result = subprocess.run([executable], check=True, capture_output=True, text=True)
            self.assertIn("PASS", result.stdout)

    def test_seeds_before_feature_constructors(self):
        import uuid
        with tempfile.TemporaryDirectory() as directory:
            executable = str(pathlib.Path(directory) / ("defaults-order-" + uuid.uuid4().hex))
            subprocess.run([
                "xcrun", "clang", "-fobjc-arc", "-fblocks", "-framework", "Foundation",
                str(ROOT / "tests/fixtures/install_defaults_order.m"),
                str(ROOT / "tweak/Sources/Core/SGInstallDefaults.m"), "-o", executable,
            ], check=True, capture_output=True, text=True)
            result = subprocess.run([executable], check=True, capture_output=True, text=True)
            self.assertIn("PASS constructor ordering", result.stdout)
