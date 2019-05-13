# docker/binfmt 

Build and push the `docker/binfmt` image.

## Build

    make

This builds the `docker/binfmt` image with QEMU static binaries from `moby/qemu`
and branch `moby/v3.1.0`.

## Push

    make push

This pushes the image to Docker Hub.

## Test manually

    make

Builds a docker/binfmt image - note the image ID.

    docker run --rm --privileged imageid

This registers the new QEMU binaries in the host kernel. Test all different architectures

    docker run --rm aarch64/alpine uname -a
    docker run --rm arm32v7/alpine uname -a
    docker run --rm ppc64le/alpine uname -a
    docker run --rm s390x/alpine uname -a
