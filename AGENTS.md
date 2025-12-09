# AGENTS.md

This file provides comprehensive documentation about the setup-k0s GitHub Action for AI agents and developers working with this codebase.

## Project Overview

**setup-k0s** is a GitHub Action that installs and configures k0s - Zero Friction Kubernetes. The action is implemented as a simple bash composite action with no external dependencies.

### Key Features
- Automatic installation of k0s with version selection
- Single-node controller setup for CI/CD pipelines
- Cluster readiness checks with configurable timeout
- Outputs kubeconfig path for easy integration with kubectl
- Simple bash implementation with no build step required

## Architecture

The action uses GitHub Actions' **composite** run type, which allows it to execute shell scripts directly without requiring Node.js or any compilation step.

### Execution Flow

```
Install k0s → Start k0s → Wait for Cluster Ready (optional)
```

**Install k0s**
- Detects system architecture (amd64/arm64/arm)
- Resolves 'latest' version or uses specified version from GitHub releases
- Downloads k0s binary from GitHub releases
- Installs binary to `/usr/local/bin/k0s`
- Location: `action.yml:33-82`

**Start k0s**
- Installs k0s as a controller service with `--single` flag
- Starts k0s service
- Waits for kubeconfig generation (10 second sleep)
- Extracts kubeconfig from k0s and writes to `~/.kube/config`
- Sets KUBECONFIG output and environment variable
- Location: `action.yml:84-108`

**Wait for Cluster Ready** (optional)
- Polls for cluster readiness with configurable timeout
- Checks: k0s status → kubectl connects → nodes Ready → kube-system pods running
- Shows diagnostics if timeout occurs
- Location: `action.yml:110-182`

## File Structure

```
setup-k0s/
├── action.yml           # Complete action definition and bash implementation
├── README.md            # User-facing documentation
├── AGENTS.md            # This file
├── LICENSE              # MIT License
└── CHANGELOG.md         # Version history
```

## Key Technical Details

### Action Configuration (action.yml)

**Inputs:**
- `version` (default: 'latest'): k0s version to install (e.g., "v1.30.0+k0s.0")
- `wait-for-ready` (default: 'true'): Wait for cluster readiness
- `timeout` (default: '300'): Timeout in seconds for readiness check

**Outputs:**
- `kubeconfig`: Path to kubeconfig file (`~/.kube/config`)

**Runtime:**
- Composite action using bash shell
- No build step required
- No external dependencies

### Dependencies

**None!** This action has no dependencies. It uses only:
- Standard bash shell commands
- `curl` for downloading k0s
- `kubectl` (installed by k0s itself)

## Common Modification Scenarios

### Adding New Configuration Options

1. Add input to `action.yml`:
```yaml
inputs:
  new-option:
    description: 'Description of the new option'
    required: false
    default: 'default-value'
```

2. Use the input in the bash script section:
```bash
NEW_OPTION="${{ inputs.new-option }}"
```

3. Update README.md documentation

### Modifying Installation Logic

The installation logic is in `action.yml:33-82`. Key areas:
- Architecture detection: lines 41-57
- Version resolution: lines 61-68
- Binary download and installation: lines 70-78

### Adjusting Cluster Startup

The startup logic is in `action.yml:84-108`. You can modify:
- Installation flags: line 92 (`--single` flag can be changed for different topologies)
- Wait time for kubeconfig: line 99 (currently 10 seconds)
- Kubeconfig location: line 102 (currently `~/.kube/config`)

### Customizing Readiness Checks

The readiness check logic is in `action.yml:110-182`. You can:
- Change polling interval: line 175 (currently 5 seconds)
- Modify readiness conditions: lines 147-167
- Add/remove diagnostic commands: lines 135-145

## Testing Strategy

### Local Testing
You can test the bash script locally by copying the shell commands from `action.yml` and running them with appropriate variable substitutions:

```bash
export VERSION="latest"
export WAIT_FOR_READY="true"
export TIMEOUT="300"

# Then run the commands from action.yml
```

### Testing in GitHub Actions
Create a workflow in `.github/workflows/test.yml`:

```yaml
name: Test Action
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./
        with:
          version: 'latest'
          wait-for-ready: 'true'
          timeout: '300'
      - name: Test kubectl
        run: kubectl get nodes
```

### Testing Checklist
**Setup Phase:**
- [ ] k0s installs successfully for different versions
- [ ] Works on different architectures (amd64, arm64)
- [ ] Cluster becomes ready within timeout
- [ ] kubectl can connect and list nodes
- [ ] kubeconfig output is set correctly
- [ ] KUBECONFIG environment variable is exported

## System Requirements

- **OS:** Linux (tested on ubuntu-latest in GitHub Actions)
- **Permissions:** sudo access (available by default in GitHub Actions)
- **Network:** Internet access to download k0s releases
- **Pre-installed tools:** bash, curl, sudo

## Debugging

### Enable Debug Logging
Set repository secret: `ACTIONS_STEP_DEBUG = true`

### Key Log Messages
- "Starting k0s setup..." - Setup begins
- "✓ k0s installed successfully" - Installation complete
- "✓ k0s cluster started successfully" - Cluster started
- "✓ k0s cluster is fully ready!" - Cluster ready
- "✓ k0s setup completed successfully!" - Complete

### Diagnostic Information
When cluster readiness times out, diagnostics are automatically displayed:
- k0s status
- k0scontroller journal logs (last 100 lines)
- Kubectl cluster info
- Nodes status
- Kube-system pods

### Common Issues

**Issue:** "Timeout waiting for cluster to be ready"
- Check the diagnostic logs printed automatically
- Ensure the runner has sufficient resources
- Consider increasing the timeout value

**Issue:** "Unsupported architecture"
- Currently supports: x86_64 (amd64), aarch64/arm64, armv7l (arm)
- Check if k0s releases support your architecture

**Issue:** "Failed to download k0s"
- Check network connectivity
- Verify the version exists in GitHub releases
- Check if rate limiting is affecting the download

## Related Resources

- **k0s Project**: https://k0sproject.io/
- **k0s GitHub**: https://github.com/k0sproject/k0s
- **GitHub Actions Documentation**: https://docs.github.com/actions
- **Composite Actions Guide**: https://docs.github.com/actions/creating-actions/creating-a-composite-action

## Contributing

### Development Workflow
1. Make changes to `action.yml`
2. Test locally or in a GitHub Actions workflow
3. Update README.md if adding/changing inputs or outputs
4. Update CHANGELOG.md with your changes
5. Create pull request

### Release Process
Releases are managed via tags following semantic versioning (e.g., v1.0.0).

To create a new release:
1. Update CHANGELOG.md
2. Create and push a new tag: `git tag v1.x.x && git push origin v1.x.x`
3. Create a GitHub release from the tag

### Code Style
- Use 2-space indentation for YAML
- Use 2-space indentation for bash
- Add comments for complex logic
- Keep error messages clear and actionable
- Use `set -e` to fail fast on errors
