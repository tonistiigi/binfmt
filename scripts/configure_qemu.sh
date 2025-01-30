#!/usr/bin/env sh

set -e

: "${QEMU_TARGETS_EXCLUDE=}"

arch="$(xx-info arch)"

if [ "$arch" = "amd64" ]; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE x86_64-linux-user"
fi
if [ "$arch" = "arm64" ]; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE aarch64-linux-user"
fi
if [ "$arch" = "arm" ]; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE arm-linux-user"
fi
if [ "$arch" = "riscv64" ]; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE riscv64-linux-user"
fi
if [ "$arch" = "ppc64le" ]; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE ppc64le-linux-user"
fi
if [ "$arch" = "s390x" ]; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE s390x-linux-user"
fi
if [ "$arch" = "386" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE i386-linux-user"
fi
if [ "$arch" = "mips64le" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE mips64el-linux-user"
fi
if [ "$arch" = "mips64" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE mips64-linux-user"
fi
if [ "$arch" = "loong64" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE loongarch64-linux-user"
fi
# github.com/containerd/containerd/platforms/database
if [ "$arch" = "armbe" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE armeb-linux-user"
fi
if [ "$arch" = "sparc" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE sparc-linux-user"
fi
if [ "$arch" = "sparc64" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE sparc64-linux-user"
fi
if [ "$arch" = "ppc" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE ppc-linux-user"
fi
if [ "$arch" = "ppc64" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE ppc64-linux-user"
fi
if [ "$arch" = "mips" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE mips-linux-user"
fi
if [ "$arch" = "mipsle" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE mipsel-linux-user"
fi
if [ "$arch" = "mips64p32" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE mipsn32-linux-user"
fi
if [ "$arch" = "mips64p32le" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE mipsn32el-linux-user"
fi
if [ "$arch" = "arm64be" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE aarch64_be-linux-user"
fi
if [ "$arch" = "riscv" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE riscv32-linux-user"
fi
# https://github.com/qemu/qemu/blob/master/scripts/qemu-binfmt-conf.sh
if [ "$arch" = "alpha" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE alpha-linux-user"
fi
if [ "$arch" = "sparc32plus" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE sparc32plus-linux-user"
fi
if [ "$arch" = "m68k" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE m68k-linux-user"
fi
if [ "$arch" = "sh4" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE sh4-linux-user"
fi
if [ "$arch" = "sh4be" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE sh4be-linux-user"
fi
if [ "$arch" = "hppa" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE hppa-linux-user"
fi
if [ "$arch" = "xtensa" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE xtensa-linux-user"
fi
if [ "$arch" = "xtensabe" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE xtensaeb-linux-user"
fi
if [ "$arch" = "microblaze" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE microblaze-linux-user"
fi
if [ "$arch" = "microblazele" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE microblazeel-linux-user"
fi
if [ "$arch" = "or1k" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE or1k-linux-user"
fi
if [ "$arch" = "hexagon" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE hexagon-linux-user"
fi
# https://salsa.debian.org/qemu-team/qemu/-/blob/master/debian/binfmt-install
if [ "$arch" = "cris" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE cris-linux-user"
fi
# No binfmt magic/mask
if [ "$arch" = "nios2" ] ; then
  QEMU_TARGETS_EXCLUDE="$QEMU_TARGETS_EXCLUDE nios2-linux-user"
fi

set -x
./configure \
  --prefix=/usr \
  --with-pkgversion=$QEMU_VERSION \
  --enable-linux-user \
  --disable-system \
  --static \
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
  --target-list-exclude="$QEMU_TARGETS_EXCLUDE"
