# Album and artist header centering

Build `harness/album/build.sh` and `harness/artist/build.sh` with THEOS set, then run
`harness/entity-header/run-centering.sh SIMULATOR_UDID`. These harnesses compile the real
AlbumHeader/ArtistHeader hooks and shared Kit views; scene delegates permit iOS 27 launch.

Each entity runs 36 geometry cases, one initial wrapping-title/hero check, and 14,408
continuous-scroll samples. Album adds 12 metadata lifecycle checks (14,457 total),
while artist runs 14,445 checks. Geometry covers
four synthetic window widths (Duo 466/669/951/466, phone 320/402/466/320), three host arrangements
(full width, translated 13pt, already inset), and three vertical states. Four repeated production
layout passes precede each check. Expected content is independently derived from the page's UIKit
safe-area layout guide, intersected with the host; ordinary phones retain full host width.
Assertions cover info bounds, title/meta and Play centers, all three controls fitting the column,
and the full-bleed hero ending 56pt below the laid-out title top. The Duo fixture title wraps at
the content width but not full header width, catching incorrect hero text-height measurement.
The continuous sweep drives the hierarchy's actual UIScrollView contentOffset from 0 to 900pt
and back in 1pt steps at each of the four widths. It runs both a fixed-height header and a
header shrinking continuously from 568 to 80pt, fades its alpha to zero, and periodically
allows the run loop to deliver deferred UIKit updates. It checks that title width/wrapping
and local position remain stable except for the prescribed collapse, hero height stays fixed,
and the production hooks do not change scroll offset, content size, or content inset.
These assertions distinguish visual text/hero jumps from scroll-position changes. For album,
the collection supplying metadata cells is detached at 200pt and reattached on the return
sweep, modeling unavailable rendered cells without changing the underlying data source.
The focused metadata cases run the production hooks before/after this transition and check
title Y, measured content height, and hero height. Before the focused disappearance check,
the host settles 40pt taller with metadata present, ensuring an earlier loading-time hero
maximum cannot conceal subsequent growth. Lifecycle cases run after the geometry matrix
because intentional identity changes legitimately alter its monotonic hero cache.
They also cover refreshed metadata,
header reuse with a new title/creator, transient empty identity reads, a late creator, and
replacement source rows that initially have no cells. A nonempty replacement value must
appear; stale values must not carry into confirmed reuse.

Album/artist have no descriptions; playlist's existing `other` variant covers description layout.

These are mock Spotify hierarchies and synthetic window resizes, not live Spotify, physical fold
transitions, or a test of Spotify's native navigation title. Passing these cases does not
prove every behavior of Spotify's live collapsing-header implementation. The metadata
fixture reproduces a 20pt title-down jump in the pre-fix hooks and verifies its removal;
it does not assert that Spotify's native collection content size grew on a physical device. Continue to run the playlist's existing
`run-centering.sh` on Duo and phone to guard its previously verified alignment.

## Verification limits

The continuous offset/fade sweep prescribes the mock header height and uses a fixed
synthetic scroll content size. It does not reproduce Spotify's native header-collapse
subscriptions, coordinated scroll views, or root-relative adapter sizing. Passing it
does not prove the reported physical artwork/title snap is resolved. The metadata
fixture validates a separate unavailable-cell artifact; the corresponding fix did
not resolve the user's report. See harness/album-artwork for the native-constraint
stretch regression and its explicitly documented assumptions.
