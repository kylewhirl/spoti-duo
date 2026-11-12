# Spoti Duo

A community Spotify iOS customization focused on the iPhone Duo: a side navigation rail,
Liquid Glass controls, Light/Dark/System appearance, and optional artwork-driven colors.

**Source-release candidate.** This tree is based on the unambiguously GPL-3.0 revision of
[skopevoj/spoti.pw](https://github.com/skopevoj/spoti.pw), with the Duo changes ported separately.
It does not include later PolyForm-licensed upstream features. See [provenance](docs/provenance.md).
Not affiliated with Spotify or Apple.

## Features

- Duo-aware side navigation and full-width layouts for Library, albums, artists and playlists.
- Light, Dark, System or Match Artwork appearance.
- Independent Match Artwork color theme and accent options, with live song changes.
- Now Playing can follow the app appearance or choose artwork-driven lightness independently.
- Native-surface light-mode corrections, neutral dividers and contrast-aware colors.
- Play Liked Songs and Play Playlist by Link App Intents; physical Shortcuts compatibility may vary.

On a fresh mod installation, defaults use System appearance, artwork theme and accent, and
Now Playing follows the app. Existing settings are not overwritten.
Upstream usage reporting is disabled entirely. Update checks are unavailable until a
Duo-specific release feed is configured; this candidate never checks upstream releases.

## Build

This repository contains **the tweak source, not Spotify or a prebuilt Spotify IPA**. Supply your
own lawfully obtained compatible app input and signing credentials. No credentials are bundled.
The upstream base targeted Spotify 9.1.78; the Duo changes have been developed against 9.1.94.
Private classes differ between releases, so a successful build does not prove compatibility.

Requirements: macOS, Xcode with an iPhoneOS 27.1+ SDK for Duo edge-to-edge packaging, Theos,
GNU make, `ldid`, `dpkg`, `zsign`, `libimobiledevice`/`ideviceinstaller`, Python 3 and `cyan`.
See the build scripts for the external tool requirements. The redesign requires iOS 26+.

```sh
export THEOS="$HOME/theos"
EXPECTED_SPOTIFY_VERSION=9.1.94 make release DUO=1 IPA=/path/to/your/Spotify-9.1.94.ipa
```

`DUO=1` opts the host executable into the installed SDK's Duo compatibility behavior with Apple's
`vtool`. It preserves the minimum OS and existing load commands; it does not recompile Spotify.
The source IPA is validated and its flag list is generated locally rather than distributed.

To build just the tweak (after generating the flag list from your local input):

```sh
make flags IPA=/path/to/your/Spotify-9.1.94.ipa
env -u MAKELEVEL gmake -C tweak clean package
```

Use your own signing setup. `.signing.env.example` documents the local-only inputs for
`scripts/install.sh`. Select the intended device explicitly with `DEVICE_UDID`; `WIFI=1` uses an
already paired network connection. These scripts do not establish pairing. Advanced Watch,
widget and CarPlay packaging requires appropriate entitlements/profiles; a successful tweak
build does not grant those capabilities or verify their operation.

No debugger binary or CI workflow is bundled in this source candidate. Optional debugger
injection requires an independently authorized package supplied via `FLEX_DEB` and `--flex`.

## Test

```sh
python3 -m unittest discover -s tests -v
```

Native reduced UIKit fixtures live under `harness/`; each has its build/run requirements.
These tests do not replace physical-device playback, navigation, fold/unfold and accessibility
checks in the actual app. The queue native-framework fixture requires separately supplied local
framework/resources; it does not distribute them.

## License and credits

GPL-3.0; see [LICENSE](LICENSE). Retain upstream copyright/attribution and mark modifications.
Theos builds the tweak and cyan injects it. The audio dependencies retain their MIT and zlib
licenses in `vendor/audio/`. No Spotify app binaries, album art, custom Spotify-logo icon,
certificates, provisioning profiles or personal logs are included in this source candidate.
