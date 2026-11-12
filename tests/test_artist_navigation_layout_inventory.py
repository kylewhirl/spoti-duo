"""Scope/ownership regressions for the proven artist title/inset feedback fix."""
from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]

class ArtistNavigationLayoutInventory(unittest.TestCase):
    def test_only_native_artist_layout_scope(self):
        source = (ROOT / 'tweak/Sources/Redesigned/Artist/ArtistNavigation.x').read_text()
        self.assertIn('SGRArtistPageOf(header)', source)
        self.assertIn('navigation.topViewController', source)
        self.assertIn('[root isDescendantOfView:pageView]', source)
        self.assertIn('@available(iOS 27.0, *)', source)
        self.assertIn('self == artistLayoutItem', source)
        self.assertIn('@finally { artistLayoutItem = previous; artistLayoutHasRail = previousRail; }', source)
    def test_does_not_change_native_fade_or_scrolling(self):
        source = (ROOT / 'tweak/Sources/Redesigned/Artist/ArtistNavigation.x').read_text()
        for setter in ['setContentOffset:', 'setAdditionalSafeAreaInsets:', 'setNavigationBarHidden:', 'setHidden:']:
            self.assertNotIn(setter, source)
    def test_native_title_and_banner_appearance_preserved(self):
        source = (ROOT / 'tweak/Sources/Redesigned/Artist/ArtistNavigation.x').read_text()
        for override in ['NSForegroundColorAttributeName', 'setAlpha:']:
            self.assertNotIn(override, source)
    def test_only_background_paint_is_cleared_in_artist_rail_scope(self):
        source = (ROOT / 'tweak/Sources/Redesigned/Artist/ArtistNavigation.x').read_text()
        self.assertIn('item != artistLayoutItem || !artistLayoutHasRail || !appearance', source)
        self.assertIn('copy.backgroundColor = UIColor.clearColor', source)
        self.assertIn('copy.backgroundEffect = nil', source)
        self.assertNotIn('titleTextAttributes =', source)
    def test_playlist_refreshes_native_back_after_registering_surface(self):
        source = (ROOT / 'tweak/Sources/Redesigned/Playlist/PlaylistField.x').read_text()
        register = source.index('SGRApplyNativeLightSurface(appearanceOwner.viewIfLoaded, NO)')
        refresh = source.index('SGRRefreshNativeNavigationAppearance(appearanceOwner.navigationController)')
        self.assertLess(register, refresh)
    def test_drawer_card_palette_is_scoped(self):
        source = (ROOT / 'tweak/Sources/Redesigned/Kit/SGRNativeSurface.x').read_text()
        self.assertIn('if (SGRDrawerOwnsView(view)) {', source)
        self.assertIn('if (at(w,42)) return SGRRoleElevated;', source)
        self.assertIn('if (at(w,71)) return SGRRoleSeparator;', source)
        self.assertIn('if (light==((role & SGRRoleLightSource)!=0)) return source;', source)
    def test_appearance_picker_remains_without_redundant_status(self):
        source = (ROOT / 'tweak/Sources/Redesigned/Kit/SGRAppearanceSettings.m').read_text()
        self.assertNotIn('@"Active appearance"', source)
        self.assertIn('@[@"Dark", @"Light", @"System", @"Match artwork"]', source)
        self.assertIn('SGRAppearanceApplyPreference()', source)
        self.assertIn('@"Accent colour"', source)
    def test_playlist_and_queue_modal_owners_use_scoped_sheet_adapter(self):
        source = (ROOT / 'tweak/Sources/Redesigned/Kit/SGRSheetAppearance.x').read_text()
        for cls in ['_TtC34PlaylistCuration_AddToPlaylistImpl26ATPContainerViewController', '_TtC34PlaylistCuration_AddToPlaylistImpl17ATPViewController', '_TtC14Queue_ViewImpl19QueueViewController']:
            hook = source.split('%hook ' + cls)[1].split('%end')[0]
            self.assertEqual(hook.count('SGRApplyNativeSheetAppearance((id)self)'), 3)
            self.assertNotIn('frame', hook)
            self.assertNotIn('hidden', hook)
    def test_nonempty_titles_are_never_cached_or_replaced(self):
        source = (ROOT / 'tweak/Sources/Redesigned/Artist/ArtistNavigationTitle.h').read_text()
        self.assertIn('return title.length ? title : @"\\u00a0";', source)

if __name__ == '__main__': unittest.main()
