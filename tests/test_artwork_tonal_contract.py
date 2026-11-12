import pathlib,unittest
R=pathlib.Path(__file__).resolve().parents[1]/'tweak/Sources'
class ArtworkTonalContract(unittest.TestCase):
 def test_mode_commit_and_same_theme_refresh(self):
  s=(R/'Redesigned/Kit/SGRAppearance.x').read_text()
  block=s[s.index('if (available && selectedTheme==desired'):s.index('NSArray<UIView *> *covers=captureCovers')]
  for t in ['SGInt(SGRKeyArtworkPalette,mode==SGRAppearanceArtwork ? 1 : 0)==1','SGInvalidateAppearanceColors()','SGRefreshAppearanceOwners()','SGRRefreshNativeSurfaces()']: self.assertIn(t,block)
  self.assertIn('palette.rawDominantColor ?: palette.edgeColor',s)
 def test_revision_is_color_affecting_and_owned(self):
  s=(R/'Core/SGAppearance.m').read_text()
  self.assertIn('SGRPaletteRevisionTrait',s)
  self.assertIn('[traits valueForNSIntegerTrait:SGRPaletteRevisionTrait.class]',s)
  self.assertIn('for (UIView *view in appearanceViews.allObjects) applyViewStyle(view)',s)
 def test_tonal_tokens_keep_fixed_fallback(self):
  s=(R/'Redesigned/Kit/SGRTokens.m').read_text()
  self.assertIn('SGRArtworkRoleColor(role,isLight) ?: [(isLight?light:dark) resolvedColorWithTraitCollection:traits]',s)
  self.assertIn('BOOL valid=enabled && dominant',s)
  self.assertIn('CGColorCreate(space,c)',s)

 def test_independent_palette_setting_preserves_legacy_choice(self):
  s=(R/'Redesigned/Kit/SGRAppearanceSettings.m').read_text()
  self.assertIn('SGChoiceRow(@"Color theme"',s)
  self.assertIn('@[@"Standard", @"Match artwork"]',s)
  self.assertIn('if (SGInt(SGRKeyArtworkPalette,-1)<0) SGSetInt(SGRKeyArtworkPalette,paletteChoice)',s)
  self.assertIn('@[@"Dark", @"Light", @"System", @"Match artwork"]',s)
