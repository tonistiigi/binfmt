# syntax=docker/dockerfile:1.1-experimental
ARG VERSION=v4.1.0

FROM --platform=$BUILDPLATFORM debian:buster AS src
RUN apt-get update && apt-get install -y git
ARG VERSION
WORKDIR /src
RUN git clone -b moby/$VERSION https://github.com/moby/qemu && \
  cd qemu && scripts/git-submodule.sh update \
  ui/keycodemapdb \
  tests/fp/berkeley-testfloat-3 \
  tests/fp/berkeley-softfloat-3 \
  dtc slirp

FROM --platform=$BUILDPLATFORM debian:buster AS qemu

RUN apt-get update && \
  apt-get install -y \
  pkg-config \
  python \
  dpkg-dev

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

FROM tonistiigi/debian:riscv AS riscv-libglibc
RUN apt-get update && apt-get install -y libglib2.0-dev

RUN for f in $(dpkg-query -L zlib1g-dev libglib2.0-dev libpcre3-dev libglib2.0-0 libpcre3); do [ ! -d $f ] && echo $f; done > /tmp/list
RUN mkdir -p /out && tar cvf /out/libglibc.tar -T /tmp/list

FROM tonistiigi/xx:riscv-toolchain AS base-riscv64
RUN apt-get update && apt-get install -y python dpkg-dev pkg-config
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
ARG VERSION

RUN --mount=target=.,from=src,src=/src/qemu,rw --mount=target=./install-scripts,src=scripts \
  TARGETPLATFORM=${TARGETPLATFORM} configure_qemu.sh && make -j "$(getconf _NPROCESSORS_ONLN)" && make install

FROM --platform=$BUILDPLATFORM tonistiigi/xx:golang@sha256:6f7d999551dd471b58f70716754290495690efa8421e0a1fcf18eb11d0c0a537 AS xgo

FROM --platform=$BUILDPLATFORM golang:1.14-alpine AS mirror
COPY --from=xgo / /
ENV CGO_ENABLED=0
ENV GOPATH=/go PATH=$PATH:/go/bin

COPY main.go /go/src/binfmt/
ARG TARGETPLATFORM
RUN TARGETPLATFORM=$TARGETPLATFORM go build -o /go/bin/binfmt /go/src/binfmt


FROM scratch AS binaries
COPY --from=build usr/bin/qemu-* /
COPY --from=mirror /go/bin/binfmt binfmt

# COPY etc/binfmt.d/00_linuxkit.conf etc/binfmt.d/00_linuxkit.conf
# CMD ["/usr/bin/binfmt"]