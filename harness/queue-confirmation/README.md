> Current authoritative fixture, promoted November 10. Build from this checkout. Historical runtime results below refer to the preserved November 9 checkpoint, not a fresh run of the restored build. Fresh runtime checks remain blocked by CoreSimulatorService; current fixture compilation is checked separately. Historical logs/manifests/images remain in out/native-surface-appearance-work/source/harness/queue-confirmation/.

# Queue confirmation refinement

## Implemented

Three new production files under `tweak/Sources/Redesigned/Queue/` restyle the native queue-success snackbar as a centered, content-sized Liquid Glass capsule with a queue symbol, the native truthful confirmation text, and Open. No other production files were edited by this worker.

The feature uses the actual native localized success values for `Queue:sSongAddedToUpNext` and `Queue:sSongAddedToPlayNext` through SpotifyShared's verified exported `__sptloc_localized` C boundary. There is no English-only/substr matching. Missing localization assets/API or an unfamiliar content/control shape leaves the original native banner in place. The actual English native values are “Added to Queue” and “Track added to top of Queue”; the renderer does not claim an appended track is playing next.

The original bound content and Open button remain alive in their original hierarchy. A standard accessible UIButton forwards one touch-up-inside event to the native control. The real native model's bindView: uses UIControlEventTouchUpInside (0x40), and its action invokes its original block and didPerformAction. Detachment and a new native bind both reset the presentation guard, including same-text, same-view/button reuse. The previous pill is released before native bindView: runs so its saved state cannot overwrite fresh alpha/accessibility values written by the new native binding. Long strings, large Dynamic Type, small heights and narrow widths fall back to native rather than truncate or reduce text size. The native look, errors, restrictions, unrelated messages, dismissal and queue state are unchanged.

The native presenter still owns all outer position/height/layout-guide constraints. Its show/hide animation methods target currentPresentedSnackbar.layer, not the inner content container hidden by this adapter. Thus a side navigation rail, keyboard, now-playing bar and connection strip use the same native positioning. Full signed-in layout coverage still needs a device check.

## Existing Play Next is unchanged; post-add button remains absent

spoti.pw already exposes a “Play next in the context menu” switch in Native look → Player → Queue & devices (`Native/Player/PlayerSettings.m:54`). It overrides Spotify's own `ios-feature-queue.is_play_next_context_menu_enabled` flag. The extracted Spotify 9.1.94 fallback is off; without a stored override, the tweak preserves Spotify's remote-config result. No source forcer enables it. Redesigned mode hides that Queue & devices page, but All flags is available in both modes and the existing shared override applies in both. This is Spotify-shipped action code exposed through an existing tweak setting, not a newly implemented queue operation. Kyle's current device setting and live menu behavior were not inspected. Nothing here changes or enables that existing feature.

A post-add Play Next button is deliberately absent. Cached native Spotify 9.1.94 has:

- Queue_ViewImpl.PlayNextAction.execute:, which selects a playback/queue branch, invokes queueTrackPlayNext:, then registers addCallback: and addErrorCallback:.
- SPTPlayerQueueWrapperImpl.queueTrackPlayNext:, which fetches the current queue and constructs `[selected track] + filtered queued tracks + filtered context tracks`, then calls setNextTracks: and setQueue:. Its two queue filters are complementary metadata predicates. It does not move/remove an exact existing appended item by UID.
- SPTEsperantoPlayer.playAsNextInQueue:options:loggingParams: and addToQueue:options:loggingParams:.

Calling native insert-next after the user already appended risks a second copy. The ordinary text/button snackbar model has no verified appended item UID. A safe binding from a completed append to its exact new queue item/revision has not been established. No URI-based removal, current-track skip, append/reorder race, Web API fallback, fake success UI, menu flag, or queued-item mutation was added. Enabling Spotify's native pre-add Play Next context-menu row could be a separate product choice, but is not a substitute silently introduced here.

`native-evidence.json` and reproducible read-only `native_calls.py` record decoded selectors from the actual cached main binary. This is static evidence, not execution of its queue service. The binary SHA256 is 50ac192d8ee014d7f34181fc338374bd11504c8c772fd867572580b3fa176daf.

## Verification

Final fixture: 32/32 assertions in `result.json`. `light.png` and `dark.png` were visually inspected. These are labeled fixture previews, not screenshots of Spotify or the physical Duo.

- Compiles actual production Logos hooks, queue renderer, Core appearance owners, SGRTokens, Core SGGlass and SGRGlass.
- Real UIKit UIGlassEffect renders on the dedicated iOS 27.1 Duo Simulator. Actual SpotifyShared localization function and unchanged SPTStrings assets return both native confirmation strings.
- Main-app SPTSnackbarView, SPTSnackbarWithActionView and text-button model are reconstructed shells. Open is verified against a real UIKit UIButton target/action in those shells, not Spotify queue navigation. No playback/queue service is executed.
- Covers one-shot Open forwarding, enabled state, same-text model rebind, native alpha/accessibility state written during rebind, detach/reinsert, 100 repeated layouts, native-mode restoration, truthful native text, errors/unrelated messages, center/width/touch sizes, RTL, long action text, narrow width, large Dynamic Type, retained Light/Dark, and native-root alpha inheritance.
- Reduce Transparency uses an injected accessibility boolean at the fixture boundary to test the production solid/glass mode transition. It does not claim an actual OS accessibility-setting run. No simulator system appearance/accessibility preferences were changed.
- Device arm64 iOS 16 syntax checks passed with `-Werror` for both production implementation and generated Logos hook. Source layer check passed. No full release/package build is claimed here.

The fixture initially needed scene-lifecycle support for iOS 27 and the native SPTStrings bundle. These were fixture setup failures, fixed before the reported passing runs. Testing the real C lookup revealed that the Swift namespace API qualifies keys with a colon; the production code now uses the verified native key format.

Only simulator 262BA20E-6672-4424-AC97-A5B7A45796AE was used. It began shutdown and was returned to shutdown. No physical device, Device Hub, signed-in Spotify, installation package, prior frozen snapshot or sharing repository was touched.

## Reproduce / artifacts

Run `build.sh`, then install/launch its `build/QueueConfirmationFixture.app` on the explicitly coordinated simulator. Copy Documents/result.json, light.png and dark.png. The script reads private prior probe/native assets for its local dependencies. `build/` is ignored and contains proprietary local framework/resources: never share/publish/copy that directory into a public source artifact.

Production source SHA256:

- SGRQueueConfirmation.h: 4551697d4e57c59426cc328d36bb9adcc2aeb0f451df7c8db8ca5d0234142b00
- SGRQueueConfirmation.m: 68a35a72e885572b819f8d746d9c82bed1cddea141b8b5f0fb87379c10a90396
- SGRQueueConfirmation.x: d6fa2728631205eea27ab8b33d15df695f9b952844385be681d0d5f1ca359046
