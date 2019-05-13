ALL: build

bin/linuxkit:
	curl -Lo bin/linuxkit https://github.com/linuxkit/linuxkit/releases/download/v0.7/linuxkit-linux-amd64
	chmod +x bin/linuxkit

build: bin/linuxkit
	bin/linuxkit pkg build -org docker binfmt

push: bin/linuxkit
	bin/linuxkit pkg push -org docker binfmt

clean:
	rm -f bin/*
