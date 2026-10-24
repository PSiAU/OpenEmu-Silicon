# MAME Core for OpenEmu-Silicon

This directory contains the OpenEmu MAME core wrapper, based on OpenEmu/UME-Core, with the small changes needed to build natively on Apple Silicon against this fork.

Status: WIP. The core builds as arm64 and loads as `org.openemu.MAME`, but polygonal 3D arcade rendering still needs validation/debugging. Use Sega Virtua Racing as the main repro case from issue #500.

## Source dependency

The MAME headless source is intentionally not committed here because it is very large. Prepare it with:

```sh
./Scripts/prepare-mame-core.sh
```

That clones official `mamedev/mame` tag `mame0289` at commit `f34f02505e32c1993c6a782b6814232cbfc74e36` into `MAME/deps/mame` and applies `patches/mame-0289-headless.patch`. The patch ports the OpenEmu headless backend from `OpenEmu-Silicon/mame` commit `fac13e827b7b8cfa4ee4f5760198d31241e2a544`, including memory access and cheats.

MAME 0.289 already includes the V60 conversion fix previously backported for Sega Model 1. The old 0.250 compiler compatibility patch is no longer needed.

`arcade.flt` selects sources with `GAME`/`GAMEL` registrations from the 0.289 `mame.lst`, excluding non-arcade registrations in shared sources. Upstream no longer supplies this filter. The split Cave CV1000 blitter sources are included explicitly because the source scanner does not discover them through headers. Update the filter with each MAME upgrade.

The backend exposes a fixed 48 kHz stereo sink to MAME’s new audio routing interface; OpenEmu continues to handle playback and frame pacing.

## Build

To reproduce the full local build:

```sh
./Scripts/build-mame-core.sh
```

The script automatically mirrors the checkout to a temporary no-space path when the repository path contains whitespace, because MAME's project generator cannot reliably build from paths such as `Open Emu`.

The script does the following:

1. Prepares `MAME/deps/mame` if needed.
2. Builds `mamearcade_headless.dylib` as arm64 with the headless OSD.
3. Builds `OpenEmuBase.framework` into the same DerivedData path.
4. Builds `MAME.oecoreplugin`.

Product path:

```text
MAME/build/XcodeDerived/Build/Products/Release/MAME.oecoreplugin
```

## Manual build notes

```sh
cd MAME/deps/mame
make NOWERROR=1 REGENIE=1 macosx_arm64_clang \
  OSD="headless" verbose=1 TARGETOS="macosx" CONFIG="release" \
  TARGET=mame SUBTARGET=arcade SOURCEFILTER=../../arcade.flt MACOSX_DEPLOYMENT_TARGET=12.0 \
  -j"$(sysctl -n hw.ncpu)"
install_name_tool -id mamearcade_headless.dylib mamearcade_headless.dylib
```

Then build `OpenEmuBase` and the `MAME` project with the same `-derivedDataPath`.

## Local testing

Install the built plugin with the repo helper, which avoids stale bundle merges:

```sh
./Scripts/install-core.sh MAME --release
./Scripts/verify-core-installed.sh MAME --release
```

Use a MAME 0.289-compatible ROM set. Older ROM sets may need updating; save states from 0.250 are not guaranteed to load. Validate both:

- A known sprite-based arcade game, to confirm the core path works.
- Sega Virtua Racing, to investigate the missing polygon issue from #500.
