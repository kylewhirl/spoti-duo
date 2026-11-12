# Album artwork reference-plane regression

This UIKit fixture compiles the production `AlbumHeader.x`, `SGRHeaderInfo`, image observer,
and other Kit implementations. It calls the production `applyPage` entry point and lets
Auto Layout solve the header rather than assigning its frame on each sample.

It tests a specific code defect, not the exact trigger of the user's live Spotify snap.
The latest-tested source also reproduced that live problem, so the previously explored
internal-column change was not its origin. This candidate is based on the latest-tested
centered info frame and `info.bounds.size.width` measurement. Metadata retention is unchanged.

## Model and evidence

Spotify 9.1.94's native `_TtC28CreativeWorkPlatform_PageKit19HeaderContainerView` creates:

- An adapter with height >= container height, leading/trailing/bottom equal to the container,
  and top <= the root's top.
- A header pinned to all four adapter edges with zero directional insets.
- A safe-area getter forwarding its root's insets. The fixture does not reconstruct that getter
  or the entire native element framework.

The adapter constraints are lower bounds, not a complete unique sizing solution. The fixture
explicitly supplies a header intrinsic content height with normal UIKit hugging/compression
priorities to model a preference for the native content's natural height. This preference is
an assumption, not a reverse-engineered implementation of Spotify's header measurement.
It gives a determinate solution, which the fixture verifies. The old and candidate code run
under exactly the same model.

Moving the root reference upward while keeping the container fixed forces a permitted adapter
stretch. The fixture also restores the reference, repeatedly. It never resets the header frame
per sample and never gives the candidate a replacement native size. Width/content changes update
the fixture's explicit native content preference and container constraints. A separate scroll
sweep moves only the scroll offset and corresponding root reference; these inputs are checked
for unexpected production writes.

## Candidate

Only artwork uses the converted native container plane. The hero remains full bleed, with the
existing dissolve, scrim, image mode, text-column measurement, and text/control geometry.
Its size is recomputed from that logical plane instead of storing the largest transient header.
The title already remains at the same world Y under the tested upward stretch; it is not moved.

The exact ancestor must occur before the current album page. Converted basis points must form
positive axis-aligned scale/translation, and the converted container must still match the
header's horizontal/bottom edges with no greater height (within one display pixel). Shared-
ancestor scaling is supported. Adapter-local scaling that breaks these pins, shifted container
bounds, unknown hierarchies, rotated/sheared/mirrored planes, and mismatched owners use the
legacy same-width maximum behavior. That fallback maximum is
invalidated by page/container/width changes or confirmed nonempty title/creator changes, not
simply because rendered metadata rows recycle. Known-container measurements have no historical
height cache. Short incomplete states hide the hero until it has valid dimensions.

The artwork observer also ignores callbacks from previously followed image views. A new empty
source clears the previous source's picture and can supply its image later without another
layout. A temporarily absent source keeps the current picture.

## Run

Run from the repository root on an existing simulator (never the physical device):

```sh
harness/album-artwork/build.sh
harness/album-artwork/run.sh SIMULATOR_UDID
```

Use an isolated build output and an exact saved older source for the before comparison:

```sh
HEADER_SRC="$PWD/out/compatibility/album-artwork/baseline-AlbumHeader.x" \
OUT="$PWD/out/compatibility/album-artwork/baseline" harness/album-artwork/build.sh
OUT="$PWD/out/compatibility/album-artwork/baseline" \
harness/album-artwork/run.sh SIMULATOR_UDID
```

The baseline run is intentionally expected to return nonzero. The scripts compile only the
isolated fixture, install its own simulator bundle, and terminate it after recording results.
They do not build, package, sign, or install Spotify, and do not contact a physical device.

## Results

Final 293-assertion suite:

- Latest-tested source `53348b286ae21b51ca19fc8ec294c3a5efdaa8b209a79a535e670c36bde7ff7f`:
  99 failures on the Duo QA simulator, including the intended stretch/crop regression.
- Candidate `65d11aad8879bf85cc971bc26b3d36addd9521306e79501aadc14c8eb594ef1a`:
  293 checks, zero failures on both Duo (iOS 27.1) and phone (iOS 26.5) QA simulators.

At the initial 466pt header width / 568pt logical height, both render the hero at world
`{17,100,466,450}` and title at `{37,494,361,53}` on Duo. With a 280pt adapter stretch,
old artwork moves to `{17,-180,466,730}`; after returning it remains `{17,100,466,730}`.
The candidate stays `{17,100,466,450}` throughout. The old 400x400 image's aspect-fill
visible source rectangle changes from approximately `{0,6.867,400,386.266}` to
`{72.329,0,255.342,400}`; the candidate keeps the first crop. Title world coordinates match
between old and candidate throughout this transition.

Coverage includes three stretch/return cycles, scroll translation and unchanged scroll inputs,
320/402/466/669/951pt width changes, real logical-height growth/shrink, title/metadata changes,
unavailable/recycled metadata, initial incomplete state and recovery, 100 repeated layouts,
nonzero header bounds, container/page replacement, legacy fallback invalidation, late artwork, old and
new image-owner callbacks, shared-ancestor scaling/translation, unsupported transforms or pin
misalignment, and wrong or
distant owning pages. Crop assertions compute the visible source rectangle from the real image
view's dimensions and `ScaleAspectFill` mode; they are not screenshot-based pixel comparisons.

Logs and source snapshots are under `out/compatibility/album-artwork/`. This evidence proves the
permitted adapter stretch no longer permanently changes artwork geometry/crop in the model.
It does not prove that Spotify uses that exact stretch at the user's title threshold, nor that
all live album self-sizing/navigation behavior is fixed. No candidate has been installed on the
user's phone as part of this work.
