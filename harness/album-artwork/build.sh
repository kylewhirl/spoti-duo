#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
SRC=$(CDPATH= cd -- "$HERE/../../tweak/Sources" && pwd)
THEOS=${THEOS:-$HOME/theos}
HEADER_SRC=${HEADER_SRC:-$SRC/Redesigned/Album/AlbumHeader.x}
OUT=${OUT:-$HERE/build}
mkdir -p "$OUT/gen" "$OUT/AlbumArtworkHarness.app"
"$THEOS/bin/logos.pl" -c generator=internal "$HEADER_SRC" > "$OUT/gen/AlbumHeader.m"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun -sdk iphonesimulator clang -target arm64-apple-ios17.0-simulator -fobjc-arc -g -O0 \
 -I"$SRC" -I"$SRC/Redesigned/Album" -I"$OUT/gen" -isysroot "$SDK" -Wno-deprecated-declarations \
 "$HERE/main.m" "$HERE/../album/stubs.m" \
 "$SRC"/Core/SGLog.m "$SRC"/Core/SGPrefs.m "$SRC"/Core/SGViewTree.m "$SRC"/Core/SGGlass.m \
 "$SRC"/Core/SGBackdrop.m "$SRC"/Core/SGFlagForce.m "$SRC"/Core/SGUIMode.m "$SRC"/Core/SGAppearance.m \
 "$SRC"/Redesigned/Kit/SGRTokens.m "$SRC"/Redesigned/Kit/SGRPalette.m "$SRC"/Redesigned/Kit/SGRField.m "$SRC"/Redesigned/Kit/SGRFlow.m \
 "$SRC"/Redesigned/Kit/SGRGlass.m "$SRC"/Redesigned/Kit/SGRGlyph.m "$SRC"/Redesigned/Kit/SGRRestyle.m \
 "$SRC"/Redesigned/Kit/SGRActionRow.m "$SRC"/Redesigned/Kit/SGRDownload.m "$SRC"/Redesigned/Kit/SGRHeaderInfo.m \
 "$SRC"/Redesigned/Kit/SGRedesign.m \
 -framework UIKit -framework QuartzCore -framework CoreGraphics -framework CoreImage -framework Foundation -framework Symbols \
 -o "$OUT/AlbumArtworkHarness.app/AlbumArtworkHarness"
cat > "$OUT/AlbumArtworkHarness.app/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>AlbumArtworkHarness</string>
<key>CFBundleIdentifier</key><string>com.vojta.albumartworkharness</string>
<key>CFBundleName</key><string>AlbumArtworkHarness</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>UIUserInterfaceStyle</key><string>Dark</string>
<key>UILaunchScreen</key><dict/>
<key>UIApplicationSceneManifest</key><dict><key>UIApplicationSupportsMultipleScenes</key><false/></dict>
</dict></plist>
PLIST
printf 'Built %s\n' "$OUT/AlbumArtworkHarness.app"
