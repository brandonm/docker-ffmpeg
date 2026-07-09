# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Two multi-stage Dockerfiles that compile FFmpeg from source on Alpine and ship a slim runtime image.

- `Dockerfile` — pinned FFmpeg release (`ARG FFMPEG_VERSION`). Published as `brandmar/ffmpeg:latest`.
- `snapshot/Dockerfile` — tracks FFmpeg **master** via `ffmpeg-snapshot.tar.bz2`, and additionally builds AV1
  (`--enable-libaom`). Published as `brandmar/ffmpeg:snapshot`.

Both use the same shape: a `build` stage that compiles into `/opt/ffmpeg`, then a fresh Alpine runtime stage
that `COPY --from=build /opt/ffmpeg /opt/ffmpeg` and re-installs only the *runtime* shared libraries. There is
no test suite and nothing to lint — verification means building the image and running the binary.

## Commands

```sh
docker build -t ffmpeg .                        # main image
docker build -f snapshot/Dockerfile snapshot/   # snapshot image (context is snapshot/)
docker compose up --build                       # mounts ./tmp -> /opt/tmp for scratch files
```

CI builds on `ubuntu-latest`, i.e. **amd64**. On Apple Silicon, add `--platform linux/amd64` to reproduce what
CI does.

Verify a build the way CI cannot — `docker build` exiting 0 says nothing about whether the image *runs*:

```sh
docker run --rm ffmpeg ffmpeg -buildconf
docker run --rm ffmpeg sh -c 'ldd /opt/ffmpeg/bin/ffmpeg | grep "not found"'   # must print nothing
docker run --rm ffmpeg sh -c 'ffmpeg -f lavfi -i testsrc -t 1 -c:v libx264 -f mp4 /tmp/o.mp4 -y'
```

To check whether an encoder exists, grep `ffmpeg -encoders`. Do **not** use `ffmpeg -h encoder=NAME` — it exits
0 even for a codec that does not exist.

## Build constraints that will bite you

**`--enable-postproc` is gone.** `libpostproc` was removed upstream in FFmpeg 8.x, and `configure` *hard-fails*
on unknown options rather than ignoring them. Passing it aborts the build. Dropping it loses only the `pp`
filter; `spp`/`fspp`/`uspp` survive as native filters. This is what silently broke `snapshot/` for ~11 months,
since it tracks master.

**`libxcb` must stay in the runtime stage.** `configure` auto-detects libxcb (pulled in transitively by a
`-dev` package) and enables the `x11grab` input device, so the binary links against it. Without `libxcb` at
runtime, `ffmpeg -version` itself dies on musl with `Error loading shared library libxcb.so.1`.
`--disable-ffplay` does *not* disable X11. To actually remove it, pass `--disable-libxcb`.

**`drawtext` needs harfbuzz, not just freetype.** `drawtext_filter_deps="libfreetype libharfbuzz"` and
`--enable-libharfbuzz` defaults to off, so `--enable-libfreetype` alone yields no `drawtext` filter. Both flags
are now set. The image ships no fonts, so `drawtext` requires `fontfile=`; `font=Name` lookup would additionally
need `--enable-libfontconfig`.

**Bump `FFMPEG_SHA256` whenever you bump `FFMPEG_VERSION`.** The main Dockerfile gates the download on a pinned
sha256. FFmpeg publishes no `.sha256` — only a `.asc` GPG signature — so the pinned hash was verified once
against release signing key `FCF986EA15E6E293A5644F10B4322F04D67658D8` (see ffmpeg.org/download.html) and then
pinned. `snapshot/` cannot pin a hash; its tarball is a moving target.

**Do not re-add an `/etc/apk/repositories` rewrite.** Alpine's official image already enables `main` +
`community` (which is where `fdk-aac` and `aom` live). A hardcoded `v3.XX` in that file silently drifts from the
`FROM alpine:3.XX` tag when only one is bumped. Never mix `edge/testing` into a stable release.

Prefer Alpine packages over hand-building dependencies — `snapshot/` used to `git clone` libaom at an unpinned
HEAD and `cmake` it; `aom-dev` from community replaced that entirely.

## Licensing (important, and deliberate)

The image is **not legally redistributable**, and this is a known, accepted state.

`--enable-gpl` + `--enable-libfdk-aac` forces `--enable-nonfree`, because `libfdk_aac` is one of three entries in
FFmpeg's `EXTERNAL_LIBRARY_NONFREE_LIST`. `configure` then sets `license="nonfree and unredistributable"`, and
`ffmpeg -L` says so out loud. CI nevertheless publishes the image.

`LICENSE` (MIT, © 2016 Alfred Gutierrez) covers **the Dockerfile only** — not the compiled binaries, whose terms
come from x264/x265 (GPL) and Fraunhofer FDK AAC.

`--enable-openssl` is *not* the blocker (OpenSSL 3.x is Apache-2.0, compatible with the GPLv3 that
`--enable-version3` selects). Only `libfdk_aac` triggers it. Dropping `--enable-nonfree` and
`--enable-libfdk-aac` yields a redistributable "GPL version 3 or later" build with the native `aac` encoder
intact — verified. Do not make that change unprompted; it removes `-c:a libfdk_aac`.

## CI

`.github/workflows/docker-image.yml` publishes both images to Docker Hub on push to `main` (or manual
`workflow_dispatch`). `.github/workflows/docker-build.yml` pushes to GHCR. Both trigger on **`main`** — the
default branch was renamed from `master`. Actions are pinned by commit SHA with a version comment; keep it that
way. Images are amd64-only on purpose: building FFmpeg for arm64 under emulation would add substantial CI time.

The two jobs in `docker-image.yml` are independent, so a broken `snapshot/` build does not block `latest` — a
red X there can go unnoticed for a long time. Check both.
