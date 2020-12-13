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

## Uninstalling emulators

```bash
docker run --privileged --rm tonistiigi/binfmt --uninstall qemu-aarch64
```

Emulator names can be found from the status output.

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
docker run --rm arm64v8/alpine uname -a
docker run --rm arm32v7/alpine uname -a
docker run --rm ppc64le/alpine uname -a
docker run --rm s390x/alpine uname -a
docker run --rm tonistiigi/debian:riscv uname -a
```

## Buildkit-helper target

This repository also provides helper for BuildKit's automatic emulation support https://github.com/moby/buildkit/pull/1528 . These binaries are BuildKit specific and should not be installed in kernel with `binfmt_misc`.