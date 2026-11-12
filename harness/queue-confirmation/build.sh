#!/bin/sh
set -eu
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
SOURCE=$(CDPATH= cd -- "$HERE/../../tweak/Sources" && pwd)
OUT="$HERE/build"
APP="$OUT/QueueConfirmationFixture.app"
mkdir -p "$OUT/gen" "$APP/Frameworks"
# Supply your own local authorized framework/resource inputs; no binaries are distributed.
: "${SPOTIFY_SIM_FRAMEWORKS:?set to your simulator Frameworks directory}"
: "${SPOTIFY_STRINGS_BUNDLE:?set to your SPTStrings.bundle}"
: "${THEOS:=$HOME/theos}"
ditto "$SPOTIFY_SIM_FRAMEWORKS" "$APP/Frameworks"
ditto "$SPOTIFY_STRINGS_BUNDLE" "$APP/SPTStrings.bundle"
"$THEOS/bin/logos.pl" -c generator=internal "$SOURCE/Redesigned/Queue/SGRQueueConfirmation.x" > "$OUT/gen/SGRQueueConfirmation.m"
SDK=$(env -u SDKROOT xcrun --sdk iphonesimulator --show-sdk-path)
env -u SDKROOT xcrun --sdk iphonesimulator clang -target arm64-apple-ios17.0-simulator -fobjc-arc -g -O0 -isysroot "$SDK" -I"$SOURCE" -I"$SOURCE/Redesigned/Queue" -Wno-deprecated-declarations \
 "$HERE/main.m" "$OUT/gen/SGRQueueConfirmation.m" "$SOURCE/Redesigned/Queue/SGRQueueConfirmation.m" \
 "$SOURCE/Core/SGAppearance.m" "$SOURCE/Core/SGGlass.m" "$SOURCE/Redesigned/Kit/SGRTokens.m" "$SOURCE/Redesigned/Kit/SGRGlass.m" \
 -F"$APP/Frameworks" -framework SpotifyShared -framework UIKit -framework Foundation -framework QuartzCore -framework CoreGraphics -Wl,-rpath,@executable_path/Frameworks -o "$APP/QueueConfirmationFixture"
cat > "$APP/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>QueueConfirmationFixture</string><key>CFBundleIdentifier</key><string>com.kyle.queueconfirmationfixture</string><key>CFBundleVersion</key><string>1</string><key>CFBundleName</key><string>Queue fixture</string><key>CFBundleShortVersionString</key><string>1.0</string><key>UILaunchScreen</key><dict/><key>UIApplicationSceneManifest</key><dict><key>UIApplicationSupportsMultipleScenes</key><false/></dict></dict></plist>
PLIST
codesign --force --sign - "$APP"
