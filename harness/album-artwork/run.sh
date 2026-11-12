#!/bin/sh
set -eu
DEVICE=${1:?Usage: run.sh SIMULATOR_UDID}
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
OUT=${OUT:-$HERE/build}
DATA=$(xcrun simctl list devices -j | python3 -c 'import json,sys; print(next(d["dataPath"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["udid"]==sys.argv[1]))' "$DEVICE")
NAME="album-artwork-$$.log"
xcrun simctl install "$DEVICE" "$OUT/AlbumArtworkHarness.app"
xcrun simctl launch --terminate-running-process --stderr="/tmp/$NAME" "$DEVICE" com.vojta.albumartworkharness
count=0
until grep -q 'ALBUM ARTWORK CHECKS:' "$DATA/tmp/$NAME" 2>/dev/null; do
 count=$((count+1)); [ "$count" -lt 30 ] || { echo 'Artwork fixture timed out' >&2; exit 1; }; sleep 1
done
cp "$DATA/tmp/$NAME" "$OUT/last-run.log"
xcrun simctl terminate "$DEVICE" com.vojta.albumartworkharness
grep 'ALBUM ARTWORK CHECKS:' "$OUT/last-run.log"
grep -q 'ALBUM ARTWORK CHECKS:.* -- PASS' "$OUT/last-run.log"
