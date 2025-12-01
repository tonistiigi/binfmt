variable "REPO_SLUG" {
  default = "tonistiigi/binfmt"
}
variable "QEMU_REPO" {
  default = "https://github.com/qemu/qemu"
}
variable "QEMU_VERSION" {
  default = "v10.0.4"
}
variable "QEMU_PATCHES" {
  default = "cpu-max-arm"
}

// Special target: https://github.com/docker/metadata-action#bake-definition
target "meta-helper" {
  tags = ["${REPO_SLUG}:test"]
}

target "_common" {
  args = {
    BUILDKIT_CONTEXT_KEEP_GIT_DIR = 1
  }
}

group "default" {
  targets = ["binaries"]
}

target "binaries" {
  inherits = ["_common"]
  output = ["./bin"]
  platforms = ["local"]
  target = "binaries"
}

target "all-arch" {
  platforms = [
    "linux/amd64",
    "linux/arm64",
    "linux/arm/v6",
    "linux/arm/v7",
    "linux/ppc64le",
    "linux/s390x",
    "linux/riscv64",
    "linux/386",
  ]
}

target "mainline" {
  inherits = ["meta-helper", "_common"]
  args = {
    QEMU_REPO = QEMU_REPO
    QEMU_VERSION = QEMU_VERSION
    QEMU_PATCHES = QEMU_PATCHES
    QEMU_PRESERVE_ARGV0 = "1"
  }
  cache-to = ["type=inline"]
  cache-from = ["${REPO_SLUG}:master"]
}

target "mainline-all" {
  inherits = ["mainline", "all-arch"]
}

target "buildkit" {
  inherits = ["mainline"]
  args = {
    BINARY_PREFIX = "buildkit-"
    QEMU_PATCHES = "${QEMU_PATCHES},buildkit-direct-execve-v10.0"
    QEMU_PRESERVE_ARGV0 = ""
  }
  cache-from = ["${REPO_SLUG}:buildkit-master"]
  target = "binaries"
}

target "buildkit-all" {
  inherits = ["buildkit", "all-arch"]
}

target "buildkit-test" {
  inherits = ["buildkit"]
  target = "buildkit-test"
  cache-to = []
  tags = []
}

target "desktop" {
  inherits = ["mainline"]
  args = {
    QEMU_PATCHES = "${QEMU_PATCHES},pretcode"
  }
  cache-from = ["${REPO_SLUG}:desktop-master"]
}

target "desktop-all" {
  inherits = ["desktop", "all-arch"]
}

target "archive" {
  inherits = ["mainline"]
  target = "archive"
  output = ["./bin"]
}

target "archive-all" {
  inherits = ["archive", "all-arch"]
}
