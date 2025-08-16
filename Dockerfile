###############################
# Build FFmpeg from source
FROM alpine:3.22 AS build

ARG FFMPEG_VERSION=7.1.1
ARG PREFIX=/opt/ffmpeg
ARG MAKEFLAGS="-j4"

# enable community (for fdk-aac)
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.22/main"      >  /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.22/community" >> /etc/apk/repositories

# Build deps
RUN apk add --no-cache \
  build-base \
  pkgconf \
  nasm \
  wget \
  freetype-dev \
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

# Fetch source (HTTPS)
RUN wget https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
    tar zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && rm ffmpeg-${FFMPEG_VERSION}.tar.gz

WORKDIR /tmp/ffmpeg-${FFMPEG_VERSION}

# Configure + build
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
    --enable-postproc \
    --enable-libfreetype \
    --enable-openssl \
    --disable-debug \
    --disable-doc \
    --disable-ffplay && \
  make ${MAKEFLAGS} && make install && make distclean

# Cleanup
RUN rm -rf /var/cache/apk/* /tmp/*

##########################
# Runtime image
FROM alpine:3.22

# enable community (for x264/x265 libs, fdk-aac runtime)
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.22/main"      >  /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.22/community" >> /etc/apk/repositories

ENV PATH="/opt/ffmpeg/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/ffmpeg/lib"

RUN apk --no-cache add \
  ca-certificates \
  openssl \
  rtmpdump \
  # codecs/filters you enabled at build time:
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
