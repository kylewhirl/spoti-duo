# Live light and dark appearance

The redesigned look has **Mod Settings → Appearance → Color appearance**:

- **Dark** selects dark backgrounds and light text.
- **Light** selects Spotify's semantic light theme and matching redesign surfaces, labels, glass and settings.
- **System**, the default when unset, follows the phone's appearance while Spotify is open and when scenes activate.

The picker applies the choice without restarting or interrupting playback. It queues one main-thread transaction and coalesces repeated requests. “Active appearance” reports the applied theme, provider drift or failure; a failed transition retains the previous rendered theme and may show a pending selection. Switching Native/Redesigned UI itself still requires a restart.

## Provider transaction and live refresh

`Redesigned/Kit/SGRAppearance.x` coordinates both independent stores: the Objective-C `SPTEncoreColorTheme.main` wrapper and native Swift `Encore.ColorTheme.main`. `SGRNativeTheme.m` resolves verified exported native accessors using their Swift calling convention and ownership rules. Both providers must verify before the selected appearance is published. Rejected changes roll back instead of partially enabling light styling. Missing APIs fail closed with visible status. Runtime code uses symbols, not hard-coded addresses or raw static writes.

After a successful transaction, `Core/SGAppearance.m` updates registered views/controllers and weakly owned refresh callbacks, then the scoped native-surface adapters refresh. Retained labels and controls use semantic colors. A short non-interactive snapshot crossfade is omitted when Reduce Motion is enabled. System mode observes scene traits and activation; it does not infer the phone's appearance from an already-overridden Spotify view.

The adapters cover native surfaces, glyphs, navigation, sheets, drawer, status bar and search, including retained controls and scope-exit restoration. The connection bar respects the navigation content lane. Queue confirmation preserves Spotify's native text and Open action. Explicit inverted/over-media colors and artwork must remain intentional. There is no whole-window guessed foreground/background color scan. These changes belong to the redesigned look; native-mode gates and restoration remain required.

## Current regression fixtures

Build from this authoritative checkout:

```
THEOS="$HOME/theos" sh harness/search-connection/build.sh
sh harness/search-connection/run.sh EXPLICIT_SIMULATOR_UDID
sh harness/queue-confirmation/build.sh
python3 -m unittest discover -s tests -v
```

`harness/search-connection` compiles the current production bridge, live settings, semantic surface adapters, retained navigation/sheets/drawer, glyphs, search and connection geometry. Its basic runner exercises Light and Dark. The fixture also exposes environment-driven System, provider failure and selector cases; the preserved November 9 matrix is historical evidence, not a fresh result for a later binary. See its README and source for coverage and limits.

`harness/queue-confirmation` compiles the production queue hooks/renderer with native localization assets and UIKit test shells. Its build needs the documented private cached SpotifyShared/SPTStrings dependencies. It does not execute a Spotify queue service. Use an explicitly coordinated simulator, never a physical device, for these fixtures.

The older `harness/appearance` fixture retains initial launch-only/restart-sheet assumptions and is historical, not the current acceptance suite. Current fixture screenshots are previews, not captures of signed-in Spotify.

## Verification status and history

The November 9 frozen search/queue checkpoint records 12 appearance matrix cases, 39,331 assertions and zero failures. Real-provider probes separately exercised cached SpotifyShared's two-store boundary, including rollback and repeated ownership transfers. These results establish their recorded source scope, not universal coverage of every Spotify screen.

On November 10, the favorite build regression was traced to replacing the entire tweak with a stale-root rebuild that omitted later appearance modules. The authoritative root was consolidated from the verified latest appearance snapshot plus only the four favorite source changes. The current main clean arm64 build and regression tests pass, and the current appearance/queue fixtures compile. Fresh simulator runtime checks are blocked by an unavailable CoreSimulator service. No new physical-device visual pass is claimed. The user confirmed the native favorite action works in the previously installed favorite build; that implementation is retained unchanged.

Historical checkpoints, original source backups, package hashes and current restoration results remain under `out/appearance-favorite-restoration/` and `out/native-surface-appearance-work/`. They are recovery and verification evidence, not competing current source trees. Follow `docs/current-build.md` for packaging and installation gates; AirPlay stays separate until proven.
