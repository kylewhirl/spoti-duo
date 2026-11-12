#!/bin/sh
# Only the explicitly selected Simulator is used.
set -eu
DEVICE=${1:?Usage: run.sh SIMULATOR_UDID}
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
OUT=${OUT:-$HERE/build}
DATA=$(xcrun simctl list devices -j | python3 -c 'import json,sys; print(next(d["dataPath"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["udid"]==sys.argv[1]))' "$DEVICE")
BUNDLE=com.vojta.entitymenuharness
NAME=duo-rail-$$.log
xcrun simctl install "$DEVICE" "$OUT/EntityMenuHarness.app"
trap 'xcrun simctl terminate "$DEVICE" "$BUNDLE" >/dev/null 2>&1 || true' EXIT
xcrun simctl launch --terminate-running-process --stderr="/tmp/$NAME" "$DEVICE" "$BUNDLE"
COUNT=0
until grep -q 'ENTITY MENU CHECKS:' "$DATA/tmp/$NAME" 2>/dev/null; do
 COUNT=$((COUNT+1)); [ "$COUNT" -lt 60 ] || { cat "$DATA/tmp/$NAME"; exit 1; }; sleep 1
done
cp "$DATA/tmp/$NAME" "$OUT/result.log"
grep 'ENTITY MENU CHECKS:' "$OUT/result.log"
grep -q 'ENTITY MENU CHECKS:.* 0 failures -- PASS' "$OUT/result.log"
