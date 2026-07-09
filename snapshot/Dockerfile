###############################
# Build the FFmpeg-build image, tracking upstream master.
FROM alpine:3.24 AS build

ARG FFMPEG_VERSION=ffmpeg-snapshot.tar.bz2
ARG PREFIX=/opt/ffmpeg
ARG MAKEFLAGS="-j4"

# No checksum pin here: ffmpeg-snapshot.tar.bz2 is a moving target by design.
# Build deps. fdk-aac and aom both live in community, which the official alpine
# image already enables -- no edge/testing repo, and no hand-built libaom.
RUN apk add --no-cache \
  build-base \
  pkgconf \
  nasm \
  wget \
  aom-dev \
  freetype-dev \
  harfbuzz-dev \
  openssl-dev \
  lame-dev \
  libogg-dev \
  libass-dev \
  libvpx-dev \
  libvorbis-dev \
  libwebp-dev \
  libtheora-dev \
  opus-dev \
  rtmpdump-dev \
  x264-dev \
  x265-dev \
  fdk-aac-dev

WORKDIR /tmp

# Get ffmpeg source.
RUN wget https://ffmpeg.org/releases/${FFMPEG_VERSION} && \
    tar xjf ${FFMPEG_VERSION} && rm ${FFMPEG_VERSION}

WORKDIR /tmp/ffmpeg

# Compile ffmpeg. libpostproc was removed upstream in 8.x, so there is no
# --enable-postproc. libharfbuzz is required for the drawtext filter.
RUN ./configure \
    --prefix="${PREFIX}" \
    --enable-version3 \
    --enable-gpl \
    --enable-nonfree \
    --enable-small \
    --enable-libaom \
    --enable-libmp3lame \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libvpx \
    --enable-libtheora \
    --enable-libvorbis \
    --enable-libopus \
    --enable-libfdk-aac \
    --enable-libass \
    --enable-libwebp \
    --enable-librtmp \
    --enable-libfreetype \
    --enable-libharfbuzz \
    --enable-openssl \
    --disable-debug \
    --disable-doc \
    --disable-ffplay && \
  make ${MAKEFLAGS} && make install && make distclean

# Cleanup.
RUN rm -rf /var/cache/apk/* /tmp/*

##########################
# Build the release image.
FROM alpine:3.24

ENV PATH="/opt/ffmpeg/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/ffmpeg/lib"

# libxcb is not optional: configure auto-detects it and enables the x11grab
# input device, so the binary links against it and will not start without it.
RUN apk --no-cache add \
  ca-certificates \
  openssl \
  rtmpdump \
  aom-libs \
  freetype \
  harfbuzz \
  libass \
  libvpx \
  libvorbis \
  libogg \
  libwebp \
  libwebpmux \
  libtheora \
  opus \
  x264-libs \
  x265-libs \
  fdk-aac \
  lame-libs \
  libxcb \
  numactl

COPY --from=build /opt/ffmpeg /opt/ffmpeg
CMD ["ffmpeg","-version"]
