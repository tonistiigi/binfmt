#!/usr/bin/env sh

: ${TARGETPLATFORM=}
: ${TARGETOS=}
: ${TARGETARCH=}
: ${TARGETVARIANT=}

: ${OUT_ARCH=}
: ${DPKG_ARCH=}
: ${PKG_PREFIX=}
: ${CROSS_PREFIX=}

if [ -n "$TARGETPLATFORM" ]; then
  os="$(echo $TARGETPLATFORM | cut -d"/" -f1)"
  arch="$(echo $TARGETPLATFORM | cut -d"/" -f2)"
  if [ ! -z "$os" ] && [ ! -z "$arch" ]; then
    export TARGETOS="$os"
    export TARGETARCH="$arch"
    if [ "$arch" = "arm" ]; then
      case "$(echo $TARGETPLATFORM | cut -d"/" -f3)" in
      "v5")
        export TARGETVARIANT="5"
        ;;
      "v6")
        export TARGETVARIANT="6"
        ;;
      *)
        export TARGETVARIANT="7"
        ;;
      esac
    fi
  fi
fi

case "$TARGETARCH" in
"amd64")
  OUT_ARCH="x86_64"
  DPKG_ARCH="amd64"
  PKG_PREFIX="x86_64-linux-gnu"
  ;;
"arm64")
  OUT_ARCH="aarch64"
  DPKG_ARCH="arm64"
  PKG_PREFIX="aarch64-linux-gnu"
  ;;
"arm")
  OUT_ARCH="armv7l"
  DPKG_ARCH="armhf"
  PKG_PREFIX="arm-linux-gnueabihf"
  if [ "$TARGETVARIANT" = "6" ]; then
    OUT_ARCH="armv6l"
    DPKG_ARCH="armel"
    PKG_PREFIX="arm-linux-gnueabi"
  fi
  ;;
"riscv64")
  OUT_ARCH="riscv64"
  DPKG_ARCH="riscv64"
  PKG_PREFIX="riscv64-linux-gnu"
  ;;
"ppc64le")
  OUT_ARCH="ppc64le"
  DPKG_ARCH="ppc64el"
  PKG_PREFIX="powerpc64le-linux-gnu"
  ;;
"s390x")
  OUT_ARCH="s390x"
  DPKG_ARCH="s390x"
  PKG_PREFIX="s390x-linux-gnu"
  ;;
"386")
  OUT_ARCH="i386"
  DPKG_ARCH="i386"
  PKG_PREFIX="i686-linux-gnu"
  ;;
"mips64le")
  OUT_ARCH="mips64"
  DPKG_ARCH="mips64el"
  PKG_PREFIX="mips64el-linux-gnuabi64"
  ;;
*)
  OUT_ARCH="$(uname -m)"
  DPKG_ARCH="$(dpkg --print-architecture)"
esac

if [ -n "$CROSS_PREFIX" ]; then
  PKG_PREFIX="$CROSS_PREFIX"
fi

case "$1" in
"is_cross")
  if [ "$OUT_ARCH" = "$(uname -m)" ]; then
    exit 1
  else
    exit 0
  fi
  ;;
"arch")
  echo $OUT_ARCH;
  ;;
"dpkg-arch")
  echo $DPKG_ARCH;
  ;;
"cross-prefix")
  echo $PKG_PREFIX;
  ;;
"install")
  if [ "$OUT_ARCH" != "$(uname -m)" ] && ! dpkg --print-foreign-architectures | grep "$DPKG_ARCH" >/dev/null ; then
    echo dpkg --add-architecture "$DPKG_ARCH"
    echo apt-get update
  fi
  shift
  pkgs=""
  for name in $@; do
    if [ "$OUT_ARCH" != "$(uname -m)" ] && [ "$name" = "gcc" ] || [ "$name" = "g++" ]; then
      pfx="$PKG_PREFIX"
      if [ "$pfx" = "x86_64-linux-gnu" ]; then
        pfx="x86-64-linux-gnu"
       fi
      pkgs="$pkgs $name-$pfx "
    else
      pkgs="$pkgs $name:$DPKG_ARCH "
    fi
  done
  echo apt-get install -y $pkgs
  ;;
*)
  echo "unknown command $1"
  exit 1
  ;;
esac
