package tests

import (
	"syscall"
	"unsafe"

	"golang.org/x/sys/unix"
)

// #include <linux/sched.h>
// #include <linux/sched/types.h>
// typedef struct sched_param sched_param;
import "C"

type Policy uint32

const (
	SCHED_NORMAL   Policy = C.SCHED_NORMAL
	SCHED_FIFO     Policy = C.SCHED_FIFO
	SCHED_RR       Policy = C.SCHED_RR
	SCHED_BATCH    Policy = C.SCHED_BATCH
	SCHED_IDLE     Policy = C.SCHED_IDLE
	SCHED_DEADLINE Policy = C.SCHED_DEADLINE
)

type SchedFlag int

const (
	SCHED_FLAG_RESET_ON_FORK SchedFlag = C.SCHED_FLAG_RESET_ON_FORK
	SCHED_FLAG_RECLAIM       SchedFlag = C.SCHED_FLAG_RECLAIM
	SCHED_FLAG_DL_OVERRUN    SchedFlag = C.SCHED_FLAG_DL_OVERRUN
)

type SchedParam C.sched_param

func SchedGetScheduler(pid int) (Policy, error) {
	r0, _, e1 := unix.Syscall(unix.SYS_SCHED_GETSCHEDULER, uintptr(pid), 0, 0)
	if e1 != 0 {
		return 0, syscall.Errno(e1)
	}
	return Policy(r0), nil
}

func SchedSetScheduler(pid int, p Policy, param SchedParam) error {
	_, _, e1 := unix.Syscall(unix.SYS_SCHED_SETSCHEDULER, uintptr(pid), uintptr(p), uintptr(unsafe.Pointer(&param)))
	if e1 != 0 {
		return syscall.Errno(e1)
	}
	return nil
}

func SchedGetPriorityMin(p Policy) (int, error) {
	r0, _, e1 := unix.Syscall(unix.SYS_SCHED_GET_PRIORITY_MIN, uintptr(p), 0, 0)
	if e1 != 0 {
		return 0, syscall.Errno(e1)
	}
	return int(r0), nil
}

func SchedGetPriorityMax(p Policy) (int, error) {
	r0, _, e1 := unix.Syscall(unix.SYS_SCHED_GET_PRIORITY_MAX, uintptr(p), 0, 0)
	if e1 != 0 {
		return 0, syscall.Errno(e1)
	}
	return int(r0), nil
}

func SchedYield() error {
	_, _, e1 := unix.Syscall(unix.SYS_SCHED_YIELD, 0, 0, 0)
	if e1 != 0 {
		return syscall.Errno(e1)
	}
	return nil
}

func SchedGetParam(pid int) (SchedParam, error) {
	var param SchedParam
	_, _, e1 := unix.Syscall(unix.SYS_SCHED_GETPARAM, uintptr(pid), uintptr(unsafe.Pointer(&param)), 0)
	if e1 != 0 {
		return param, syscall.Errno(e1)
	}
	return param, nil
}

func SchedSetParam(pid int, param SchedParam) error {
	_, _, e1 := unix.Syscall(unix.SYS_SCHED_SETPARAM, uintptr(pid), uintptr(unsafe.Pointer(&param)), 0)
	if e1 != 0 {
		return syscall.Errno(e1)
	}
	return nil
}

type SchedAttr struct {
	Size          uint32
	SchedPolicy   Policy
	SchedFlags    uint64
	SchedNice     uint32
	SchedPriority uint32
	SchedRuntime  uint64
	SchedDeadline uint64
	SchedPeriod   uint64
	SchedUtilMin  uint32
	SchedUtilMax  uint32
}

func SchedGetAttr(pid int) (SchedAttr, error) {
	var attr SchedAttr
	_, _, e1 := unix.Syscall6(unix.SYS_SCHED_GETATTR, uintptr(pid), uintptr(unsafe.Pointer(&attr)), unsafe.Sizeof(SchedAttr{}), 0, 0, 0)
	if e1 != 0 {
		return attr, syscall.Errno(e1)
	}
	return attr, nil
}

func SchedSetAttr(pid int, attr SchedAttr, flags SchedFlag) error {
	attr.Size = uint32(unsafe.Sizeof(attr))
	_, _, e1 := unix.Syscall(unix.SYS_SCHED_SETATTR, uintptr(pid), uintptr(unsafe.Pointer(&attr)), uintptr(flags))
	if e1 != 0 {
		return syscall.Errno(e1)
	}
	return nil
}
