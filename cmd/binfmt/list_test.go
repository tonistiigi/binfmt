package main

import (
	"testing"
)

func TestList(t *testing.T) {
	all := []string{"amd64", "arm64", "s390x"}
	allItems := len(all)

	a := newList()
	a.add(all...)
	if len(a.items) != allItems {
		t.Errorf("expected: %d, got: %d: %v", allItems, len(a.items), a.items)
	}
	a.add("amd64", "amd64")
	if len(a.items) != allItems {
		t.Errorf("expected: %d, got: %d: %v", allItems, len(a.items), a.items)
	}
	a.exclude("amd64")
	if len(a.items) != allItems-1 {
		t.Errorf("expected: %d, got: %d: %v", allItems-1, len(a.items), a.items)
	}
}
