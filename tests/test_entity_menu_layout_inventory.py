"""Keep the runtime-verified menu layout fix when source snapshots are consolidated.

These source guards complement, not replace, harness/entity-menu's real UIKit
old/new setter-count, routing, and geometry tests.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class EntityMenuLayoutInventoryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = (ROOT / 'tweak/Sources/Redesigned/Kit/SGRActionRow.m').read_text()
        cls.feed = cls.source.split('SGRMirrorButton *SGRPinnedMore(', 1)[1]

    def test_header_feed_does_not_force_or_request_nested_layout(self):
        self.assertNotIn('layoutIfNeeded', self.feed)
        self.assertNotIn('setNeedsLayout', self.feed)
        self.assertIn('[layout updatePlacement]', self.feed)

    def test_placement_alone_owns_visibility(self):
        self.assertNotIn('button.hidden =', self.feed)
        self.assertIn('if (!button.hidden) button.hidden = YES;', self.source)
        self.assertIn('if (button.hidden != !self.hasSource) button.hidden = !self.hasSource;', self.source)

    def test_unchanged_observer_frame_is_not_written(self):
        self.assertIn('if (!CGRectEqualToRect(layout.frame, page.bounds)) layout.frame = page.bounds;', self.feed)

    def test_runtime_setter_count_regression_remains_available(self):
        fixture = (ROOT / 'harness/entity-menu/main.m').read_text()
        self.assertIn('steadyMenuFeeds', fixture)
        self.assertIn('forcedLayouts==0 && layoutRequests==0', fixture)


if __name__ == '__main__':
    unittest.main()
