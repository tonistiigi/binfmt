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
  platforms = ["linux/amd64", "linux/arm64", "linux/arm", "linux/ppc64le", "linux/s390x", "linux/riscv64"]
}

target "mainline" {
  args = {
    QEMU_REPO = "https://github.com/qemu/qemu"
    QEMU_VERSION = "v5.0.0"
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
    QEMU_REPO = "https://github.com/tiborvass/qemu"
    QEMU_VERSION = "878126af123e293a0b4fe59dd697e28c86244336"
  }
  tags = [suffix-tag("${REPO}", "buildkit", "${NAME_SUFFIX}")]
  cache-to = ["type=inline"]
  cache-from = ["${REPO}:buildkit-master"]
}

target "buildkit-helper-all" {
  inherits = ["buildkit-helper", "all-arch"]
}