#!/usr/bin/env bash
set -e

echo "::group::Installing k0s"
echo "Starting k0s setup..."

VERSION="${INPUT_VERSION}"
WAIT_FOR_READY="${INPUT_WAIT_FOR_READY}"
TIMEOUT="${INPUT_TIMEOUT}"

echo "Configuration: version=${VERSION}, wait-for-ready=${WAIT_FOR_READY}, timeout=${TIMEOUT}s"

# Detect architecture
ARCH=$(uname -m)
case ${ARCH} in
  x86_64)
    BINARY_ARCH="amd64"
    ;;
  aarch64|arm64)
    BINARY_ARCH="arm64"
    ;;
  armv7l)
    BINARY_ARCH="arm"
    ;;
  *)
    echo "::error::Unsupported architecture: ${ARCH}"
    exit 1
    ;;
esac

echo "Architecture: ${ARCH} -> ${BINARY_ARCH}"

# Resolve version if 'latest'
ACTUAL_VERSION="${VERSION}"
if [ "${VERSION}" = "latest" ]; then
  echo "Resolving latest version..."
  ACTUAL_VERSION=$(curl -sL https://api.github.com/repos/k0sproject/k0s/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
  echo "Latest version: ${ACTUAL_VERSION}"
fi

# Construct download URL
DOWNLOAD_URL="https://github.com/k0sproject/k0s/releases/download/${ACTUAL_VERSION}/k0s-${ACTUAL_VERSION}-${BINARY_ARCH}"
echo "Downloading from: ${DOWNLOAD_URL}"

# Download and install binary
curl -sfL "${DOWNLOAD_URL}" -o /tmp/k0s
sudo install /tmp/k0s /usr/local/bin/k0s
rm -f /tmp/k0s

# Verify installation
echo "Verifying installation..."
k0s version
echo "✓ k0s installed successfully"
echo "::endgroup::"

echo "::group::Starting k0s cluster"
echo "Starting k0s as controller..."

# Install k0s as a controller service
sudo k0s install controller --single

# Start k0s service
sudo k0s start

# Wait for kubeconfig generation
echo "Waiting for kubeconfig generation..."
sleep 10

# Create .kube directory
mkdir -p ~/.kube

# Extract kubeconfig from k0s
echo "Extracting kubeconfig..."
sudo k0s kubeconfig admin > ~/.kube/config
chmod 600 ~/.kube/config

KUBECONFIG_PATH="${HOME}/.kube/config"
echo "kubeconfig=${KUBECONFIG_PATH}" >> $GITHUB_OUTPUT
echo "KUBECONFIG=${KUBECONFIG_PATH}" >> $GITHUB_ENV
echo "KUBECONFIG exported: ${KUBECONFIG_PATH}"
echo "✓ k0s cluster started successfully"
echo "::endgroup::"

# Wait for cluster ready (if requested)
if [ "${WAIT_FOR_READY}" = "true" ]; then
  echo "::group::Waiting for cluster ready"
  echo "Waiting for k0s cluster to be ready (timeout: ${TIMEOUT}s)..."
  
  START_TIME=$(date +%s)
  
  while true; do
    ELAPSED=$(($(date +%s) - START_TIME))
    
    if [ ${ELAPSED} -gt ${TIMEOUT} ]; then
      echo "::error::Timeout waiting for cluster to be ready"
      echo "::group::Diagnostic Information"
      echo "=== k0s Status ==="
      sudo k0s status || true
      echo "=== k0s Controller Logs ==="
      sudo journalctl -u k0scontroller -n 100 --no-pager || true
      echo "=== Kubectl Cluster Info ==="
      kubectl cluster-info || true
      echo "=== Nodes ==="
      kubectl get nodes -o wide || true
      echo "=== Kube-system Pods ==="
      kubectl get pods -n kube-system || true
      echo "::endgroup::"
      exit 1
    fi
    
    # Check k0s status
    if sudo k0s status >/dev/null 2>&1; then
      echo "k0s is running"
      
      # Check if kubectl can connect to API server
      if kubectl cluster-info >/dev/null 2>&1; then
        echo "kubectl can connect to API server"
        
        # Check if all nodes are Ready
        if ! kubectl get nodes --no-headers 2>/dev/null | grep -v " Ready " >/dev/null 2>&1; then
          echo "All nodes are Ready"
          
          # Check if core pods are running
          if ! kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -v "Running\|Completed" >/dev/null 2>&1; then
            echo "All kube-system pods are running"
            break
          else
            echo "Some kube-system pods not running yet"
          fi
        else
          echo "Some nodes not Ready yet"
        fi
      else
        echo "kubectl cannot connect yet"
      fi
    else
      echo "k0s not running yet"
    fi
    
    echo "Cluster not ready yet, waiting... (${ELAPSED}/${TIMEOUT}s)"
    sleep 5
  done
  
  echo "✓ k0s cluster is fully ready!"
  echo "::endgroup::"
fi

echo "✓ k0s setup completed successfully!"
