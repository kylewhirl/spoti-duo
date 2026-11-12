# Pinned entity menu regression

Build with `sh harness/entity-menu/build.sh`, then run `harness/entity-menu/run.sh DUO_SIMULATOR_UDID`.
This compiles the production common Kit implementation and uses a real UINavigationController and
native Back, not a painted Back stand-in. Playlist, album and artist names exercise separate common
helper instances; their full Spotify header hooks are tested by their existing individual harnesses.

Checks cover page ownership, 44pt center/corner window hit routes, system rail placement below Back,
source forwarding once, recorder identity before source dispatch, repeated feeds, missing sources,
scroll, push/pop, sheet coverage/dismiss/reopen, container resizing without header callbacks, and
safe suppression/restoration where no unobstructed second slot fits. Actual hardware folding is not
simulated. The 130pt synthetic window deliberately provides no usable menu slot.

The transition fixture also uses the real navigation bar to obstruct the rail menu slot,
then removes the obstruction. Per-instance harness subclasses count button hidden/frame
setters and observer frame/layout requests across twelve repeated production feeds.
Steady visible, blocked, and restored states must perform zero redundant writes and zero
forced/requested observer layouts. Each visibility transition must write hidden exactly
once; removing/restoring the source cannot expose a blocked menu. Instrumentation stays
in the harness and does not swizzle UIKit globally or modify production classes.
These assertions detect transient show/hide churn that final-frame checks alone miss.
They do not prove anything about Spotify's native scrolling content-size calculation.

The phone diagnostic run intentionally reports the plain UINavigationController's existing top-corner
hit interception and stale positions when header callbacks are disabled. Compare against the exact
pre-edit SGRActionRow.m with `ACTION_ROW_SRC=/path/to/before/SGRActionRow.m OUT=/tmp/baseline sh
harness/entity-menu/build.sh`; do not claim these raw phone checks pass. On the tested iOS 26.5 phone,
all 11 phase geometries and all 43 failure signatures match the pre-edit baseline exactly. No phone
placement or refresh behavior was changed.

`harness/tabbar` additionally accepts `reservation` to exercise production tab composition with twelve
custom plus three built-in tabs. It checks every tab's scrolling/window hits at 470, 220, 164, 112, 80,
and restored 470pt rail heights, selection retention, default 152pt group geometry and offset recovery.
Below 112pt there is insufficient space for Back and a full nav row together; the extra menu yields
and the nav row remains accessible. No device model or width threshold selects the layout.
