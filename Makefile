ALL: build

bin/linuxkit:
	curl -Lo bin/linuxkit https://github.com/linuxkit/linuxkit/releases/download/v0.7/linuxkit-linux-amd64
	echo "c747033343315774b6e51f618eb143d5714e398a32b59b9b6acab23b599dd970  bin/linuxkit" | sha256sum --check
	chmod +x bin/linuxkit

bin/manifest-tool:
	curl -Lo bin/manifest-tool https://github.com/estesp/manifest-tool/releases/download/v0.9.0/manifest-tool-linux-amd64
	echo "80906341c3306e3838437eeb08fff5da2c38bd89149019aa301c7745e07ea8f9  bin/manifest-tool" | sha256sum --check
	chmod +x bin/manifest-tool

bin/notary:
	curl -Lo bin/notary https://github.com/theupdateframework/notary/releases/download/v0.6.1/notary-Linux-amd64
	echo "73353b2b4b85604c738a6800465133cb3a828dff0aa26f3c0926dd9a73e19879 bin/notary" | sha256sum --check
	chmod +x bin/notary

build: bin/linuxkit
	bin/linuxkit pkg build -org docker binfmt

test: bin/linuxkit
	bin/linuxkit pkg build -org docker -hash test binfmt
	docker run --rm --privileged docker/binfmt:test
	docker run --rm arm64v8/alpine uname -a
	docker run --rm arm32v7/alpine uname -a
	docker run --rm ppc64le/alpine uname -a
	docker run --rm s390x/alpine uname -a

push-unsigned: bin/linuxkit bin/manifest-tool
	export PATH=$(CURDIR)/bin:$$PATH ; bin/linuxkit pkg push -disable-content-trust -org docker binfmt

push-signed: bin/linuxkit bin/manifest-tool bin/notary
		export PATH=$(CURDIR)/bin:$$PATH ; bin/linuxkit pkg push -org docker binfmt


clean:
	rm -f bin/*
