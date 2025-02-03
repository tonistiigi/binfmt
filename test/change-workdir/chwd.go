package main

import (
	"bytes"
	"crypto/md5"
	"fmt"
	"os"
)

func main() {
	if err := os.Chdir("/tmp"); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	if p, err := os.Readlink("/proc/self/exe"); err != nil {
		fmt.Println(err)
		os.Exit(1)
	} else {
		fmt.Println(p)
	}
	f, err := os.Open("/proc/self/exe")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer f.Close()
	var buf bytes.Buffer
	buf.ReadFrom(f)
	hash := md5.Sum(buf.Bytes())
	f2, err := os.Open(os.Args[1])
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	buf.Reset()
	buf.ReadFrom(f2)
	hash2 := md5.Sum(buf.Bytes())
	if hash != hash2 {
		fmt.Printf("/proc/self/exe does not match %s\n", os.Args[1])
		os.Exit(1)
	}
	os.Exit(0)
}
