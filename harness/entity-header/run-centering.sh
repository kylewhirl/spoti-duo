#!/bin/sh
set -eu
DEVICE=${1:?Usage: run-centering.sh SIMULATOR_UDID}
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
mkdir -p "$HERE/build/$DEVICE"
for entity in album artist; do
 case $entity in album) app=AlbumHarness;; artist) app=ArtistHarness;; esac
 xcrun simctl install "$DEVICE" "$HERE/../$entity/build/$app.app"
 log="$HERE/build/$DEVICE/$entity.log"
 : > "$log"
 xcrun simctl launch --terminate-running-process --stderr="$log" "$DEVICE" "com.vojta.${entity}harness" centering
 count=0
 until grep -q 'entity centering checks:' "$log"; do
  count=$((count+1)); [ "$count" -lt 30 ] || { cat "$log"; exit 1; }; sleep 1
 done
 grep 'entity centering checks:' "$log"
 xcrun simctl terminate "$DEVICE" "com.vojta.${entity}harness"
 grep -q 'entity centering checks:.* -- PASS' "$log"
done
