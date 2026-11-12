from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]/'tweak/Sources/Redesigned/Album'
class AlbumFieldOwnership(unittest.TestCase):
 def test_track_backings_ignore_global_tonal_rgb(self):
  s=(R/'AlbumRows.x').read_text();b=s[s.index('static void clearSurface'):s.index('static void applyHairline')]
  self.assertIn('view.backgroundColor = UIColor.clearColor',b)
  self.assertNotIn('SGRIsBaseSurface',b)
  self.assertIn('((UICollectionViewCell *)cell).selected',s)
  self.assertIn('((UICollectionViewCell *)cell).highlighted',s)
 def test_list_scope_is_album_only(self):
  s=(R/'AlbumField.x').read_text();b=s[s.index('%hook _TtC32CreativeWorkPlatform_TemplateKit28CreativeWorkTemplateListView'):s.index('// Every cell of the list')]
  self.assertIn('if (!SGRAlbumPageOf(list)) return;',b)
  self.assertIn('list.backgroundColor = UIColor.clearColor',b)
  self.assertIn('[sub isKindOfClass:UIScrollView.class]',b)
