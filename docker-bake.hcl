variable "REPO" {
  default = "tonistiigi/binfmt"
}
variable "QEMU_REPO" {
  default = ""
}
variable "QEMU_VERSION" {
  default = ""
}

// Special target: https://github.com/crazy-max/ghaction-docker-meta#bake-definition
target "meta-helper" {
  tags = ["${REPO}:test"]
}

function "getdef" {
  params = [val, default]
  result = <<-EOT
    %{ if val != "" }${val}%{ else }${default}%{ endif }
  EOT
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
  platforms = [
    "linux/amd64",
    "linux/arm64",
    "linux/arm",
    "linux/ppc64le",
    "linux/s390x",
    "linux/riscv64",
    "linux/386",
    "linux/mips64le"
  ]
}

target "mainline" {
  inherits = ["meta-helper"]
  args = {
    QEMU_REPO = trimspace(getdef("${QEMU_REPO}", "https://github.com/qemu/qemu"))
    QEMU_VERSION = trimspace(getdef("${QEMU_VERSION}", "v6.0.0"))
  }
  cache-to = ["type=inline"]
  cache-from = ["${REPO}:master"]
}

target "mainline-all" {
  inherits = ["mainline", "all-arch"]
}

target "buildkit" {
  inherits = ["meta-helper"]
  args = {
    QEMU_REPO = trimspace(getdef("${QEMU_REPO}", "https://github.com/tonistiigi/qemu"))
    QEMU_VERSION = trimspace(getdef("${QEMU_VERSION}", "be25039802ac0d9ead77960a8c14c1ecdb75ee34"))
    BINARY_PREFIX = "buildkit-"
  }
  cache-to = ["type=inline"]
  cache-from = ["${REPO}:buildkit-master"]
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

target "archive" {
  inherits = ["mainline"]
  target = "archive"
  output = ["./bin"]
}

target "archive-all" {
  inherits = ["archive", "all-arch"]
}