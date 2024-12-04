# Binfmt

[![GitHub release](https://img.shields.io/github/release/tonistiigi/binfmt.svg?style=flat-square)](https://github.com/tonistiigi/binfmt/releases/latest)
[![CI Status](https://img.shields.io/github/actions/workflow/status/tonistiigi/binfmt/ci.yml?label=ci&logo=github&style=flat-square)](https://github.com/tonistiigi/binfmt/actions?query=workflow%3Aci)
[![Go Report Card](https://goreportcard.com/badge/github.com/tonistiigi/binfmt?style=flat-square)](https://goreportcard.com/report/github.com/tonistiigi/binfmt)
[![Docker Pulls](https://img.shields.io/docker/pulls/tonistiigi/binfmt.svg?style=flat-square&logo=docker)](https://hub.docker.com/r/tonistiigi/binfmt/)

Cross-platform emulator collection distributed with Docker images.

## Build local binaries

```bash
docker buildx bake
```

This builds the qemu-user emulator binaries for your local plaform to the `bin` directory.

## Build test image

```bash
REPO=myuser/binfmt docker buildx bake --load mainline
docker run --privileged --rm myuser/binfmt
```

Prints similar to:

```
{
  "supported": [
    "linux/amd64",
    "linux/arm64",
    "linux/riscv64",
    "linux/ppc64le",
    "linux/s390x",
    "linux/386",
    "linux/arm/v7",
    "linux/arm/v6"
  ],
  "emulators": [
    "qemu-aarch64",
    "qemu-arm",
    "qemu-i386",
    "qemu-ppc64le",
    "qemu-riscv64",
    "qemu-s390x"
  ]
}
```

## Installing emulators

```bash
docker run --privileged --rm tonistiigi/binfmt --install all
docker run --privileged --rm tonistiigi/binfmt --install arm64,riscv64,arm
```

## Installing emulators from Docker-Compose

```docker
version: "3"
services:
  emulator:
    image: tonistiigi/binfmt
    container_name: emulator
    privileged: true
    command: --install all
    network_mode: bridge
    restart: "no"
```
Only use container `restart-policy` as `no`, otherwise docker will keep restarting the container.

## Uninstalling emulators

```bash
docker run --privileged --rm tonistiigi/binfmt --uninstall qemu-aarch64
```

Emulator names can be found from the status output.

You can also uninstall all archs for a specific emulator:

```bash
docker run --privileged --rm tonistiigi/binfmt --uninstall qemu-*
```

## Display version

```bash
docker run --privileged --rm tonistiigi/binfmt --version
```
```
binfmt/9a44d27 qemu/v6.0.0 go/1.15.11
```

## Development commands

```bash
# validate linter
./hack/lint

# validate vendored files
./hack/validate-vendor

# update vendored files
./hack/update-vendor

# test, only run on nodes where you allow emulators to be installed in kernel
./hack/install-and-test
```

## Test current emulation support

```
docker run --rm arm64v8/alpine:latest@sha256:ea3c5a9671f7b3f7eb47eab06f73bc6591df978b0d5955689a9e6f943aa368c0 uname -a
docker run --rm arm32v7/alpine:latest@sha256:4fdafe217d0922f3c3e2b4f64cf043f8403a4636685cd9c51fea2cbd1f419740 uname -a
docker run --rm ppc64le/alpine:latest@sha256:0880443bffa028dfbbc4094a32dd6b7ac25684e4c0a3d50da9e0acae355c5eaf uname -a
docker run --rm s390x/alpine:latest@sha256:b815fadf80495594eb6296a6af0bc647ae5f193e0044e07acec7e5b378c9ce2d uname -a
docker run --rm tonistiigi/debian:riscv uname -a
```

## `buildkit` target

This repository also provides helper for BuildKit's automatic emulation support https://github.com/moby/buildkit/pull/1528.
These binaries are BuildKit specific and should not be installed in kernel with `binfmt_misc`.

## Licenses

MIT. See `LICENSE` for more details.
For QEMU see https://wiki.qemu.org/License
