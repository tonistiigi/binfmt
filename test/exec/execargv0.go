package main

import (
	"errors"
	"flag"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func main() {
	if err := run(); err != nil {
		log.Printf("%+v", err)
		os.Exit(1)
	}
}

func run() error {
	flag.Parse()
	if len(flag.Args()) < 2 {
		return errors.New("at least 2 arguments required")
	}
	cmd := &exec.Cmd{
		Args: flag.Args()[1:],
	}
	argv0 := flag.Arg(0)
	if filepath.IsAbs(argv0) {
		cmd.Path = argv0
	} else if strings.HasPrefix(argv0, "./") {
		p, err := filepath.Abs(argv0)
		if err != nil {
			return err
		}
		cmd.Path = p
	} else {
		p, err := exec.LookPath(argv0)
		if err != nil {
			return err
		}
		cmd.Path = p
	}
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
