# syntax = docker/dockerfile:1.1-experimental
FROM golang:1.14-alpine AS vendored
RUN  apk add --no-cache git
WORKDIR /src
RUN --mount=target=/src,rw \
  --mount=target=/go/pkg/mod,type=cache \
  go mod tidy && \
  mkdir /out && cp -r go.mod go.sum /out

FROM scratch AS update
COPY --from=vendored /out /

FROM vendored AS validate
RUN --mount=target=.,rw \
  git add -A && \
  cp -rf /out/* . && \
  ./hack/validate-vendor check
