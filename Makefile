ALL: build

bin/linuxkit:
	curl -Lo bin/linuxkit https://github.com/linuxkit/linuxkit/releases/download/v0.7/linuxkit-linux-amd64
	chmod +x bin/linuxkit

build: bin/linuxkit
	bin/linuxkit pkg build -org docker binfmt

test: bin/linuxkit
	bin/linuxkit pkg build -org docker -hash test binfmt
	docker run --rm --privileged docker/binfmt:test
	docker run --rm arm64v8/alpine uname -a
	docker run --rm arm32v7/alpine uname -a
	docker run --rm ppc64le/alpine uname -a
	docker run --rm s390x/alpine uname -a

push: bin/linuxkit
	bin/linuxkit pkg push -org docker binfmt

clean:
	rm -f bin/*
