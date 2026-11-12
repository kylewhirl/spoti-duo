"""Regression inventory for optional, player-local artwork appearance."""
from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]/'tweak/Sources'
class ArtworkAppearanceTests(unittest.TestCase):
 def test_optional_local_mode_does_not_change_global_preference(self):
  s=(R/'Redesigned/Player/PlayerAppearance.m').read_text()
  self.assertIn('SGInt(SGRKeyPlayerArtworkAppearance,0)==1',s)
  self.assertIn('SGClearAppearanceScope(root)',s)
  self.assertNotIn('SGSetInt(',s)
  self.assertNotIn('SGConfigureRedesignAppearance(',s)
 def test_palette_uses_raw_luminance_and_async_identity_guard(self):
  p=(R/'Redesigned/Kit/SGRPalette.m').read_text()
  self.assertIn('palette.artworkLuminance = artworkLuminance',p)
  f=(R/'Redesigned/Kit/SGRField.m').read_text()
  self.assertIn('generation != field->_generation',f)
  self.assertIn('self.artworkLuminanceChanged(palette.artworkLuminance)',f)
 def test_modals_form_global_appearance_boundary(self):
  s=(R/'Redesigned/Kit/SGRSheetAppearance.x').read_text()
  self.assertIn('SGSetAppearanceScope(root, UIUserInterfaceStyleUnspecified)',s)
 def test_global_match_artwork_keeps_existing_mode_values(self):
  s=(R/'Redesigned/Kit/SGRAppearance.h').read_text()
  for mode,value in [('Dark',0),('Light',1),('System',2),('Artwork',3)]:
   self.assertIn(f'SGRAppearance{mode} = {value}',s)
  p=(R/'Redesigned/Player/PlayerAppearance.m').read_text()
  self.assertIn('!=SGRAppearanceArtwork',p)
 def test_global_artwork_generation_and_identity(self):
  s=(R/'Redesigned/Kit/SGRAppearance.x').read_text()
  self.assertIn('generation!=artworkGeneration',s)
  self.assertIn('![identity isEqual:artworkIdentity]',s)
  self.assertIn('SGRCurrentNowPlayingArtwork',s)
 def test_artwork_accent_is_independent_and_retains_manual_choice(self):
  s=(R/'Redesigned/Kit/SGRAccent.x').read_text()
  self.assertIn('SGInt(SGRKeyAccentArtwork,0)==1',s)
  start=s.index('void SGRSetArtworkAccent(');end=s.index('UIColor *SGRAccentColor(',start)
  self.assertNotIn('SGSetInt(SGRKeyAccent,',s[start:end])
 def test_transition_keeps_previous_theme_while_current_art_is_pending(self):
  s=(R/'Redesigned/Kit/SGRAppearance.x').read_text()
  self.assertIn('if (!SGRCurrentNowPlayingArtworkPending())',s)
  b=(R/'Redesigned/Kit/SGRBridges.x').read_text()
  self.assertIn('sg_artworkPending=YES',b)
  self.assertIn('SGRCurrentNowPlayingArtworkPending(void)',b)
