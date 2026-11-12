"""Prevent shipping a partial checkout that drops released appearance or favorite features."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / 'tweak/Sources'

class CurrentFeatureInventoryTests(unittest.TestCase):
    def test_released_appearance_modules_are_present(self):
        required = [
            'Kit/SGRAppearance.x', 'Kit/SGRNativeTheme.m',
            'Kit/SGRNativeSurface.x', 'Kit/SGRNativeGlyph.x',
            'Kit/SGRDrawerAppearance.x', 'Kit/SGRSheetAppearance.x',
            'Kit/SGRNavigationAppearance.x', 'Kit/SGRStatusBarAppearance.x',
            'Kit/SGRSearchAppearance.x', 'Kit/SGRShareControls.m',
            'Kit/SGRConnectionBar.x', 'Queue/SGRQueueConfirmation.x',
            'Queue/SGRQueueConfirmation.m',
        ]
        for name in required:
            with self.subTest(source=name):
                self.assertTrue((SOURCES / 'Redesigned' / name).is_file(),
                    'Released appearance source missing. Do not replace the current dylib with a partial build.')

    def test_current_regression_fixtures_are_in_authoritative_checkout(self):
        for name in ['search-connection', 'queue-confirmation']:
            for source in ['main.m', 'build.sh', 'README.md']:
                with self.subTest(fixture=name, source=source):
                    self.assertTrue((ROOT / 'harness' / name / source).is_file())

    def test_native_favorite_feature_is_present(self):
        self.assertTrue((SOURCES / 'Shared/LockScreenFavorite/LockScreenFavorite.m').is_file())
        settings = (SOURCES / 'Shared/Player/PlayerSettings.m').read_text()
        self.assertIn('SGLockScreenFavoritePreferenceKey()', settings)

if __name__ == '__main__':
    unittest.main()
