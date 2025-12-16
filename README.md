# Setup k0s Action

A GitHub Action for installing and configuring [k0s](https://k0sproject.io/) - Zero Friction Kubernetes. k0s is a lightweight, CNCF-certified Kubernetes distribution that's easy to install and maintain.

## Features

- ✅ Automatic installation of k0s
- ✅ Single-node controller setup
- ✅ Configurable version
- ✅ Waits for cluster readiness
- ✅ Outputs kubeconfig path for easy integration
- ✅ No cleanup required - designed for ephemeral GitHub Actions runners

## Quick Start

```yaml
name: Test with k0s

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup k0s
        id: k0s
        uses: fenio/setup-k0s@v2
      
      - name: Deploy and test
        run: |
          kubectl apply -f k8s/
          kubectl wait --for=condition=available --timeout=60s deployment/my-app
```

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `version` | k0s version to install (e.g., `v1.30.0+k0s.0`) or `latest` | `latest` |
| `wait-for-ready` | Wait for cluster to be ready before completing | `true` |
| `timeout` | Timeout in seconds to wait for cluster readiness | `120` |
| `dns-readiness` | Wait for CoreDNS to be ready and verify DNS resolution works | `true` |

## Outputs

| Output | Description |
|--------|-------------|
| `kubeconfig` | Path to the kubeconfig file (typically `~/.kube/config`) |

## Usage Examples

### Basic Usage with Latest Version

```yaml
- name: Setup k0s
  uses: fenio/setup-k0s@v2
```

### Specific Version

```yaml
- name: Setup k0s
  uses: fenio/setup-k0s@v2
  with:
    version: 'v1.30.0+k0s.0'
```

### Custom Timeout

```yaml
- name: Setup k0s
  uses: fenio/setup-k0s@v2
  with:
    timeout: '600'  # 10 minutes
```

## How It Works

1. Installs the k0s binary for your platform
2. Installs k0s as a single-node controller using systemd
3. Starts the k0s service
4. Extracts and configures kubectl with the admin kubeconfig
5. Waits for the cluster to become ready (if `wait-for-ready` is enabled)

**No cleanup needed** - GitHub Actions runners are ephemeral and destroyed after each workflow run, so there's no need to restore system state.

## Requirements

- Runs on `ubuntu-latest` (or any Linux-based runner)
- Requires `sudo` access (provided by default in GitHub Actions)
- Requires systemd for service management

## Troubleshooting

### Cluster Not Ready

If the cluster doesn't become ready in time, increase the timeout:

```yaml
- name: Setup k0s
  uses: fenio/setup-k0s@v2
  with:
    timeout: '600'  # 10 minutes
```

### Check k0s Status

You can add a step to check the k0s status:

```yaml
- name: Check k0s Status
  run: |
    sudo k0s status
    kubectl get nodes
    kubectl get pods -A
```

## Development

This action is implemented as a pure bash script (`setup.sh`) with no build step required.

### Testing

To test changes locally:

1. Fork and clone the repository
2. Make your changes to `action.yml` or `setup.sh`
3. Create a test workflow that uses your local action (`uses: ./`)
4. Push to your fork and verify the workflow runs successfully

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Related Projects

- [k0s](https://k0sproject.io/) - Zero Friction Kubernetes

### Other Kubernetes Setup Actions

- [setup-k3s](https://github.com/fenio/setup-k3s) - Lightweight Kubernetes (k3s)
- [setup-kubesolo](https://github.com/fenio/setup-kubesolo) - Ultra-lightweight Kubernetes
- [setup-microk8s](https://github.com/fenio/setup-microk8s) - Lightweight Kubernetes by Canonical
- [setup-minikube](https://github.com/fenio/setup-minikube) - Local Kubernetes (Minikube)
- [setup-talos](https://github.com/fenio/setup-talos) - Secure, immutable Kubernetes OS (Talos)
