> Current authoritative fixture, promoted November 10. Build from this checkout. Historical runtime results below refer to the preserved November 9 checkpoint, not a fresh run of the restored build. Fresh runtime checks remain blocked by CoreSimulatorService; current fixture compilation is checked separately. Historical logs/manifests/images remain in out/native-surface-appearance-work/source/harness/search-connection/.

# Search and connection appearance regression

This isolated simulator fixture compiles the production search appearance and connection-bar adapters, plus the existing full appearance regression fixture. It does not launch Spotify or contact a physical device.

Build and run from the source root:

```
THEOS="$HOME/theos" SRC="$PWD/tweak/Sources" OUT="$PWD/harness/search-connection/build" sh harness/search-connection/build.sh
harness/search-connection/run.sh EXPLICIT_SIMULATOR_UDID
```

`run.sh` uses only its supplied simulator, terminates the fixture, does not change the simulator's system appearance, and copies the fixture's own offscreen renderings. It does not use screenshots, a signed Spotify IPA, Device Hub, or physical-device tools.

## Coverage

- Both Dark-origin and Light-origin native search headers; eight retained live changes each.
- Explicit native dark blur, native Cancel normal-state color cached before registration, native query and chip ink, and retained AMOLED-black header.
- Rendered search text and material in both modes, native Cancel target-action delivered once, query/selection/placeholder/delegate preserved.
- Latest native effects/styles and input color/keyboard assignments restored on individual or ancestor scope exit; retained out-of-scope controls do not follow later changes. Native artwork and artwork effects remain untouched.
- 160 connection geometries per launch: widths 320/466/744/1000, both rail edges, LTR/RTL, ten repeated reflows each. Uses actual UIKit directional constraints and native-shaped message-label hierarchy.
- Native message text/background stays entirely inside the content lane; native band Y, height, vertical constraints and bottom reservation remain unchanged. Latest native horizontal constants restore when vertical mode ends or the bar detaches.
- Light and Dark composite renderings prove the connection band does not cover the bottom rail and its native status text remains legible.
- Includes the full inherited appearance suite and latest AddTo selection disagreement/repeated-event/untouched-action regressions from the parent worker.

## Native evidence and limits

`evidence/native-9.1.94.json` records the actual binary hash, decoded Objective-C selector implementations, and cached native message-bar tree/constraints. `evidence/extract.py` reproduces that extraction. Search HeaderViewController's load/view lifecycle, SearchBarContainer's text field, ChipView's effect ownership, and the exact message-bar class are proven by that cached binary/tree. Runtime code resolves class names and public UIKit methods; no recorded binary offsets are used at runtime.

The dedicated simulator is iOS 26.5. UIKit effect rendering, retained controls, native-adapter event hooks, and constraint reflow are exercised. The iOS 27.1 vertical-bar layout-region lookup cannot execute there; the production layout function receives explicit rail rectangles in the fixture. The fixture does not claim signed-in Spotify/physical-Duo verification or native network error generation. The native native message model, localization, timer and `sendAction` are not replaced. There are no preference or tab-composition writes.

`production.diff` and `production-manifest.json` cover exactly the five search/connection production files versus the frozen retained-settings source baseline. `tested-source/` preserves those inputs and the companion AddTo implementation; `fixture-source-manifest.json` records all source inputs present for the final fixture build. Rendered images are fixture previews, not Spotify screenshots.
