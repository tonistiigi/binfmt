# syntax=docker/dockerfile:1.2

ARG ALPINE_BASE=alpine:3.13

ARG QEMU_VERSION
ARG QEMU_REPO=https://github.com/qemu/qemu

# xx is a helper for cross-compilation
FROM --platform=$BUILDPLATFORM tonistiigi/xx@sha256:e34a0426f70defa9519be88256fb46336660a75b70f8810ada9f7eb88e2c24aa AS xx

FROM --platform=$BUILDPLATFORM ${ALPINE_BASE} AS src
RUN apk add --no-cache git patch
ARG QEMU_VERSION
ARG QEMU_REPO
WORKDIR /src
RUN git clone $QEMU_REPO && \
  git clone --depth 1 https://github.com/alpinelinux/aports.git && \
  cd qemu && \
  git checkout $QEMU_VERSION && \
  for f in  ../aports/community/qemu/*.patch; do patch -p1 < $f; done && \
  scripts/git-submodule.sh update \
  ui/keycodemapdb \
  tests/fp/berkeley-testfloat-3 \
  tests/fp/berkeley-softfloat-3 \
  dtc slirp

FROM --platform=$BUILDPLATFORM ${ALPINE_BASE} AS base
RUN apk add --no-cache git clang lld python3 llvm make ninja pkgconfig glib-dev gcc musl-dev perl bash
COPY --from=xx / /
ENV PATH=/qemu/install-scripts:$PATH
WORKDIR /qemu

ARG TARGETPLATFORM
RUN xx-apk add musl-dev gcc glib-dev glib-static linux-headers zlib-static
RUN set -e; \
  [ "$(xx-info arch)" = "ppc64le" ] && XX_CC_PREFER_LINKER=ld xx-clang --setup-target-triple; \
  [ "$(xx-info arch)" = "386" ] && XX_CC_PREFER_LINKER=ld xx-clang --setup-target-triple; \
  true


FROM base AS build
ARG TARGETPLATFORM
ARG QEMU_VERSION
ENV AR=llvm-ar STRIP=llvm-strip
RUN --mount=target=.,from=src,src=/src/qemu,rw --mount=target=./install-scripts,src=scripts \
  TARGETPLATFORM=${TARGETPLATFORM} configure_qemu.sh && \
  make -j "$(getconf _NPROCESSORS_ONLN)" && \
  make install && \
  cd /usr/bin && for f in $(ls qemu-*); do xx-verify $f; done 

ARG BINARY_PREFIX
RUN cd /usr/bin; [ -z "$BINARY_PREFIX" ] || for f in $(ls qemu-*); do ln -s $f $BINARY_PREFIX$f; done

FROM build AS build-archive
RUN cd /usr/bin && mkdir -p /archive && \
  tar czvfh "/archive/${BINARY_PREFIX}qemu_${QEMU_VERSION}_$(echo $TARGETPLATFORM | sed 's/\//-/g').tar.gz" ${BINARY_PREFIX}qemu*

FROM --platform=$BUILDPLATFORM golang:1.16-alpine AS binfmt
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
    xx-verify /go/bin/binfmt

FROM scratch AS binaries
ARG BINARY_PREFIX
COPY --from=build usr/bin/${BINARY_PREFIX}qemu-* /

FROM scratch AS archive
COPY --from=build-archive /archive/* /

FROM --platform=$BUILDPLATFORM tonistiigi/bats-assert AS assert

FROM golang:1.16-alpine AS buildkit-test
RUN apk add --no-cache bash bats
WORKDIR /work
COPY --from=assert . .
COPY test .
COPY --from=binaries / /usr/bin
RUN ./run.sh

FROM scratch
COPY --from=binaries / /usr/bin/
COPY --from=binfmt /go/bin/binfmt /usr/bin/binfmt
ENTRYPOINT [ "/usr/bin/binfmt" ]
VOLUME /tmp
