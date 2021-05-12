# syntax=docker/dockerfile:1.2

ARG QEMU_VERSION
ARG QEMU_REPO=https://github.com/qemu/qemu

FROM --platform=$BUILDPLATFORM debian:buster AS src
RUN apt-get update && apt-get install -y git
ARG QEMU_VERSION
ARG QEMU_REPO
WORKDIR /src
RUN git clone $QEMU_REPO && \
  cd qemu && \
  git checkout $QEMU_VERSION && \
  scripts/git-submodule.sh update \
  ui/keycodemapdb \
  tests/fp/berkeley-testfloat-3 \
  tests/fp/berkeley-softfloat-3 \
  dtc slirp

FROM --platform=$BUILDPLATFORM debian:buster AS qemu

RUN apt-get update && \
  apt-get install -y \
  dpkg-dev \
  git \
  ninja-build \
  pkg-config \
  python3 \
  python3-setuptools

WORKDIR /qemu

ARG TARGETPLATFORM

ENV PATH=/qemu/install-scripts:$PATH
RUN --mount=target=./install-scripts,src=scripts \
  TARGETPLATFORM=${TARGETPLATFORM} cross.sh install gcc libglib2.0-dev | sh

FROM qemu AS base-amd64
FROM qemu AS base-arm64
FROM qemu AS base-ppc64le
FROM qemu AS base-s390x
FROM qemu AS base-armv7
FROM qemu AS base-armv6
FROM qemu AS base-386
FROM qemu AS base-mips64le

FROM tonistiigi/debian:riscv AS riscv-libglibc
RUN apt-get update && apt-get install -y libglib2.0-dev

RUN for f in $(dpkg-query -L zlib1g-dev libglib2.0-dev libpcre3-dev libglib2.0-0 libpcre3); do [ ! -d $f ] && echo $f; done > /tmp/list
RUN mkdir -p /out && tar cvf /out/libglibc.tar -T /tmp/list

FROM tonistiigi/xx:riscv-toolchain AS base-riscv64
RUN apt-get update && \
  apt-get install -y \
  dpkg-dev \
  git \
  ninja-build \
  pkg-config \
  python3 \
  python3-setuptools
ENV PATH=/qemu/install-scripts:$PATH
WORKDIR /qemu

RUN --mount=from=riscv-libglibc,target=/riscv-libglibc,src=out \
  mkdir -p /tmp/out && tar xvf /riscv-libglibc/libglibc.tar -C /tmp/out && \
  cp -a /tmp/out/usr/include/* /usr/riscv64-linux-gnu/include/ && \
  cp -a /tmp/out/usr/lib/riscv64-linux-gnu/* /usr/riscv64-linux-gnu/lib/ && \
  cp -a /tmp/out/usr/lib/* /usr/riscv64-linux-gnu/lib/ && \
  ln -s /usr/riscv64-linux-gnu /usr/riscv64-buildroot-linux-gnu
ENV CROSS_PREFIX=riscv64-buildroot-linux-gnu

FROM base-$TARGETARCH$TARGETVARIANT AS base

FROM base AS build
ARG TARGETPLATFORM
ARG QEMU_VERSION
RUN --mount=target=.,from=src,src=/src/qemu,rw --mount=target=./install-scripts,src=scripts \
  TARGETPLATFORM=${TARGETPLATFORM} configure_qemu.sh && \
  make -j "$(getconf _NPROCESSORS_ONLN)" && \
  make install

ARG BINARY_PREFIX
RUN cd /usr/bin; [ -z "$BINARY_PREFIX" ] || for f in $(ls qemu-*); do ln -s $f $BINARY_PREFIX$f; done

FROM build AS build-archive
RUN cd /usr/bin && mkdir -p /archive && \
  tar czvfh "/archive/${BINARY_PREFIX}qemu_${QEMU_VERSION}_$(echo $TARGETPLATFORM | sed 's/\//-/g').tar.gz" ${BINARY_PREFIX}qemu*

FROM --platform=$BUILDPLATFORM tonistiigi/xx:golang@sha256:6f7d999551dd471b58f70716754290495690efa8421e0a1fcf18eb11d0c0a537 AS xgo
FROM --platform=$BUILDPLATFORM golang:1.16-alpine AS binfmt
COPY --from=xgo / /
ENV CGO_ENABLED=0
ARG TARGETPLATFORM
ARG QEMU_VERSION
WORKDIR /src
RUN apk add --no-cache git
RUN --mount=target=. \
  TARGETPLATFORM=$TARGETPLATFORM go build \
    -ldflags "-X main.revision=$(git rev-parse --short HEAD) -X main.qemuVersion=${QEMU_VERSION}" \
    -o /go/bin/binfmt ./cmd/binfmt

FROM scratch AS binaries
ARG BINARY_PREFIX
COPY --from=build usr/bin/${BINARY_PREFIX}qemu-* /

FROM scratch AS archive
COPY --from=build-archive /archive/* /

FROM --platform=$BUILDPLATFORM tonistiigi/bats-assert AS assert

FROM golang:alpine AS buildkit-test
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
