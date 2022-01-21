package tests

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

func init() {
	if v := os.Getenv("BINFMT_ARGV0_TEST"); v != "" {
		fmt.Println(strings.Join(os.Args, ","))
		os.Exit(0)
	}
}

func TestArgv0(t *testing.T) {
	self := "/proc/self/exe"
	if v, ok := os.LookupEnv("REEXEC_NAME"); ok {
		self = v
	}
	cmd := &exec.Cmd{
		Path: self,
		Env:  []string{"BINFMT_ARGV0_TEST=1"},
		Args: []string{"first", "second", "third"},
	}
	out, err := cmd.CombinedOutput()
	require.Equal(t, "first,second,third\n", string(out))
	require.NoError(t, err)
}
