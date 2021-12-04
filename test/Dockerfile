#syntax=docker/dockerfile:1.3-labs

FROM --platform=$BUILDPLATFORM tonistiigi/xx:1.1.0 AS xx

FROM scratch AS src
COPY *.go go.* /

FROM --platform=$BUILDPLATFORM golang:1.17-alpine AS build
COPY --from=xx / /
RUN apk add clang lld file
ARG TARGETPLATFORM
RUN xx-apk add musl-dev linux-headers gcc
WORKDIR /src
RUN XX_CC_PREFER_STATIC_LINKER=1 xx-clang --setup-target-triple
RUN --mount=from=src \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg \
    CGO_ENABLED=1 xx-go test -c -o /out/test -ldflags "-linkmode external -extldflags -static" . && \
    xx-verify --static /out/test

FROM scratch AS binary
COPY --from=build /out/test .

FROM alpine AS run
RUN apk add libcap
COPY --from=binary / /usr/bin
ARG CONFIG_RT_GROUP_SCHED
RUN --security=insecure /usr/bin/test -test.v

FROM binary