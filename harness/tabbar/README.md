# Tab bar harness

The bottom of Spotify's main screen mocked under its own class names, so `Redesigned/Navbar/TabBar.x`
and `Redesigned/NowPlayingBar/NowPlayingBar.x` run for real over it on the Mac without the phone: the
tab bar container with Spotify's bar and its row of tabs, a page with a list on the tab's stack, the
now playing bar's page with its card, and Spotify's message bar (`LimitedExperienceIndicatorBar`, what
Offline and Private Session show) under the tab bar. It plays issue #33.

    THEOS=$HOME/theos ./build.sh
    xcrun simctl install <udid> build/TabBarHarness.app
    xcrun simctl launch <udid> com.vojta.tabbarharness shown
    xcrun simctl io <udid> screenshot shot.png

`build.sh` runs `logos.pl -c generator=internal` over `TabBar.x` and `NowPlayingBar.x` from the
checkout it sits in and links them with the real `Core/` and `SGRTokens.m`; `SRC=<other tweak/Sources>
./build.sh` builds an older tree instead, to compare. `Navbar.x` and `NavbarLayout.m` run the real saved composition. `stubs.m` stands in for
the accent/repaint hooks, Spotify URI dispatcher and Mod Settings. iOS 27 ends an app with no scene delegate at
launch, so the harness has one.

The layout is the one 9.1.78 makes in a compact width, with the addresses it was read from:

- `TabBarContainerImpl`'s view has a guide from 49 pt above its safe area's bottom to its bottom
  (`viewDidLoad`, 0x1008409a8); the stack holding the tab bar is as tall as the guide and stands on
  the view's bottom, and the tab bar is as tall as the stack (0x106fabb7c).
- The direct `SPNavigationController` wrapper gets 49 pt of safe area on top of the container's
  (0x10707bde4, confirmed separately from the page in the live 9.1.94 hierarchy). The now
  playing bar's share of the pages' inset comes another way in Spotify; here it is a stand-in of 64 pt
  on the page, so the list's end marks where Spotify thinks the bars begin.
- The chrome puts the tab bar container above the message bar, and the now playing bar's page (64 pt,
  its content 8 pt above its bottom, 0x105345190) on the container's guide's top, which is the bottom
  anchor `MainUIContainer` gives the chrome (0x100ae0178).
- The message bar is its message plus the safe area it pads the message by, 22 pt here.

Launch words: `none` no message bar; `shown` one sliding in at 1.5 s; `away` one there from the start,
sliding away at 1.5 s; `cycle` in at 1.5 s and out at 4.5 s, for a recording. At 2.5 s everything is
logged in window points, with the gap between the bottom of the now playing card and the top of the
glass bar's platter (8 pt is the redesign's own, on a Face ID phone with nothing under the bar), and
half way through a slide what the screen shows of the message bar, the tab bar and the now playing bar:

    xcrun simctl spawn <udid> log show --last 1m --style compact --predicate 'eventMessage CONTAINS "[harness]" OR eventMessage CONTAINS "tab bar:"'

Before the fix the gap was -26 pt with nothing under the bar on an iPhone SE, and with the message bar
up on any phone: UIKit's glass bar is 83 pt, Spotify's bar was its 49 pt row with no inset under it,
and the glass bar stood the difference above it, over the now playing bar.

What it does not cover: Spotify's own chrome, which is Swift with no symbols (the constraints above
are read from its code, not run), the real now playing bar's content and its page's inset, the tab
bar hidden by a page, the player's open and close over the bars, and a regular width.

## Native vertical-bar regression

With an iOS 27.1+ SDK and a Duo simulator, the same harness follows the window's real
`verticalBarEdge` and bar layout region. No simulated model or width switch is used. The `cycle`
scenario asserts the rail matches that region, the four icon-only 48pt controls retain accessible names and receive hits outside Spotify's
bottom bar, inside one bottom-aligned 52×202pt glass pill, and the miniplayer stays beside the rail and above the bottom safe area, before/during/
after the message bar. On ordinary phones it asserts that the existing system bottom bar remains.
For multi-display simulators, add `--display=1` (or the desired ID from `simctl io <udid> enumerate`)
to screenshots. The navigation wrapper's exact 49pt tab-row contribution is removed only in vertical mode;
its other edges and the separate page/miniplayer inset are retained. The fixture also exercises
a caller replacing the bottom inset with 61pt, and moving the navigation controller outside and
back into the tab container. Ordinary-phone navigation retains its original 49pt. This covers
ownership restoration, not a physical fold or live vertical-bar trait transition.

The four default tabs are Home, Search, Library and Create. All remain visible until the existing
Navbar tab editor hides them; the separate global Hide Create override was removed. Previously
stored override values are left untouched and ignored. Tests verify Create shown and hidden,
custom tabs, hidden Search, explicit reordering, disabling custom navbar, and unchanged saved
values after layout. The four-item default pill is 202pt tall. The `reservation` launch argument
also checks 16 stock/custom tabs across six rail heights (470, 220, 164, 112, 80, 470pt), window
hit testing, selected-state restoration and default scroll-offset restoration.

## Label policy and theme selection

`SGRTabPolicy.h` owns a read-only policy: only the exact `com.kyle.spotipw.duo` bundle forces
icons-only labels. Its fully-open portrait state uses the user's Hide labels setting. All other
bundles always use that preference, including original spoti.pw on Duo hardware. The vertical
rail stays icon-only and retains accessible names. No screen-width or hardware-model heuristics
are involved, and no preference is written when posture changes.

The real source bar owns a `UIHingeInteraction`, available from iOS 27.1, receiving initial and
later posture updates. Scene effective geometry supplies orientation. Unknown, unavailable,
closed and partially-open posture remain icons-only for the Duo bundle. The harness checks all
160 combinations of four bundle identifiers, four postures, five orientations and both stored
preference values through the production policy. This matrix is not evidence of a physical fold.
For the Duo-identifier fixture, an independent public hinge observer checks the rendered title
result against the actual simulator posture as well.

Append `light` to any scenario to test Light. Both Light and Dark exercise each tab's authoritative
icon `isActive` with deliberately contradictory label colors, then disable that getter in the mock
to verify semantic-label fallback. Translucent secondary labels cannot mark a tab selected.

Build isolated variants without replacing the normal fixture output:

    THEOS=$HOME/theos OUT=../../out/navbar-preferences-qa/build-duo BUNDLE_ID=com.kyle.spotipw.duo ./build.sh

Only install that identifier variant in a dedicated simulator where it does not replace an existing
app. It is a fixture, not Spotify. The normal default bundle remains `com.vojta.tabbarharness`.

November 9, 2026 simulator regression logs are under `out/navbar-preferences-qa/`: ordinary iOS 26.5
phone message-bar cycles in Light and Dark, native Duo rail tests with the original bundle, and
Duo-identifier label/selection checks. Full Spotify still requires physical validation of folding,
rotation, navigation, player opening and its real page/chrome constraint graph.
