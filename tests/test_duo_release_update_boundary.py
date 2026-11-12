"""Release candidate must never route Duo updates to the original project's feed."""
from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]

class DuoUpdateBoundary(unittest.TestCase):
    def test_no_network_or_usage_sender(self):
        source = (ROOT / 'tweak/Sources/App/About/Update.m').read_text()
        for prohibited in ('NSURLSession', 'https://', 'SGUsageBody()', 'SGUsageNoteAsked()', 'arrayForKey:'):
            self.assertNotIn(prohibited, source)
        self.assertIn('SGUpdateReleases(void) { return @[]; }', source)
        self.assertIn('SGUpdateVersion(void) { return nil; }', source)

    def test_usage_disabled_even_for_old_preferences(self):
        source = (ROOT / 'tweak/Sources/App/About/Usage.m').read_text()
        self.assertIn('SGUsageBody(void) { return nil; }', source)
        self.assertIn('SGUsageOwed(void) { return NO; }', source)
        for prohibited in ('NSUserDefaults', 'NSUUID', 'NSURLSession', 'https://'):
            self.assertNotIn(prohibited, source)

    def test_no_misleading_upstream_prompts(self):
        for path in ('App/ModSettings.x', 'App/Onboarding/Onboarding.x', 'App/Onboarding/Tour.m'):
            source = (ROOT / 'tweak/Sources' / path).read_text()
            for prohibited in ('SGWatchForDonate();', 'SGOfferDonate();', 'SGDonateAfterTour(self.needsRestart)', '@[SGDonateRow()]', 'stringByAppendingString:@"/issues"'):
                self.assertNotIn(prohibited, source)

    def test_no_fake_update_option(self):
        source = (ROOT / 'tweak/Sources/App/About/UpdatePage.m').read_text()
        body = source
        self.assertIn('Duo updates are not configured', body)
        self.assertIn('Automatic checks are off.', body)
        self.assertNotIn('SGKeyUpdateNotice', body)
        self.assertNotIn('Check now', body)

if __name__ == '__main__':
    unittest.main()
