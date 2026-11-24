"""Source-level regression checks for the native Home prompt in the redesigned feed."""
from pathlib import Path
import unittest

HOME = Path(__file__).resolve().parents[1] / "tweak/Sources/Redesigned/Home/HomeSections.x"
SOURCE = HOME.read_text()


def section(start, end):
    return SOURCE.split(start, 1)[1].split(end, 1)[0]


class HomeTalkToSpotifyTests(unittest.TestCase):
    def test_spotify_controls_availability_and_dj_badge_stays_off(self):
        flags = section('SGRedesignForceFlags(@"home"', 'if (!SGRedesignedUI())')
        self.assertNotIn("interactive_entrypoint", flags)
        self.assertIn('@"ios-home-evopage-impl.dj_mdc_beta_badge_enabled": @NO', flags)

    def test_prompt_is_kept_before_unknown_sections_are_dropped(self):
        kind = section('static SGRHomeKind kindOf(', 'static void collapse(')
        self.assertLess(kind.index('if (isPromptSection(root, 10, &inspectionBudget)) return SGRHomeKindKeep;'),
                        kind.index('return SGRHomeKindDrop;'))
        self.assertIn('return gridKind(', kind)
        self.assertIn('return stackKind(', kind)
        prompt = section('static BOOL isPromptSection(', 'static SGRHomeKind kindOf(')
        self.assertIn('InteractiveEntryPoint', prompt)
        self.assertIn('accessibilityIdentifier', prompt)
        self.assertIn('UITextField.class', prompt)
        self.assertIn('UIAccessibilityTraitSearchField', prompt)
        self.assertNotIn('accessibilityLabel', prompt)
        self.assertIn('NSUInteger inspectionBudget = 96;', kind)
        self.assertIn('if (depth == 0 || *remaining == 0) return NO;', prompt)
        self.assertIn('--*remaining;', prompt)
        for marker in ('Discovery_PromoElement', 'Discovery_MediumDensityCardKit',
                       'Discovery_PreviewElement', 'Discovery_DJElementKit', 'ActionCardCarouselElement'):
            self.assertLess(prompt.index(marker), prompt.index('UITextField.class'))
        self.assertLess(prompt.index('if ([view isKindOfClass:UICollectionView.class]) return NO;'),
                        prompt.index('isPromptSection(child, depth - 1, remaining)'))

    def test_reused_cell_is_restored_before_measuring_or_remeasured_after_restore(self):
        fitting = section('- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:',
                          '- (void)layoutSubviews')
        self.assertLess(fitting.index('expand(cell);'),
                        fitting.index('UICollectionViewLayoutAttributes *result = %orig;'))
        self.assertRegex(fitting, r'if \(collapsed\) \{\s*expand\(cell\);\s*result = %orig;')
        restore = section('static void expand(', '%hook ')
        for property in ('content.hidden = NO', 'cell.clipsToBounds = NO',
                         'cell.accessibilityElementsHidden = NO'):
            self.assertIn(property, restore)


if __name__ == "__main__":
    unittest.main()
