# Source provenance and release boundary

This source tree starts from upstream `skopevoj/spoti.pw` commit
`a6b187684356c83dad10cda2213f933886d6cc69`, whose LICENSE is GPL version 3.
Both its root LICENSE and README identify GPL. The next commit, `c790445`, adds a
contradictory PolyForm license screen while the root LICENSE remains GPL; that entire
three-file addition is excluded here. The later `f44abdf` changes the root LICENSE.
The original GPL LICENSE is retained verbatim. The original author is Vojtěch Škopek;
the Duo adaptations were developed for Kyle Worrall in November 2026.

The development checkout used a newer upstream base, `425d68b`. This export is **not** that
checkout with a changed license. It is an independent export of the GPL baseline with reviewed
local source deltas applied. Ninety locally modified tracked paths did not overlap later upstream
changes. Two source overlaps were reconciled onto their GPL versions:

- `SGPageStyle.m`: local appearance changes, without later upstream Discord additions.
- `PlayerSettings.m`: local Favorite control on the GPL version's artwork flag settings,
  without the later animated-artwork source provider.

Documentation overlaps were rewritten or applied manually to GPL documentation. New local
Duo source and test files were copied selectively; generated binaries, diagnostics output and
private native resources were not copied into the release inventory.

## Intentionally omitted

- Post-license `Shared/LockScreenArtwork/*` and `harness/lockart/*` (Canvas/Apple Music
  animated lock-screen artwork integration).
- Post-license `Settings/SGOrderPage.*` and newer upstream lyrics-ordering changes.
- The transitional `c790445` license screen and its two call/declaration additions.
- Post-license CLA, onboarding/about/donation/update and release metadata changes.
- All CI workflows, bundled AutoFLEX debugger, unrelated agent skill collections, screenshots,
  branded icon assets, signing inputs, generated flag lists and app binaries.

The baseline lyrics-source UI and baseline lock-screen artwork flags remain. Full animated
lock-screen artwork from newer upstream releases is not advertised or included.

This is a code-provenance audit, not legal advice or a guarantee about every third-party right.
The release owner should review the notices and any external tooling/input they choose to use.

## Dependency notices

`vendor/audio/README.md` pins libbs2b and WDL source revisions. Their MIT and zlib notices remain.
The baseline custom EEL2 parser is part of the GPL project. Theos, cyan and Apple SDKs are
external build dependencies, not copied into this source distribution.

## Duo update boundary

The GPL baseline updater was replaced with an inert implementation. It sends no requests,
does not use cached upstream release results, and does not send a usage payload. The Updates
page explicitly says no Duo release feed is configured; it does not offer a nonfunctional toggle.
An optional, default-off update setting can be added once a real Duo-owned release feed exists.
The upstream usage-reporting implementation is disabled entirely, including for existing installs
whose old settings enabled it. It creates no install identifier and returns no usage body.

Upstream website/source/signing links are labeled as upstream attribution/help. The fork does
not direct bug reports to the original maintainer or show upstream donation prompts.
