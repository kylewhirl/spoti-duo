#!/bin/sh
# Simulator only. Uses the explicitly supplied UDID, never a physical device or default target.
set -eu
DEVICE=${1:?Usage: run.sh SIMULATOR_UDID}
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
OUT=${OUT:-$HERE/build}
DATA=$(xcrun simctl list devices -j | python3 -c 'import json,sys; print(next(d["dataPath"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["udid"]==sys.argv[1]))' "$DEVICE")
xcrun simctl install "$DEVICE" "$OUT/AppearanceHarness.app"
trap 'xcrun simctl terminate "$DEVICE" com.vojta.appearanceharness >/dev/null 2>&1 || true' EXIT
for MODE in 0 1; do
 NAME="artwork-palette-$MODE-$$.log"
 SIMCTL_CHILD_SG_TEST_APPEARANCE="$MODE" xcrun simctl launch --terminate-running-process --stderr="/tmp/$NAME" "$DEVICE" com.vojta.appearanceharness
 COUNT=0
 until grep -q 'ARTWORK SUITE COMPLETE:' "$DATA/tmp/$NAME" 2>/dev/null; do
  COUNT=$((COUNT+1)); [ "$COUNT" -lt 60 ] || { cat "$DATA/tmp/$NAME"; exit 1; }; sleep 1
 done
 cp "$DATA/tmp/$NAME" "$OUT/mode-$MODE.log"
 xcrun simctl terminate "$DEVICE" com.vojta.appearanceharness
 grep -E 'ARTWORK SUITE COMPLETE:' "$OUT/mode-$MODE.log"
 grep -q 'ARTWORK SUITE COMPLETE:.* -- PASS' "$OUT/mode-$MODE.log"
done
CONTAINER=$(xcrun simctl get_app_container "$DEVICE" com.vojta.appearanceharness data)
find "$CONTAINER/Documents" -name "*.png" -maxdepth 1 -exec cp {} "$OUT/" \;
