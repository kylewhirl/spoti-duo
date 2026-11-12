# GPL source candidate verification

This isolated source candidate preserves the Duo layout and artwork-theme work while excluding
later restricted upstream additions. It is not the complete installed Spotify app package.

Completed checks and their logs are kept locally under ignored `out/`:
- Clean arm64 Theos compile, link and tweak package.
- Native rail control fixture: 230 checks, zero failures.
- 79 source/packaging/defaults/update-boundary regression tests passed.
- Reduced UIKit artwork fixture: 3,190 and 3,193 checks passed with zero failures
  for the two appearance settings. This tests real theme source with mocked player inputs,
  not the complete Spotify runtime.

The generated flag table was supplied as local build input and remains excluded from release.
Simulator and physical-device testing of this rebased candidate must be distinguished from
previous testing of the development build. No physical app install is implied by this document.

The artist follow-up also passed reduced native fixtures in the development checkout using
identical changed source: 3,195 backing checks and 34 header-geometry checks, zero failures.
Those fixture runs were not full Spotify runtime or physical-device verification.
