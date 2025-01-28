# syntax=docker/dockerfile:1

ARG GO_VERSION=1.23
ARG ALPINE_VERSION=3.21

FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION}
RUN apk add --no-cache gcc musl-dev
RUN wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s v1.62.0
WORKDIR /go/src/github.com/tonistiigi/binfmt
RUN --mount=target=. --mount=target=/root/.cache,type=cache \
  golangci-lint run
