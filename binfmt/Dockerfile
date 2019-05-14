FROM debian@sha256:75f7d0590b45561bfa443abad0b3e0f86e2811b1fc176f786cd30eb078d1846f AS qemu
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        git \
        libtool \
        libpixman-1-dev \
        libglib2.0-dev \
        pkg-config \
        python

RUN git clone -b moby/v4.0.0 https://github.com/moby/qemu && \
  	cd qemu && scripts/git-submodule.sh update \
    		ui/keycodemapdb \
    		tests/fp/berkeley-testfloat-3 \
    		tests/fp/berkeley-softfloat-3 \
    		dtc

WORKDIR /qemu

RUN ./configure \
        --prefix=/usr \
        --enable-linux-user \
        --disable-system \
        --static \
        --disable-blobs \
        --disable-bluez \
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
        --target-list="aarch64-linux-user arm-linux-user ppc64le-linux-user s390x-linux-user"

RUN make -j "$(getconf _NPROCESSORS_ONLN)"
RUN make install

FROM linuxkit/alpine:518c2ed0f398c5508969ac5e033607201fb419ed AS mirror

RUN apk add --no-cache go musl-dev
ENV GOPATH=/go PATH=$PATH:/go/bin

COPY main.go /go/src/binfmt/
RUN go-compile.sh /go/src/binfmt

FROM scratch
ENTRYPOINT []
WORKDIR /
COPY --from=qemu usr/bin/qemu-* usr/bin/
COPY --from=mirror /go/bin/binfmt usr/bin/binfmt
COPY etc/binfmt.d/00_linuxkit.conf etc/binfmt.d/00_linuxkit.conf
CMD ["/usr/bin/binfmt"]
