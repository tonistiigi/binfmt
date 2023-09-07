package main

import "github.com/containerd/containerd/platforms"

func newList() list {
	return list{
		included: map[string]bool{},
	}
}

type list struct {
	included map[string]bool
	items    []string
}

func (a *list) add(platform ...string) {
	for _, v := range platform {
		p := getArch(v)
		if a.included[p] {
			continue
		}
		a.items = append(a.items, p)
		a.included[p] = true
	}
}

// exclude the given platform.
func (a *list) exclude(platform string) {
	if p := getArch(platform); a.included[p] {
		b := a.items[:0]
		for _, v := range a.items {
			if v != p {
				b = append(b, v)
			}
		}
		a.items = b
	} else {
		a.included[p] = true
	}
}

func getArch(platform string) string {
	p, err := platforms.Parse(platform)
	if err != nil {
		return platform
	}
	return p.Architecture
}
