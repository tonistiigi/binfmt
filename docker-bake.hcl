variable "REPO" {
  default = "tonistiigi/binfmt"
}
variable "NAME_SUFFIX" {
  default = ""
}

function "suffix-tag" {
  params = [name, tag, suffix]
  result = "${name}:${"${suffix}"==""?"${tag}":"${"${tag}"=="latest"?"${suffix}":"${tag}-${suffix}"}"}"
}

group "default" {
  targets = ["binaries"]
}

target "binaries" {
  output = ["./bin"]
  platforms = ["local"]
  target = "binaries"
}

target "all-arch" {
  platforms = ["linux/amd64", "linux/arm64", "linux/arm", "linux/ppc64le", "linux/s390x", "linux/riscv64", "linux/386"]
}

target "mainline" {
  args = {
    QEMU_REPO = "https://github.com/qemu/qemu"
    QEMU_VERSION = "v5.2.0"
  }
  tags = [suffix-tag("${REPO}", "latest", "${NAME_SUFFIX}")]
  cache-to = ["type=inline"]
  cache-from = ["${REPO}:master"]
}

target "mainline-all" {
  inherits = ["mainline", "all-arch"]
}

target "buildkit-helper" {
  args = {
    QEMU_REPO = "https://github.com/tonistiigi/qemu"
    QEMU_VERSION = "be25039802ac0d9ead77960a8c14c1ecdb75ee34"
    BINARY_PREFIX = "buildkit-"
  }
  tags = [suffix-tag("${REPO}", "buildkit", "${NAME_SUFFIX}")]
  cache-to = ["type=inline"]
  cache-from = ["${REPO}:buildkit-master"]
  target = "binaries"
}

target "buildkit-helper-all" {
  inherits = ["buildkit-helper", "all-arch"]
}

target "buildkit-test" {
  inherits = ["buildkit-helper"]
  target = "buildkit-test"
  cache-to = []
  tags = []
}
