###############################
# Build the FFmpeg-build image.
#FROM alpine:edge as build
FROM alpine:3.19 AS build

ARG FFMPEG_VERSION=ffmpeg-snapshot.tar.bz2
ARG AOM_VERSION=master

ARG PREFIX=/opt/ffmpeg
ARG PKG_CONFIG_PATH=/opt/ffmpeg/lib64/pkgconfig
ARG LD_LIBRARY_PATH=/opt/ffmpeg/lib
ARG MAKEFLAGS="-j4"

# FFmpeg build dependencies.
RUN apk --no-cache add \
  build-base \
  cmake \
  coreutils \
  openssl-dev \
  freetype-dev \
  lame-dev \
  libogg-dev \
  libass \
  libass-dev \
  libvpx-dev \
  libvorbis-dev \
  libwebp-dev \
  libtheora-dev \
  libtool \
  opus-dev \
  perl \
  pkgconf \
  pkgconfig \
  python3 \
  rtmpdump-dev \
  wget \
  x264-dev \
  x265-dev \
  yasm

# Install fdk-aac from testing.
RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
  apk add --no-cache fdk-aac-dev

RUN mkdir -p /tmp/aom
WORKDIR /tmp

# Build libaom for av1.
RUN wget https://aomedia.googlesource.com/aom/+archive/${AOM_VERSION}.tar.gz && \
    tar zxf ${AOM_VERSION}.tar.gz && rm ${AOM_VERSION}.tar.gz && \
    rm -rf CMakeCache.txt CMakeFiles && \
    mkdir -p ./aom_build && \
    cd ./aom_build && \
    cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" -DBUILD_SHARED_LIBS=1 .. && \
    make && \
    make install && \
    make clean

WORKDIR /tmp

# Get ffmpeg source.
RUN wget https://ffmpeg.org/releases/${FFMPEG_VERSION}
RUN tar xjvf ${FFMPEG_VERSION} && rm ${FFMPEG_VERSION}

WORKDIR /tmp/ffmpeg

# Compile ffmpeg.
RUN ./configure \
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
  --enable-postproc \
  --enable-libfreetype \
  --enable-openssl \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --extra-cflags="-I${PREFIX}/include" \
  --extra-ldflags="-L${PREFIX}/lib" \
  --extra-libs="-lpthread -lm" \
  --prefix="${PREFIX}" && \
    make && \
    make install && \
    make distclean

# Cleanup.
RUN rm -rf /var/cache/apk/* /tmp/*

##########################
# Build the release image.
FROM alpine:3.19

ENV PATH=/opt/ffmpeg/bin:$PATH

RUN apk --no-cache add \
  ca-certificates \
  openssl \
  pcre \
  lame \
  libogg \
  libass \
  libvpx \
  libvorbis \
  libwebp \
  libtheora \
  opus \
  rtmpdump \
  x264-dev \
  x265-dev

COPY --from=build /opt/ffmpeg /opt/ffmpeg
COPY --from=build /opt/ffmpeg/lib64/libaom.so* /usr/lib/
COPY --from=build /usr/lib/libfdk-aac.so.2 /usr/lib/libfdk-aac.so.2

CMD ["/opt/ffmpeg/bin/ffmpeg"]
