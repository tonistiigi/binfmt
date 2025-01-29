# syntax=docker/dockerfile:1

ARG GO_VERSION=1.23
ARG ALPINE_VERSION=3.21
ARG XX_VERSION=1.6.1

ARG QEMU_VERSION=HEAD
ARG QEMU_REPO=https://github.com/qemu/qemu

# xx is a helper for cross-compilation
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS src
RUN apk add --no-cache git patch meson

WORKDIR /src
ARG QEMU_VERSION
ARG QEMU_REPO
RUN git clone $QEMU_REPO && cd qemu && git checkout $QEMU_VERSION
COPY patches patches
# QEMU_PATCHES defines additional patches to apply before compilation
ARG QEMU_PATCHES=cpu-max-arm
# QEMU_PATCHES_ALL defines all patches to apply before compilation
ARG QEMU_PATCHES_ALL=${QEMU_PATCHES},alpine-patches,meson
ARG QEMU_PRESERVE_ARGV0
RUN <<eof
  set -ex
  if [ "${QEMU_PATCHES_ALL#*alpine-patches}" != "${QEMU_PATCHES_ALL}" ]; then
    ver="$(cat qemu/VERSION)"
    for l in $(cat patches/aports.config); do
      pver=$(echo $l | cut -d, -f1)
      if [ "${ver%.*}" = "${pver%.*}" ]; then
        commit=$(echo $l | cut -d, -f2)
        rmlist=$(echo $l | cut -d, -f3)
        break
      fi
    done
    mkdir -p aports && cd aports && git init
    git fetch --depth 1 https://github.com/alpinelinux/aports.git "$commit"
    git checkout FETCH_HEAD
    mkdir -p ../patches/alpine-patches
    for f in $(echo $rmlist | tr ";" "\n"); do
      rm community/qemu/*${f}*.patch || true
    done
    cp -a community/qemu/*.patch ../patches/alpine-patches/
    cd - && rm -rf aports
  fi
  if [ -n "${QEMU_PRESERVE_ARGV0}" ]; then
    QEMU_PATCHES_ALL="${QEMU_PATCHES_ALL},preserve-argv0"
  fi
  cd qemu
  for p in $(echo $QEMU_PATCHES_ALL | tr ',' '\n'); do
    for f in  ../patches/$p/*.patch; do echo "apply $f"; patch -p1 < $f; done
  done
eof
RUN <<eof
  set -ex
  cd qemu
  # https://github.com/qemu/qemu/blob/ed734377ab3f3f3cc15d7aa301a87ab6370f2eed/scripts/make-release#L56-L57
  git submodule update --init --single-branch
  meson subprojects download keycodemapdb berkeley-testfloat-3 berkeley-softfloat-3 dtc slirp
eof

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS base
RUN apk add --no-cache git clang lld python3 llvm make ninja pkgconfig glib-dev gcc musl-dev perl bash
COPY --from=xx / /
ENV PATH=/qemu/install-scripts:$PATH
WORKDIR /qemu

ARG TARGETPLATFORM
RUN xx-apk add --no-cache musl-dev gcc glib-dev glib-static linux-headers zlib-static
RUN set -e; \
  [ "$(xx-info arch)" = "ppc64le" ] && XX_CC_PREFER_LINKER=ld xx-clang --setup-target-triple; \
  [ "$(xx-info arch)" = "386" ] && XX_CC_PREFER_LINKER=ld xx-clang --setup-target-triple; \
  true

FROM base AS build
ARG TARGETPLATFORM
# QEMU_TARGETS sets architectures that emulators are built for (default all)
ARG QEMU_VERSION QEMU_TARGETS
ENV AR=llvm-ar STRIP=llvm-strip
RUN --mount=target=.,from=src,src=/src/qemu,rw --mount=target=./install-scripts,src=scripts \
  echo ${TARGETPLATFORM} && \
  TARGETPLATFORM=${TARGETPLATFORM} configure_qemu.sh && \
  make -j "$(getconf _NPROCESSORS_ONLN)" && \
  make install && \
  cd /usr/bin && for f in $(ls qemu-*); do xx-verify --static $f; done

ARG BINARY_PREFIX
RUN cd /usr/bin; [ -z "$BINARY_PREFIX" ] || for f in $(ls qemu-*); do ln -s $f $BINARY_PREFIX$f; done

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS binfmt
COPY --from=xx / /
ENV CGO_ENABLED=0
ARG TARGETPLATFORM
ARG QEMU_VERSION
WORKDIR /src
RUN apk add --no-cache git
RUN --mount=target=. \
  TARGETPLATFORM=$TARGETPLATFORM xx-go build \
    -ldflags "-X main.revision=$(git rev-parse --short HEAD) -X main.qemuVersion=${QEMU_VERSION}" \
    -o /go/bin/binfmt ./cmd/binfmt && \
    xx-verify --static /go/bin/binfmt

FROM build AS build-archive
COPY --from=binfmt /go/bin/binfmt /usr/bin/binfmt
RUN cd /usr/bin && mkdir -p /archive && \
  tar czvfh "/archive/${BINARY_PREFIX}qemu_${QEMU_VERSION}_$(echo $TARGETPLATFORM | sed 's/\//-/g').tar.gz" ${BINARY_PREFIX}qemu* && \
  tar czvfh "/archive/binfmt_$(echo $TARGETPLATFORM | sed 's/\//-/g').tar.gz" binfmt

# binaries contains only the compiled QEMU binaries
FROM scratch AS binaries
# BINARY_PREFIX sets prefix string to all QEMU binaries
ARG BINARY_PREFIX
COPY --from=build usr/bin/${BINARY_PREFIX}qemu-* /

# archive returns the tarball of binaries
FROM scratch AS archive
COPY --from=build-archive /archive/* /

FROM --platform=$BUILDPLATFORM tonistiigi/bats-assert AS assert

FROM --platform=$BUILDPLATFORM alpine:${ALPINE_VERSION} AS alpine-crossarch

RUN apk add --no-cache bash

# Runs on the build platform without emulation, but we need to get hold of the cross arch busybox binary
# for use with tests using emulation
ARG BUILDARCH
RUN <<eof
  bash -euo pipefail -c '
    if [ "$BUILDARCH" == "amd64" ]; then
      echo "aarch64" > /etc/apk/arch
    else
      echo "x86_64" > /etc/apk/arch
    fi
    '
eof
RUN apk add --allow-untrusted --no-cache busybox-static

# Recreate all the symlinks for commands handled by the busybox multi-call binary such that they will use
# the cross-arch binary, and work under emulation
RUN <<eof
  bash -euo pipefail -c '
    mkdir -p /crossarch/bin /crossarch/usr/bin
    mv /bin/busybox.static /crossarch/bin/
    for i in $(echo /bin/*; echo /usr/bin/*); do
     if [[ $(readlink -f "$i") != *busybox* ]]; then
       continue
     fi
     ln -s /crossarch/bin/busybox.static /crossarch$i
    done'
eof

# buildkit-test runs test suite for buildkit embedded QEMU
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS buildkit-test
RUN apk add --no-cache bash bats
WORKDIR /work
COPY --from=assert . .
COPY test .
COPY --from=binaries / /usr/bin
COPY --from=alpine-crossarch /crossarch /crossarch/
RUN ./run.sh

# image builds binfmt installation image 
FROM scratch AS image
COPY --from=binaries / /usr/bin/
COPY --from=binfmt /go/bin/binfmt /usr/bin/binfmt
# QEMU_PRESERVE_ARGV0 defines if argv0 is used to set the binary name
ARG QEMU_PRESERVE_ARGV0
ENV QEMU_PRESERVE_ARGV0=${QEMU_PRESERVE_ARGV0}
ENTRYPOINT [ "/usr/bin/binfmt" ]
VOLUME /tmp
