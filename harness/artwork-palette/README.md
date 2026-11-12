# Artwork palette UIKit fixture

Build from the repository root:

```sh
THEOS="$HOME/theos" sh harness/artwork-palette/build.sh
sh harness/artwork-palette/run.sh YOUR_BOOTED_SIMULATOR_UDID
```

The runner requires an explicit Simulator ID and does not operate a physical device. It checks
production appearance/accent/theme code with synthetic player state and native semantic providers.
It exercises same-theme hue changes, fixed modes, system mode and independent artwork choices.
This does not verify the complete Spotify app or playback. Logs/renders stay in ignored build/.
