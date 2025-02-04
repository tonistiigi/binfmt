# syntax=docker/dockerfile:1

# https://github.com/processone/ejabberd/blob/master/.github/container/Dockerfile

FROM --platform=$BUILDPLATFORM alpine AS src
WORKDIR /ejabberd
ADD --keep-git-dir=true "https://github.com/processone/ejabberd.git#24.12" .
RUN mv .github/container/ejabberdctl.template .

FROM erlang:27.2-alpine AS build
RUN apk --update --no-cache add \
        autoconf \
        automake \
        bash \
        build-base \
        curl \
        expat-dev \
        file \
        gd-dev \
        git \
        jpeg-dev \
        libpng-dev \
        libwebp-dev \
        linux-pam-dev \
        openssl-dev \
        sqlite-dev \
        yaml-dev \
        zlib-dev

WORKDIR /src/elixir
RUN wget -q https://github.com/elixir-lang/elixir/archive/v1.18.1.tar.gz -O - | tar xvz --strip 1

ARG QEMU_STRACE

RUN make install clean

RUN mix local.hex --force \
    && mix local.rebar --force

WORKDIR /src/ejabberd
COPY --from=src /ejabberd .
RUN ./autogen.sh \
    && ./configure --with-rebar=mix \
    && make deps \
    && make rel
