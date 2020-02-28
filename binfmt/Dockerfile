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

ARG VERSION

RUN --mount=target=.,from=src,src=/src/qemu,rw --mount=target=./install-scripts,src=scripts \
  TARGETPLATFORM=${TARGETPLATFORM} configure_qemu.sh && make -j "$(getconf _NPROCESSORS_ONLN)" && make install

FROM linuxkit/alpine:27df8a8be139cd19cd7348c21efca8843b424f2b AS mirror

RUN apk add --no-cache go musl-dev
ENV GOPATH=/go PATH=$PATH:/go/bin

COPY main.go /go/src/binfmt/
RUN go-compile.sh /go/src/binfmt

FROM scratch AS binaries
COPY --from=qemu usr/bin/qemu-* /


# COPY --from=mirror /go/bin/binfmt usr/bin/binfmt
# COPY etc/binfmt.d/00_linuxkit.conf etc/binfmt.d/00_linuxkit.conf
# CMD ["/usr/bin/binfmt"]
