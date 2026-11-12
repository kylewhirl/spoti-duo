# Album footer fitting regression

Run `sh harness/album-footer/build.sh` with THEOS set if needed, then
`sh harness/album-footer/run.sh SIMULATOR_UDID` on a dedicated QA simulator.

This compiles the unchanged production `AlbumSections.x` selected by the build. The mock
Element_List cell directly subclasses UICollectionViewCell and does not override fitting:
UIKit supplies the hook's original method. Unhooked UICollectionViewCell controls use the
same content. Page lookup/color/gating have minimal stubs; sizing is not stubbed.

540 assertions cover frame-based and fully constrained multiline-label content, repeated
preferred fitting, width/text changes, retained footer styling, dropped sections, and
reuse from dropped to kept/nonfooter content with and without prepareForReuse. Recovery cases leave both cells at zero height while passing nonzero
incoming attributes, and compare nondefault autoresizing, clipping, visibility and
accessibility states against the native control. An optional original prepareForReuse
fixture deliberately resets those flags; cleanup must occur before that method so its
new state wins. That reset fixture is explicit test behavior, not a claim about Spotify's
current reuse defaults. Returned
attributes are applied and copied into the next fitting pass. Heights are not reset to a
fixed baseline between passes. Width/text changes are explicit fixture inputs.

Kept rows must match native controls exactly, including content frames. Dropped rows must
remain zero-height and concealed. The correction intentionally removes the custom 16pt
gaps above the summary/copyright; retained footer height and placement belong to UIKit.

Compare an exact source baseline using `SECTIONS_SRC=/path/to/AlbumSections.before.x
OUT=/tmp/footer-baseline sh harness/album-footer/build.sh`, then run with the same OUT.
The old +16pt-per-fit implementation fails: its frame-based kept rows grow each pass;
its constrained rows stay stable but include non-native padding. Native passthrough works
for both paths and permits intrinsic height changes when text/width changes.

This drives UIKit's real fitting method, but not Spotify's content models or a complete
UICollectionView invalidation cycle. It establishes footer-hook behavior, not the cause
of a live album artwork/title snap. The exact native footer constraints remain unknown.
