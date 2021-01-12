#!/usr/bin/env bats

load "assert"

exec0() {
  if [ -z "$BINFMT_EMULATOR" ]; then
    run ./execargv0 "$@"
  else 
    run buildkit-qemu-$BINFMT_EMULATOR ./execargv0 "$@"
  fi
}

execdirect() {
  if [ -z "$BINFMT_EMULATOR" ]; then
    run "$@"
  else 
    run buildkit-qemu-$BINFMT_EMULATOR "$@"
  fi
}


@test "exec-single" {
  exec0 ./printargs foo bar1 bar2
  assert_success
  assert_output "foo bar1 bar2"
}

@test "exec-multi" {
  exec0 ./execargv0 ./printargs ./printargs baz
  assert_success
  assert_output "baz"
}

@test "exec-multi-abs" {
  exec0 ./execargv0 $(pwd)/printargs $(pwd)/printargs baz
  assert_success
  assert_output "baz"
}

@test "exec-multi-path" {
  cp $(pwd)/printargs /usr/bin/test-printargs
  exec0 test-printargs test-printargs abc
  assert_success
  assert_output "test-printargs abc"
}

@test "exec-direct" {
  execdirect test-printargs foo bar1
  assert_success
  assert_output "test-printargs foo bar1"
}

@test "exec-direct-abs" {
  execdirect $(pwd)/printargs foo bar1
  assert_success
  assert_output "$(pwd)/printargs foo bar1"
}

@test "shebang" {
  exec0 ./shebang.sh arg1 arg2
  assert_success
  assert_output "./printargs $(pwd)/shebang.sh arg2"
}

@test "shebang-arg" {
  exec0 ./shebang2.sh arg1 arg2
  assert_success
  assert_output "./printargs arg $(pwd)/shebang2.sh arg2"
}

@test "shebang-abs" {
  exec0 ./shebang3.sh arg1 arg2
  assert_success
  assert_output "/work/printargs $(pwd)/shebang3.sh arg2"
}

@test "shebang-multi" {
  exec0 ./shebang4.sh arg1 arg2
  assert_success
  assert_output "/work/printargs $(pwd)/shebang3.sh $(pwd)/shebang4.sh arg2"
}

@test "shebang-direct" {
  execdirect ./shebang.sh foo bar1
  assert_success
  assert_output "./printargs ./shebang.sh foo bar1"
}
