#!/usr/bin/env sh

go build print/printargs.go
go build exec/execargv0.go

echo "testing $(uname -m)"
./test.bats

crossArch=arm64
crossEmulator=aarch64

if [ "$(uname -m)" = "aarch64" ]; then
  crossArch="amd64"
  crossEmulator="x86_64"
fi

GOARCH=$crossArch go build print/printargs.go
GOARCH=$crossArch go build exec/execargv0.go

if ./printargs >/dev/null 2>/dev/nulll; then
  echo "can't test emulator because $crossEmulator emulator is installed in the kernel"
  exit 1
fi

echo "testing $crossEmulator"
BINFMT_EMULATOR=$crossEmulator ./test.bats
