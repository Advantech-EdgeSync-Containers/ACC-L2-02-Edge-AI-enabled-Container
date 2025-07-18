#!/usr/bin/env bash
#
# ONNX Runtime GPU Installation Script
# Purpose: Install NVIDIA-optimized ONNX Runtime for JetPack 5.1.2
# Version: 1.0.0
#

set -euo pipefail

# Constants
readonly CONTAINER_NAME="advantech-l2-02"
readonly ONNX_WHEEL_URL="https://nvidia.box.com/shared/static/iizg3ggrtdkqawkmebbfixo7sce6j365.whl"
readonly ONNX_WHEEL_NAME="onnxruntime_gpu-1.16.0-cp38-cp38-linux_aarch64.whl"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Logging
log() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo -e "${RED}[ERROR] $*${NC}" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS] $*${NC}"; }
log_warning() { echo -e "${YELLOW}[WARN] $*${NC}"; }

# Check if container is running
check_container() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_error "Container '${CONTAINER_NAME}' is not running. Start it with: ./build.sh"
        exit 1
    fi
}

# Execute command in container
exec_container() {
    docker exec "${CONTAINER_NAME}" bash -c "$*"
}

# Main installation
install_onnx_gpu() {
    log "Installing ONNX Runtime GPU for JetPack 5.1.2..."
    
    # Check current status
    if exec_container "python3 -c 'import onnxruntime; print(\"GPU\" if \"CUDAExecutionProvider\" in onnxruntime.get_available_providers() else \"CPU\")' 2>/dev/null" | grep -q "GPU"; then
        log_success "ONNX Runtime GPU is already installed and working"
        exec_container "python3 -c 'import onnxruntime as ort; print(f\"Version: {ort.__version__}\"); print(f\"Providers: {ort.get_available_providers()}\")'"
        return 0
    fi
    
    # Uninstall existing versions
    log "Removing existing ONNX Runtime..."
    exec_container "pip3 uninstall -y onnxruntime onnxruntime-gpu &>/dev/null || true"
    
    # Download and install
    log "Downloading ONNX Runtime GPU wheel..."
    if ! exec_container "cd /tmp && wget -q --show-progress '${ONNX_WHEEL_URL}' -O '${ONNX_WHEEL_NAME}'"; then
        log_error "Failed to download ONNX Runtime wheel"
        exit 1
    fi
    
    log "Installing..."
    if ! exec_container "cd /tmp && pip3 install '${ONNX_WHEEL_NAME}' && rm -f '${ONNX_WHEEL_NAME}'"; then
        log_error "Failed to install ONNX Runtime"
        exit 1
    fi
    
    # Verify GPU support
    log "Verifying GPU support..."
    if exec_container "python3 -c '
import onnxruntime as ort
providers = ort.get_available_providers()
print(f\"Version: {ort.__version__}\")
print(f\"Providers: {providers}\")
if \"CUDAExecutionProvider\" in providers:
    print(\"✓ GPU Support: ENABLED\")
    exit(0)
else:
    print(\"✗ GPU Support: NOT DETECTED\")
    exit(1)
'"; then
        log_success "ONNX Runtime GPU installed successfully!"
    else
        log_error "GPU support verification failed"
        exit 1
    fi
}

# Main execution
main() {
    check_container
    install_onnx_gpu
}

main "$@"