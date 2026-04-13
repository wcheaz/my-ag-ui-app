#!/bin/bash

################################################################################
# Kubernetes Deployment Setup Script
#
# This script automates the manual deployment steps that are part of the
# human handoff process in the fix-k8s-agent-streaming workflow. It performs
# a complete end-to-end deployment of Docker images to a Kubernetes cluster
# running in a Multipass VM.
#
# Purpose:
# - After making code changes to the frontend (my-ag-ui-app) or agent,
#   this script rebuilds the Docker images and deploys them to production
# - Eliminates the need to manually run multiple commands across the host
#   and VM during the deployment process
#
# What the script does:
# 1. Pre-flight validation: Checks that VM exists, Docker is accessible
# 2. Build phase: Builds Docker images (frontend, agent, or both)
# 3. Transfer phase: Saves images to tar files, transfers to VM, loads them
# 4. Registry phase: Tags and pushes images to local registry (localhost:32000)
# 5. Manifest phase: Applies updated Kubernetes manifests if specified
# 6. Restart phase: Restarts affected deployments to pick up new images
# 7. Verification phase: Runs verification script to test the deployment
# 8. Cleanup: Removes temporary tar files from host and VM
#
# When to use this script:
# - After implementing SSE streaming fixes in the frontend or agent code
# - After updating Kubernetes manifests (ingress.yaml, deployment.yaml, etc.)
# - Any time you need to deploy updated Docker images to the K8s cluster
#
# Related files:
# - openspec/changes/fix-k8s-agent-streaming/tasks.md (original manual steps)
# - k8s/*.yaml (Kubernetes manifests)
# - test/verify_k8s_sse_fix.sh (verification script)
#
# Usage examples:
#   scripts/kubernetes-deployment-setup.sh --build all --manifest k8s/ingress.yaml --restart --verify
#   scripts/kubernetes-deployment-setup.sh --build frontend --manifest k8s/deployment.yaml --restart
#
# Environment variables:
#   VM_NAME: Name of the Multipass VM (default: my-ag-ui-app-k8s)
################################################################################

set -e

# Configuration
VM_NAME="${VM_NAME:-my-ag-ui-app-k8s}"
REGISTRY="localhost:32000"
FRONTEND_IMAGE_NAME="my-ag-ui-app"
AGENT_IMAGE_NAME="agent"
FRONTEND_DEPLOYMENT="my-ag-ui-app"
AGENT_DEPLOYMENT="agent"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -b, --build BUILD_TYPE     What to build: frontend, agent, or all (default: all)"
    echo "  -m, --manifest FILE        K8s manifest to apply (can be specified multiple times)"
    echo "  -r, --restart              Restart deployments after applying manifests"
    echo "  -v, --verify               Run verification script after deployment"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  VM_NAME                    Name of the Multipass VM (default: my-ag-ui-app-k8s)"
    echo ""
    echo "Examples:"
    echo "  $0 --build all --manifest k8s/ingress.yaml --restart --verify"
    echo "  $0 --build frontend --manifest k8s/deployment.yaml --restart"
    exit 1
}

# Parse arguments
BUILD_TYPE="all"
MANIFESTS=()
RESTART_DEPLOYMENTS=false
RUN_VERIFICATION=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--build)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -m|--manifest)
            MANIFESTS+=("$2")
            shift 2
            ;;
        -r|--restart)
            RESTART_DEPLOYMENTS=true
            shift
            ;;
        -v|--verify)
            RUN_VERIFICATION=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate build type
if [[ "$BUILD_TYPE" != "frontend" && "$BUILD_TYPE" != "agent" && "$BUILD_TYPE" != "all" ]]; then
    log_error "Invalid build type: $BUILD_TYPE. Must be frontend, agent, or all"
    exit 1
fi

log_info "Starting Kubernetes deployment setup"
log_info "VM: $VM_NAME"
log_info "Build type: $BUILD_TYPE"

# Pre-flight checks
log_info "Running pre-flight checks..."

# Check if VM exists
if ! multipass list | grep -q "$VM_NAME"; then
    log_error "VM '$VM_NAME' not found. Please create the VM first."
    exit 1
fi

# Check if Docker is accessible
if ! docker info >/dev/null 2>&1; then
    log_error "Docker daemon is not accessible. Start Docker daemon: sudo systemctl start docker"
    exit 1
fi

# Check if Docker in VM is accessible
if ! multipass exec "$VM_NAME" -- docker info >/dev/null 2>&1; then
    log_error "Docker daemon not accessible in VM. Cannot transfer images."
    exit 1
fi

log_info "✅ Pre-flight checks passed"

# Function to build and transfer image
build_and_transfer_image() {
    local image_name="$1"
    local build_context="$2"
    local dockerfile_path="${3:-Dockerfile}"
    
    log_info "Building $image_name:latest..."
    
    # Build image
    if ! docker build -t "$image_name:latest" -f "$dockerfile_path" "$build_context"; then
        log_error "Failed to build $image_name:latest"
        return 1
    fi
    
    log_info "✅ $image_name:latest built successfully"
    
    # Get image ID
    IMAGE_ID=$(docker images "$image_name:latest" --format "{{.ID}}" 2>/dev/null | head -n1)
    if [ -z "$IMAGE_ID" ]; then
        log_error "Cannot find image ID for $image_name:latest"
        return 1
    fi
    log_info "Image ID: $IMAGE_ID"
    
    # Save image to tar
    TAR_FILE="./${image_name}.tar"
    log_info "Saving image to $TAR_FILE..."
    if ! docker save "$IMAGE_ID" -o "$TAR_FILE"; then
        log_error "Failed to save $image_name image"
        return 1
    fi
    
    log_info "✅ Image saved to $TAR_FILE ($(ls -lh "$TAR_FILE" | awk '{print $5}'))"
    
    # Transfer to VM
    log_info "Transferring $TAR_FILE to VM..."
    if ! multipass transfer "$TAR_FILE" "$VM_NAME:/tmp/"; then
        log_error "Failed to transfer $TAR_FILE to VM"
        rm -f "$TAR_FILE"
        return 1
    fi
    
    log_info "✅ Image transferred to VM"
    
    # Load image in VM
    log_info "Loading image in VM..."
    load_output=$(multipass exec "$VM_NAME" -- docker load -i "/tmp/${image_name}.tar" 2>&1)
    if [ $? -ne 0 ]; then
        log_error "Failed to load $image_name image in VM"
        multipass exec "$VM_NAME" -- rm -f "/tmp/${image_name}.tar"
        rm -f "$TAR_FILE"
        return 1
    fi
    
    log_info "✅ Image loaded in VM"
    
    # Extract image ID from load output
    VM_IMAGE_ID=$(echo "$load_output" | grep -o 'sha256:[a-f0-9]\+')
    if [ -z "$VM_IMAGE_ID" ]; then
        log_error "Could not extract image ID from load output"
        multipass exec "$VM_NAME" -- rm -f "/tmp/${image_name}.tar"
        rm -f "$TAR_FILE"
        return 1
    fi
    
    # Tag and push to registry
    TARGET_IMAGE="${REGISTRY}/${image_name}:latest"
    log_info "Tagging image as $TARGET_IMAGE..."
    if ! multipass exec "$VM_NAME" -- docker tag "$VM_IMAGE_ID" "$TARGET_IMAGE"; then
        log_error "Failed to tag $image_name image"
        multipass exec "$VM_NAME" -- rm -f "/tmp/${image_name}.tar"
        rm -f "$TAR_FILE"
        return 1
    fi
    
    log_info "Pushing image to registry..."
    if ! multipass exec "$VM_NAME" -- docker push "$TARGET_IMAGE"; then
        log_error "Failed to push $image_name image to registry"
        multipass exec "$VM_NAME" -- rm -f "/tmp/${image_name}.tar"
        rm -f "$TAR_FILE"
        return 1
    fi
    
    log_info "✅ $image_name successfully pushed to $TARGET_IMAGE"
    
    # Cleanup
    rm -f "$TAR_FILE"
    multipass exec "$VM_NAME" -- rm -f "/tmp/${image_name}.tar"
}

# Build and transfer images based on build type
if [[ "$BUILD_TYPE" == "frontend" || "$BUILD_TYPE" == "all" ]]; then
    build_and_transfer_image "$FRONTEND_IMAGE_NAME" "." "Dockerfile"
    if [ $? -ne 0 ]; then
        log_error "Frontend image build/transfer failed"
        exit 1
    fi
fi

if [[ "$BUILD_TYPE" == "agent" || "$BUILD_TYPE" == "all" ]]; then
    build_and_transfer_image "$AGENT_IMAGE_NAME" "./agent" "agent/Dockerfile"
    if [ $? -ne 0 ]; then
        log_error "Agent image build/transfer failed"
        exit 1
    fi
fi

# Apply K8s manifests if specified
if [ ${#MANIFESTS[@]} -gt 0 ]; then
    log_info "Applying Kubernetes manifests..."
    
    for manifest in "${MANIFESTS[@]}"; do
        if [ ! -f "$manifest" ]; then
            log_error "Manifest file not found: $manifest"
            exit 1
        fi
        
        log_info "Applying $manifest..."
        MANIFEST_NAME=$(basename "$manifest")
        
        if ! multipass transfer "$manifest" "$VM_NAME:/home/ubuntu/$MANIFEST_NAME"; then
            log_error "Failed to transfer $manifest to VM"
            exit 1
        fi
        
        if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f "/home/ubuntu/$MANIFEST_NAME"; then
            log_error "Failed to apply $manifest"
            exit 1
        fi
        
        log_info "✅ Applied $manifest"
    done
fi

# Restart deployments if requested
if [ "$RESTART_DEPLOYMENTS" = true ]; then
    log_info "Restarting deployments..."
    
    DEPLOYMENTS_TO_RESTART=()
    
    if [[ "$BUILD_TYPE" == "frontend" || "$BUILD_TYPE" == "all" ]]; then
        DEPLOYMENTS_TO_RESTART+=("$FRONTEND_DEPLOYMENT")
    fi
    
    if [[ "$BUILD_TYPE" == "agent" || "$BUILD_TYPE" == "all" ]]; then
        DEPLOYMENTS_TO_RESTART+=("$AGENT_DEPLOYMENT")
    fi
    
    for deployment in "${DEPLOYMENTS_TO_RESTART[@]}"; do
        log_info "Restarting deployment/$deployment..."
        if ! multipass exec "$VM_NAME" -- microk8s kubectl rollout restart deployment/"$deployment"; then
            log_error "Failed to restart deployment/$deployment"
            exit 1
        fi
        
        log_info "Waiting for rollout to complete..."
        if ! multipass exec "$VM_NAME" -- microk8s kubectl rollout status deployment/"$deployment"; then
            log_error "Rollout status check failed for $deployment"
            exit 1
        fi
        
        log_info "✅ Deployment $deployment restarted successfully"
    done
fi

# Run verification if requested
if [ "$RUN_VERIFICATION" = true ]; then
    log_info "Running verification script..."
    
    if [ ! -f "test/verify_k8s_sse_fix.sh" ]; then
        log_warn "Verification script not found at test/verify_k8s_sse_fix.sh, skipping verification"
    else
        if ! bash test/verify_k8s_sse_fix.sh; then
            log_error "Verification failed"
            log_info "To rollback, run: multipass exec $VM_NAME -- microk8s kubectl rollout undo deployment/<deployment-name>"
            exit 1
        fi
        log_info "✅ Verification passed"
    fi
fi

log_info "🎉 Deployment completed successfully!"
log_info ""
log_info "Next steps:"
log_info "  - Check pod status: multipass exec $VM_NAME -- microk8s kubectl get pods"
log_info "  - View logs: multipass exec $VM_NAME -- microk8s kubectl logs -f deployment/<deployment-name>"
log_info "  - To rollback (if needed): multipass exec $VM_NAME -- microk8s kubectl rollout undo deployment/<deployment-name>"

exit 0
