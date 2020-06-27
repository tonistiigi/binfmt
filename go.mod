module github.com/tonistiigi/binfmt/binfmt

go 1.14

require (
	github.com/containerd/containerd v1.4.0-0
	github.com/moby/buildkit v0.6.2-0.20200303093749-09900f32dcaa
	github.com/pkg/errors v0.9.1
)

replace github.com/containerd/containerd => github.com/containerd/containerd v1.3.1-0.20200227195959-4d242818bf55

replace github.com/docker/docker => github.com/docker/docker v1.4.2-0.20200227233006-38f52c9fec82
