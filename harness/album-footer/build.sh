#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/../.." && pwd)
SRC="$ROOT/tweak/Sources"
THEOS=${THEOS:-$HOME/theos}
SECTIONS_SRC=${SECTIONS_SRC:-$SRC/Redesigned/Album/AlbumSections.x}
OUT=${OUT:-$HERE/build}
mkdir -p "$OUT/FooterSizing.app"
"$THEOS/bin/logos.pl" -c generator=internal "$SECTIONS_SRC" > "$OUT/AlbumSections.m"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun -sdk iphonesimulator clang -target arm64-apple-ios17.0-simulator -fobjc-arc -g -O0 \
 -I"$SRC" -I"$SRC/Redesigned/Album" -isysroot "$SDK" \
 "$HERE/main.m" "$OUT/AlbumSections.m" "$SRC/Core/SGViewTree.m" \
 -framework UIKit -framework QuartzCore -framework CoreGraphics -framework Foundation \
 -o "$OUT/FooterSizing.app/FooterSizing"
cat > "$OUT/FooterSizing.app/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>FooterSizing</string>
<key>CFBundleIdentifier</key><string>com.vojta.footersizing</string>
<key>CFBundleName</key><string>FooterSizing</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>UIUserInterfaceStyle</key><string>Dark</string>
<key>UILaunchScreen</key><dict/>
<key>UIApplicationSceneManifest</key><dict><key>UIApplicationSupportsMultipleScenes</key><false/></dict>
</dict></plist>
PLIST
