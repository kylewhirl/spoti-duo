#!/bin/sh
# The strict pass target is a Duo simulator. Phone diagnostics retain known pre-edit failures.
set -eu
DEVICE=${1:?Usage: run.sh DUO_SIMULATOR_UDID}
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
DATA=$(xcrun simctl list devices -j | python3 -c 'import json,sys; print(next(d["dataPath"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["udid"] == sys.argv[1]))' "$DEVICE")
NAME="entity-menu-$$.log"
xcrun simctl install "$DEVICE" "$HERE/build/EntityMenuHarness.app"
xcrun simctl launch --terminate-running-process --stderr="/tmp/$NAME" "$DEVICE" com.vojta.entitymenuharness
count=0
until grep -q 'ENTITY MENU CHECKS:' "$DATA/tmp/$NAME" 2>/dev/null; do
    count=$((count + 1))
    if [ "$count" -ge 30 ]; then echo 'Timed out waiting for entity menu checks' >&2; exit 1; fi
    sleep 1
done
cp "$DATA/tmp/$NAME" "$HERE/build/last-run.log"
grep 'ENTITY MENU CHECKS:' "$HERE/build/last-run.log"
grep -q 'ENTITY MENU CHECKS:.* -- PASS' "$HERE/build/last-run.log"
