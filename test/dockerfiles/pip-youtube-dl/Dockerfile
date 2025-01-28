FROM python:3.9-alpine
MAINTAINER kev <noreply@easypi.pro>

RUN apk add --no-cache ca-certificates ffmpeg openssl aria2

ARG QEMU_STRACE
RUN pip3 install youtube-dl

# Try to run it so we know it works
RUN youtube-dl --version

WORKDIR /data

ENTRYPOINT ["youtube-dl"]
CMD ["--help"]
