###############################
# Build FFmpeg from source
FROM alpine:3.24 AS build

ARG FFMPEG_VERSION=8.1.2
# GPG-verified against FFmpeg's published release signing key
# FCF986EA15E6E293A5644F10B4322F04D67658D8 (see ffmpeg.org/download.html).
# Bump this whenever FFMPEG_VERSION changes.
ARG FFMPEG_SHA256=32faba5ef67340d54724941eae1425580791195312a4fd13bf6f820a2818bf22
ARG PREFIX=/opt/ffmpeg
ARG MAKEFLAGS="-j4"

# Build deps. The official alpine image already enables main + community,
# so there is no repository file to rewrite.
RUN apk add --no-cache \
  build-base \
  pkgconf \
  nasm \
  wget \
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

RUN wget https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
    echo "${FFMPEG_SHA256}  ffmpeg-${FFMPEG_VERSION}.tar.gz" | sha256sum -c - && \
    tar zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && rm ffmpeg-${FFMPEG_VERSION}.tar.gz

WORKDIR /tmp/ffmpeg-${FFMPEG_VERSION}

# libharfbuzz is required for the drawtext filter, on top of libfreetype.
RUN ./configure \
    --prefix="${PREFIX}" \
    --enable-version3 \
    --enable-gpl \
    --enable-nonfree \
    --enable-small \
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

# Cleanup
RUN rm -rf /var/cache/apk/* /tmp/*

##########################
# Runtime image
FROM alpine:3.24

ENV PATH="/opt/ffmpeg/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/ffmpeg/lib"

# libxcb is not optional: configure auto-detects it and enables the x11grab
# input device, so the binary links against it and will not start without it.
RUN apk --no-cache add \
  ca-certificates \
  openssl \
  rtmpdump \
  # codecs/filters you enabled at build time:
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
