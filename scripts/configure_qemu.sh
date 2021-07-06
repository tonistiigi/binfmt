#!/usr/bin/env sh

set -e

: ${QEMU_TARGETS=}

arch="$(xx-info arch)"

if [ "$arch" != "amd64" ]; then
    QEMU_TARGETS="$QEMU_TARGETS x86_64-linux-user"
fi
if [ "$arch" != "arm64" ]; then
    QEMU_TARGETS="$QEMU_TARGETS aarch64-linux-user"
fi
if [ "$arch" != "arm" ]; then
    QEMU_TARGETS="$QEMU_TARGETS arm-linux-user"
fi
if [ "$arch" != "riscv64" ]; then
    QEMU_TARGETS="$QEMU_TARGETS riscv64-linux-user"
fi
if [ "$arch" != "ppc64le" ]; then
    QEMU_TARGETS="$QEMU_TARGETS ppc64le-linux-user"
fi
if [ "$arch" != "s390x" ] && [ "$arch" != "riscv64" ] ; then
    QEMU_TARGETS="$QEMU_TARGETS s390x-linux-user"
fi
if [ "$arch" != "386" ] ; then
    QEMU_TARGETS="$QEMU_TARGETS i386-linux-user"
fi
if [ "$arch" != "mips64le" ] ; then
    QEMU_TARGETS="$QEMU_TARGETS mips64el-linux-user"
fi
if [ "$arch" != "mips64" ] ; then
    QEMU_TARGETS="$QEMU_TARGETS mips64-linux-user"
fi

set -x
./configure \
  --prefix=/usr \
  --with-pkgversion=$QEMU_VERSION \
  --enable-linux-user \
  --disable-system \
  --static \
  --disable-blobs \
  --disable-brlapi \
  --disable-cap-ng \
  --disable-capstone \
  --disable-curl \
  --disable-curses \
  --disable-docs \
  --disable-gcrypt \
  --disable-gnutls \
  --disable-gtk \
  --disable-guest-agent \
  --disable-guest-agent-msi \
  --disable-libiscsi \
  --disable-libnfs \
  --disable-mpath \
  --disable-nettle \
  --disable-opengl \
  --disable-pie \
  --disable-sdl \
  --disable-spice \
  --disable-tools \
  --disable-vte \
  --disable-werror \
  --disable-debug-info \
  --disable-glusterfs \
  --cross-prefix=$(xx-info)- \
  --host-cc=$(xx-clang --print-target-triple)-clang \
  --host=$(xx-clang --print-target-triple) \
  --build=$(TARGETPLATFORM= TARGETPAIR= xx-clang --print-target-triple) \
  --cc=$(xx-clang --print-target-triple)-clang \
  --extra-ldflags=-latomic \
  --target-list="$QEMU_TARGETS"
