variable "REPO" {
  default = "tonistiigi/binfmt"
}
variable "TAG" {
  default = ""
}

function "gen-tags" {
  params = [flavor, tag]
  result = <<-EOT
    %{ if tag == "" }
      ${flavor},
    %{ endif }
    %{ if flavor == "mainline" && tag != "" }
      ${tag},latest
    %{ endif }
    %{ if flavor != "mainline" && tag != "" }
      ${flavor}-${tag},${flavor}-latest
    %{ endif }
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
  platforms = ["linux/amd64", "linux/arm64", "linux/arm", "linux/ppc64le", "linux/s390x", "linux/riscv64", "linux/386", "linux/mips64le"]
}

target "mainline" {
  args = {
    QEMU_REPO = "https://github.com/qemu/qemu"
    QEMU_VERSION = "v5.2.0"
  }
  tags = formatlist( "${REPO}:%s", compact(split(",", trimspace(gen-tags("mainline", "${TAG}")))))
  cache-to = ["type=inline"]
  cache-from = ["${REPO}:master"]
}

target "mainline-all" {
  inherits = ["mainline", "all-arch"]
}

target "buildkit" {
  args = {
    QEMU_REPO = "https://github.com/tonistiigi/qemu"
    QEMU_VERSION = "be25039802ac0d9ead77960a8c14c1ecdb75ee34"
    BINARY_PREFIX = "buildkit-"
  }
  tags = formatlist("${REPO}:%s", compact(split(",", trimspace(gen-tags("buildkit", "${TAG}")))))
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
