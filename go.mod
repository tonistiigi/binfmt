module github.com/tonistiigi/binfmt

go 1.15

require (
	github.com/containerd/containerd v1.4.3
	github.com/moby/buildkit v0.8.0
	github.com/pkg/errors v0.9.1
)

replace github.com/docker/docker => github.com/docker/docker v1.4.2-0.20200227233006-38f52c9fec82
