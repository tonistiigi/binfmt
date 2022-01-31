package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"syscall"

	"github.com/containerd/containerd/platforms"
	"github.com/moby/buildkit/util/archutil"
	"github.com/pkg/errors"
)

var (
	mount       string
	toInstall   string
	toUninstall string
	flVersion   bool
)

func init() {
	flag.StringVar(&mount, "mount", "/proc/sys/fs/binfmt_misc", "binfmt_misc mount point")
	flag.StringVar(&toInstall, "install", "", "architectures to install")
	flag.StringVar(&toUninstall, "uninstall", "", "architectures to uninstall")
	flag.BoolVar(&flVersion, "version", false, "display version")
}

func uninstall(arch string) error {
	fis, err := os.ReadDir(mount)
	if err != nil {
		return err
	}
	for _, fi := range fis {
		if fi.Name() == arch || strings.HasSuffix(fi.Name(), "-"+arch) {
			return os.WriteFile(filepath.Join(mount, fi.Name()), []byte("-1"), 0600)
		}
	}
	return errors.Errorf("not found")
}

func install(arch string) error {
	cfg, ok := configs[arch]
	if !ok {
		return errors.Errorf("unsupported architecture: %v", arch)
	}
	register := filepath.Join(mount, "register")
	file, err := os.OpenFile(register, os.O_WRONLY, 0)
	if err != nil {
		e, ok := err.(*os.PathError)
		if ok && e.Err == syscall.ENOENT {
			return errors.Errorf("ENOENT opening %s is it mounted?", register)
		}
		if ok && e.Err == syscall.EPERM {
			return errors.Errorf("EPERM opening %s check permissions?", register)
		}
		return errors.Errorf("Cannot open %s: %s", register, err)
	}
	defer file.Close()

	binaryPath := "/usr/bin"
	if v := os.Getenv("QEMU_BINARY_PATH"); v != "" {
		binaryPath = v
	}
	flags := "CF"
	if v := os.Getenv("QEMU_PRESERVE_ARGV0"); v != "" {
		flags += "P"
	}
	binaryBasename := cfg.binary
	if binaryPrefix := os.Getenv("QEMU_BINARY_PREFIX"); binaryPrefix != "" {
		if strings.ContainsRune(binaryPrefix, os.PathSeparator) {
			return errors.New("binary prefix must not contain path separator (Hint: set $QEMU_BINARY_PATH to specify the directory)")
		}
		binaryBasename = binaryPrefix + binaryBasename
	}
	binaryFullpath := filepath.Join(binaryPath, binaryBasename)

	line := fmt.Sprintf(":%s:M:0:%s:%s:%s:%s", binaryBasename, cfg.magic, cfg.mask, binaryFullpath, flags)

	// short writes should not occur on sysfs, cannot usefully recover
	_, err = file.Write([]byte(line))
	if err != nil {
		e, ok := err.(*os.PathError)
		if ok && e.Err == syscall.EEXIST {
			return errors.Errorf("%s already registered", binaryBasename)
		}
		return errors.Errorf("cannot register %q to %s: %s", binaryFullpath, register, err)
	}
	return nil
}

func printStatus() error {
	fis, err := os.ReadDir(mount)
	if err != nil {
		return err
	}
	var emulators []string
	for _, f := range fis {
		if f.Name() == "register" || f.Name() == "status" {
			continue
		}
		dt, err := os.ReadFile(filepath.Join(mount, f.Name()))
		if err != nil {
			return err
		}
		if strings.HasPrefix(string(dt), "enabled") {
			emulators = append(emulators, f.Name())
		}
	}

	out := struct {
		Supported []string `json:"supported"`
		Emulators []string `json:"emulators"`
	}{
		Supported: archutil.SupportedPlatforms(true),
		Emulators: emulators,
	}

	dt, err := json.MarshalIndent(out, "", "  ")
	if err != nil {
		return nil
	}
	fmt.Printf("%s\n", dt)
	return nil
}

func parseArch(in string) (out []string) {
	if in == "" {
		return
	}
	for _, v := range strings.Split(in, ",") {
		p, err := platforms.Parse(v)
		if err != nil {
			out = append(out, v)
		} else {
			out = append(out, p.Architecture)
		}
	}
	return
}

func parseUninstall(in string) (out []string) {
	if in == "" {
		return
	}
	for _, v := range strings.Split(in, ",") {
		if p, err := platforms.Parse(v); err == nil {
			if c, ok := configs[p.Architecture]; ok {
				v = strings.TrimPrefix(c.binary, "qemu-")
			}
		}
		fis, err := filepath.Glob(filepath.Join(mount, v))
		if err != nil || len(fis) == 0 {
			out = append(out, v)
		}
		for _, fi := range fis {
			out = append(out, filepath.Base(fi))
		}
	}
	return
}

func main() {
	log.SetFlags(0) // no timestamps in logs
	flag.Parse()
	if err := run(); err != nil {
		log.Printf("error: %+v", err)
	}
}

func run() error {
	if flVersion {
		log.Printf("binfmt/%s qemu/%s go/%s", revision, qemuVersion, runtime.Version()[2:])
		return nil
	}

	if _, err := os.Stat(filepath.Join(mount, "status")); err != nil {
		if err := syscall.Mount("binfmt_misc", mount, "binfmt_misc", 0, ""); err != nil {
			return errors.Wrapf(err, "cannot mount binfmt_misc filesystem at %s", mount)
		}
		defer syscall.Unmount(mount, 0)
	}

	for _, name := range parseUninstall(toUninstall) {
		err := uninstall(name)
		if err == nil {
			log.Printf("uninstalling: %s OK", name)
		} else {
			log.Printf("uninstalling: %s %v", name, err)
		}
	}

	var installArchs []string
	if toInstall == "all" {
		installArchs = allArch()
	} else {
		installArchs = parseArch(toInstall)
	}

	for _, name := range installArchs {
		err := install(name)
		if err == nil {
			log.Printf("installing: %s OK", name)
		} else {
			log.Printf("installing: %s %v", name, err)
		}
	}

	printStatus()
	return nil
}
