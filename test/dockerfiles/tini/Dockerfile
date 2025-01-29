# syntax=docker/dockerfile:1

ARG TINI_VERSION="v0.19.0"

FROM alpine:3.17
RUN apk add --no-cache file wget
ARG TINI_VERSION
ARG TARGETPLATFORM
RUN <<EOT
  TINI_ARCH=$(case ${TARGETPLATFORM} in
    "linux/amd64")   echo "amd64"   ;;
    "linux/arm/v6")  echo "armel"   ;;
    "linux/arm/v7")  echo "armhf"   ;;
    "linux/arm64")   echo "arm64"   ;;
    "linux/ppc64le") echo "ppc64le" ;;
    "linux/s390x")   echo "390x"    ;;
    *)               echo ""        ;; esac)
  wget -q "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-${TINI_ARCH}" -qO /tini
  chmod +x /tini
  file /tini
EOT

ENV QEMU_STRACE=""
CMD [ "/tini", "-s", "--", "uname", "-a" ]
