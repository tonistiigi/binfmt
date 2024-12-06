# binfmt

Cross-platform emulator collection

# Usage

Install and uninstall using Helm.

For example, prepare all nodes for `arm64` emulation by running
```sh
helm install --wait binfmt-arm64 charts/binfmt --set formats=arm64
helm uninstall
```

# Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| formats | string | `"all"` | a comma-separated list of [architecture formats](https://github.com/tonistiigi/binfmt) to enable or "all" |
| | | | |
| nameOverride | string | `""` | alternative to default chart name |
| fullnameOverride | string | `""` | alternative to default fully qualified app name |
| podAnnotations | object | `{}` | annotations for the pod |
| resources | object | `{"limits": {"memory": "128Mi"}, "requests": {"cpu": "100m", "memory": "128Mi"}}` | resource definition for the pod |
| nodeSelector | object | `{}` | selector that limits deployment to matching nodes |
| tolerations | list | `[]` | tolerations (list of taint match definitions) for the pod |
| affinity | object | `{}` | scheduling constraints for the pod |
