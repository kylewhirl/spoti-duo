import pathlib
import unittest
R=pathlib.Path(__file__).resolve().parents[1]/'tweak/Sources/Redesigned'
class ArtistBacking(unittest.TestCase):
 def test_source_not_emitted_rgb(self):
  s=(R/'Kit/SGRNativeSurface.x').read_text()
  f=s[s.index('BOOL SGRNativeSurfaceHasNeutralBacking'):s.index('static void remember')]
  self.assertIn('originals(view,NO)',f)
  self.assertIn('roles(view,NO)',f)
  self.assertIn('SGRRoleElevated',f)
  self.assertNotIn('view.backgroundColor',f)
 def test_artist_scope_and_content_exclusions(self):
  s=(R/'Artist/ArtistSections.x').read_text()
  self.assertIn('SGRArtistPageOf(cell)',s)
  self.assertIn('item.selected || item.highlighted',s)
  self.assertIn('UIImageView.class',s)
  self.assertIn('UIControl.class',s)
  self.assertIn('view.bounds.size.width<wide',s)
 def test_keep_old_non_scroll_cleanup(self):
  s=(R/'Artist/ArtistField.x').read_text()
  self.assertIn('([sub isKindOfClass:UIScrollView.class] && SGRNativeSurfaceHasNeutralBacking(sub)) || (sub.backgroundColor && SGRIsBaseSurface(sub.backgroundColor.CGColor))',s)
