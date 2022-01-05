package tests

import (
	"errors"
	"os"
	"runtime"
	"strconv"
	"syscall"
	"testing"
	"unsafe"

	"github.com/stretchr/testify/require"
)

var CONFIG_RT_GROUP_SCHED bool = true

func init() {
	runtime.LockOSThread()

	if v := os.Getenv("CONFIG_RT_GROUP_SCHED"); v != "" {
		if vv, err := strconv.ParseBool(v); err == nil {
			CONFIG_RT_GROUP_SCHED = vv
		}
	}
}

func TestGetSetScheduler(t *testing.T) {
	_, err := SchedGetScheduler(1 << 30)
	require.Error(t, err)

	pid := os.Getpid()
	s, err := SchedGetScheduler(pid)
	require.NoError(t, err)
	require.Equal(t, SCHED_NORMAL, s)

	// priority
	err = SchedSetScheduler(pid, SCHED_RR, SchedParam{
		sched_priority: 100,
	})
	require.True(t, errors.Is(err, syscall.EINVAL))

	err = SchedSetScheduler(pid, SCHED_RR, SchedParam{
		sched_priority: 90,
	})
	require.True(t, !errors.Is(err, syscall.EINVAL))

	if CONFIG_RT_GROUP_SCHED {
		t.Logf("skipping scheduler set checks")
	} else {
		require.NoError(t, err)

		s, err := SchedGetScheduler(pid)
		require.NoError(t, err)
		require.Equal(t, SCHED_RR, s)

		p, err := SchedGetParam(pid)
		require.NoError(t, err)
		require.Equal(t, 90, int(p.sched_priority))
	}

	err = SchedSetScheduler(pid, SCHED_IDLE, SchedParam{})
	require.NoError(t, err)

	s, err = SchedGetScheduler(pid)
	require.NoError(t, err)
	require.Equal(t, SCHED_IDLE, s)

	err = SchedSetScheduler(pid, SCHED_NORMAL, SchedParam{})
	require.NoError(t, err)
}

func TestSchedMinMax(t *testing.T) {
	p, err := SchedGetPriorityMin(SCHED_RR)
	require.NoError(t, err)
	require.Equal(t, 1, p)

	p, err = SchedGetPriorityMax(SCHED_RR)
	require.NoError(t, err)
	require.Equal(t, 99, p)

	p, err = SchedGetPriorityMax(SCHED_BATCH)
	require.NoError(t, err)
	require.Equal(t, 0, p)
}

func TestSchedYield(t *testing.T) {
	err := SchedYield()
	require.NoError(t, err)
}

func TestSchedGetSetParam(t *testing.T) {
	pid := os.Getpid()

	p, err := SchedGetParam(pid)
	require.NoError(t, err)

	require.Equal(t, 0, int(p.sched_priority))

	err = SchedSetParam(pid, SchedParam{})
	require.NoError(t, err)

	if CONFIG_RT_GROUP_SCHED {
		t.Logf("skipping setting sched_priority")
	} else {
		err = SchedSetScheduler(pid, SCHED_RR, SchedParam{sched_priority: 50})
		require.NoError(t, err)

		p, err := SchedGetParam(pid)
		require.NoError(t, err)

		require.Equal(t, 50, int(p.sched_priority))
	}
}

func TestSchedAttr(t *testing.T) {
	pid := os.Getpid()

	if !CONFIG_RT_GROUP_SCHED {
		err := SchedSetScheduler(pid, SCHED_RR, SchedParam{sched_priority: 50})
		require.NoError(t, err)
	}

	attr, err := SchedGetAttr(pid)
	require.NoError(t, err)

	require.True(t, attr.Size >= 0x30)

	if CONFIG_RT_GROUP_SCHED {
		require.Equal(t, SCHED_NORMAL, attr.SchedPolicy)

		attr := SchedAttr{SchedPolicy: SCHED_IDLE}
		err := SchedSetAttr(pid, attr, 0)
		require.NoError(t, err)

		attr, err = SchedGetAttr(pid)
		require.NoError(t, err)
		require.Equal(t, SCHED_IDLE, attr.SchedPolicy)

		t.Logf("skipping setting attr priority")
	} else {
		require.Equal(t, SCHED_RR, attr.SchedPolicy)
		require.Equal(t, 50, int(attr.SchedPriority))

		attr := SchedAttr{SchedPolicy: SCHED_RR, SchedPriority: 60}
		err := SchedSetAttr(pid, attr, 0)
		require.NoError(t, err)

		attr, err = SchedGetAttr(pid)
		require.NoError(t, err)
		require.Equal(t, SCHED_RR, attr.SchedPolicy)
		require.Equal(t, 60, int(attr.SchedPriority))
	}
}

func TestSchedAttrSize(t *testing.T) {
	pid := os.Getpid()

	dt := make([]byte, 2)
	ptr := unsafe.Pointer(&dt[0])
	err := schedSetAttr(pid, ptr, 0)
	require.Error(t, err)
	t.Logf("short read error: %v", err) // this error does not look consistent even with no emulation

	dt = make([]byte, 80)
	ptr = unsafe.Pointer(&dt[0])

	err = schedSetAttr(pid, ptr, 0)
	require.NoError(t, err) // empty size is ok for some reason

	ints := (*[20]uint32)(ptr)
	ints[0] = 8 // too small size

	err = schedSetAttr(pid, ptr, 0)
	require.Error(t, err)
	require.True(t, errors.Is(err, syscall.E2BIG))
	require.Equal(t, uint32(0x38), ints[0]) // expecting kernel 5.3+

	ints[0] = 80 // too big but empty contents is ok
	err = schedSetAttr(pid, ptr, 0)
	require.NoError(t, err)

	ints[18] = 0xff // too big and not empty

	err = schedSetAttr(pid, ptr, 0)
	require.Error(t, err)
	require.True(t, errors.Is(err, syscall.E2BIG))
	require.Equal(t, uint32(0x38), ints[0]) // expecting kernel 5.3+

	runtime.KeepAlive(dt)
}
