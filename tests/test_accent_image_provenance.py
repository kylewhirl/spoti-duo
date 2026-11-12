"""Structural regressions for semantic baked-image refresh; runtime fixture covers pixels."""
from pathlib import Path
import unittest

class AccentImageProvenance(unittest.TestCase):
    def test_only_explicit_semantic_tint_creates_recipe(self):
        s=(Path(__file__).resolve().parents[1]/'tweak/Sources/Redesigned/Kit/SGRAccent.x').read_text()
        body=s.split('static UIImage *recordTintedImage',1)[1].split('%hook UIImage',1)[0]
        self.assertIn('objc_getAssociatedObject(color,&sourceKey)',body)
        self.assertIn('result==base',body)
        self.assertNotIn('CGImageGet',body)
        self.assertIn('@(result.renderingMode)',body)
    def test_all_state_assignments_track_and_clear_recipe(self):
        s=(Path(__file__).resolve().parents[1]/'tweak/Sources/Redesigned/Kit/SGRAccent.x').read_text()
        for prop in ['image','highlightedImage']:
            self.assertIn('trackSource(self,@"'+prop+'",recipe)',s)
        self.assertIn('@"imageState:%lu"',s)
        self.assertIn('[sources removeObjectForKey:property]',s)
        self.assertIn('NSHashTable weakObjectsHashTable',s)
    def test_scoped_foreground_and_baked_images_follow_local_traits(self):
        s=(Path(__file__).resolve().parents[1]/'tweak/Sources/Redesigned/Kit/SGRAccent.x').read_text()
        mapped=s.split('static UIColor *mappedSource',1)[1].split('static UIColor *trackedColor',1)[0]
        self.assertIn('SGAppearanceStyleForTraits(traits)',mapped)
        self.assertNotIn('SGRedesignLightAppearance()',mapped)
        self.assertIn('resolvedColorWithTraitCollection:owner.traitCollection',s)
        self.assertIn('registerForTraitChanges:traits',s)
        self.assertNotIn('SGRegisterAppearanceRefresh(',s)
