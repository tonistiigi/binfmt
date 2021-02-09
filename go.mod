module github.com/tonistiigi/binfmt

go 1.15

require (
	github.com/containerd/containerd v1.4.1-0.20201215193253-e922d5553d12
	github.com/moby/buildkit v0.8.2-0.20210202025417-7cd6a5feaf83
	github.com/pkg/errors v0.9.1
)

replace github.com/containerd/stargz-snapshotter/estargz v0.0.0-00010101000000-000000000000 => github.com/containerd/stargz-snapshotter/estargz v0.0.0-20210202123615-f0962e4437ca
