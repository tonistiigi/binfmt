FROM alpine:3.15.4 AS build
ARG REPOSITORY=https://github.com/processone/ejabberd.git
#ARG VERSION=master
ARG VERSION=99d9e315a3c0524d84197e63741790d5893c51f4

RUN apk upgrade --update musl \
    && apk add \
    autoconf \
    automake \
    bash \
    build-base \
    curl \
    elixir \
    erlang-odbc \
    erlang-reltool \
    expat-dev \
    file \
    gd-dev \
    git \
    jpeg-dev \
    libpng-dev \
    libwebp-dev \
    linux-pam-dev \
    openssl \
    openssl-dev \
    sqlite-dev \
    yaml-dev \
    zlib-dev

ARG QEMU_STRACE

RUN mix local.hex --force \
    && mix local.rebar --force

WORKDIR ejabberd

RUN git clone $REPOSITORY . \
    && git checkout $VERSION \
    && mv .github/container/ejabberdctl.template . \
    && ./autogen.sh \
    && ./configure --with-rebar=mix \
    && make deps \
    && make rel
