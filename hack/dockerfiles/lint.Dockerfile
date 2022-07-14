# syntax=docker/dockerfile:1

FROM golang:1.18-alpine
RUN apk add --no-cache gcc musl-dev
RUN wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s v1.45.0
WORKDIR /go/src/github.com/tonistiigi/binfmt
RUN --mount=target=. --mount=target=/root/.cache,type=cache \
  golangci-lint run
