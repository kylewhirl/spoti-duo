import pathlib
import unittest
ROOT = pathlib.Path(__file__).resolve().parents[1]
class PlaylistLightBacking(unittest.TestCase):
    def test_row_scope_preserves_nonrow_cleanup(self):
        s = (ROOT/'tweak/Sources/Redesigned/Playlist/PlaylistRows.x').read_text()
        body = s[s.index('static void applyRow'):s.index('%hook', s.index('static void applyRow'))]
        self.assertLess(body.index('clearSurface(cell);'), body.index('if (!row) return;'))
        self.assertIn('if(light && !interacting)', body)
        self.assertIn('else if(!light)', body)
        self.assertIn('if(v==cell)break;', body)
    def test_list_owned_light_only(self):
        s = (ROOT/'tweak/Sources/Redesigned/Playlist/PlaylistField.x').read_text()
        self.assertIn('SGRPlaylistHeaderOf(list) && SGAppearanceStyleForView(list)==UIUserInterfaceStyleLight',s)
        self.assertIn('list.backgroundColor && SGRIsBaseSurface(list.backgroundColor.CGColor)',s)
