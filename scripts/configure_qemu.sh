#!/usr/bin/env sh

set -x

: ${QEMU_TARGETS=}
: ${FLAG_CROSS_PREFIX=}

arch="$(cross.sh arch)"

if [ "$arch" != "x86_64" ]; then
    QEMU_TARGETS="$QEMU_TARGETS x86_64-linux-user"
fi
if [ "$arch" != "aarch64" ]; then
    QEMU_TARGETS="$QEMU_TARGETS aarch64-linux-user"
fi
if [ "$arch" != "armv7l" ] && [ "$arch" != "armv6l" ] ; then
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

if cross.sh is_cross; then 
    FLAG_CROSS_PREFIX="--cross-prefix=$(cross.sh cross-prefix)-"
fi

set -x
./configure \
  --prefix=/usr \
  --with-pkgversion=$VERSION \
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
  --disable-sdl \
  --disable-spice \
  --disable-tools \
  --disable-vte $FLAG_CROSS_PREFIX --target-list="$QEMU_TARGETS" 