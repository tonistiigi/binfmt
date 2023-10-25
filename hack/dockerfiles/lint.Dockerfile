# syntax=docker/dockerfile:1

ARG GO_VERSION=1.21

FROM golang:${GO_VERSION}-alpine
RUN apk add --no-cache gcc musl-dev
RUN wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s v1.54.2
WORKDIR /go/src/github.com/tonistiigi/binfmt
RUN --mount=target=. --mount=target=/root/.cache,type=cache \
  golangci-lint run
