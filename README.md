# docker-ffmpeg
An FFmpeg Dockerfile built from source. Built on Alpine Linux.

* ffmpeg 8.1.2 on Alpine 3.24 (compiled from source). See [FFmpeg Build](#ffmpeg-build) for build configuration.

[![Publish Docker image](https://github.com/brandonm/docker-ffmpeg/actions/workflows/docker-image.yml/badge.svg)](https://github.com/brandonm/docker-ffmpeg/actions/workflows/docker-image.yml)
[![Docker Stars](https://img.shields.io/docker/stars/brandmar/ffmpeg.svg)](https://hub.docker.com/r/brandmar/ffmpeg/)
[![Docker Pulls](https://img.shields.io/docker/pulls/brandmar/ffmpeg.svg)](https://hub.docker.com/r/brandmar/ffmpeg/)

Forked from [alfg/docker-ffmpeg](https://github.com/alfg/docker-ffmpeg).

## Usage

* Pull the Docker image and run:
```
docker pull brandmar/ffmpeg
docker run -it --rm brandmar/ffmpeg ffmpeg -buildconf
```

* or build and run the container from source:
```
docker build -t ffmpeg .
docker run -it --rm ffmpeg ffmpeg -buildconf
```

* or use as a base image in your Dockerfile:
```
FROM brandmar/ffmpeg:latest
```

* Example using a mounted volume:
```
docker run -v ${PWD}:/opt/tmp/ -it --rm brandmar/ffmpeg ffmpeg -i /opt/tmp/input.mp4 -c copy /opt/tmp/output.mp4
```

Images are published for `linux/amd64` only.

## FFmpeg Snapshot Builds
For building ffmpeg from snapshot, see [snapshot/Dockerfile](/snapshot/Dockerfile) for FFmpeg snapshot builds
including support for AV1 (libaom).

Or pull from the Docker tag:
```
docker pull brandmar/ffmpeg:snapshot
```

The snapshot tag tracks FFmpeg master and may be out of date. Build from
[snapshot/Dockerfile](/snapshot/Dockerfile) to get the latest build.

## Notes

* `libpostproc` was removed upstream in FFmpeg 8.x, so the `pp` filter is no longer available. The native
  `spp`, `fspp` and `uspp` filters are unaffected.
* The `drawtext` filter is enabled, but the image ships no fonts — pass `fontfile=/path/to/font.ttf`.
* The FFmpeg tarball is verified against a pinned `sha256` at build time. Bump `FFMPEG_SHA256` alongside
  `FFMPEG_VERSION`.

### FFmpeg Build
```
 # ffmpeg -buildconf
ffmpeg version 8.1.2 Copyright (c) 2000-2026 the FFmpeg developers
  built with gcc 15.2.0 (Alpine 15.2.0)
  configuration: --prefix=/opt/ffmpeg --enable-version3 --enable-gpl --enable-nonfree --enable-small --enable-libmp3lame --enable-libx264 --enable-libx265 --enable-libvpx --enable-libtheora --enable-libvorbis --enable-libopus --enable-libfdk-aac --enable-libass --enable-libwebp --enable-librtmp --enable-libfreetype --enable-libharfbuzz --enable-openssl --disable-debug --disable-doc --disable-ffplay
  libavutil      60. 26.102 / 60. 26.102
  libavcodec     62. 28.102 / 62. 28.102
  libavformat    62. 12.102 / 62. 12.102
  libavdevice    62.  3.102 / 62.  3.102
  libavfilter    11. 14.102 / 11. 14.102
  libswscale      9.  5.102 /  9.  5.102
  libswresample   6.  3.102 /  6.  3.102

  configuration:
    --prefix=/opt/ffmpeg
    --enable-version3
    --enable-gpl
    --enable-nonfree
    --enable-small
    --enable-libmp3lame
    --enable-libx264
    --enable-libx265
    --enable-libvpx
    --enable-libtheora
    --enable-libvorbis
    --enable-libopus
    --enable-libfdk-aac
    --enable-libass
    --enable-libwebp
    --enable-librtmp
    --enable-libfreetype
    --enable-libharfbuzz
    --enable-openssl
    --disable-debug
    --disable-doc
    --disable-ffplay
```

## Resources
* https://alpinelinux.org/
* https://www.ffmpeg.org

## License

The contents of this repository (the Dockerfiles and supporting files) are MIT licensed — see [LICENSE](/LICENSE).

**The MIT license does not extend to the built image.** The FFmpeg binary in these images is compiled with
`--enable-gpl` and `--enable-libfdk-aac`, which requires `--enable-nonfree`. FFmpeg therefore marks the result
as *"nonfree and unredistributable"*:

```
$ docker run --rm brandmar/ffmpeg ffmpeg -L
This version of ffmpeg has nonfree parts compiled in.
Therefore it is not legally redistributable.
```

If you need a redistributable build, remove `--enable-nonfree` and `--enable-libfdk-aac` from the Dockerfile
and use FFmpeg's native `aac` encoder (`-c:a aac`) instead of `-c:a libfdk_aac`. The resulting binary is
"GPL version 3 or later".
