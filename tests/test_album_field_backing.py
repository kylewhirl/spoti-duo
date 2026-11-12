from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]/'tweak/Sources/Redesigned/Album'
class AlbumFieldBacking(unittest.TestCase):
 def test_proven_row_backings_not_reclassified_by_rendered_color(self):
  s=(R/'AlbumRows.x').read_text()
  f=s.split('static void clearSurface',1)[1].split('static void applyHairline',1)[0]
  self.assertIn('view.backgroundColor = UIColor.clearColor',f)
  self.assertNotIn('SGRIsBaseSurface(',f)
  self.assertIn('RetrievalListStructuredData',s)
  self.assertIn('SGRAlbumPageOf(cell)',s)
  self.assertIn('.selected ||',s)
  self.assertIn('.highlighted',s)
 def test_template_list_uses_own_album_field(self):
  s=(R/'AlbumField.x').read_text()
  self.assertIn('if (!SGRAlbumPageOf(list)) return',s)
  self.assertIn('[sub isKindOfClass:UIScrollView.class]',s)
  self.assertIn('list.backgroundColor = UIColor.clearColor',s)
