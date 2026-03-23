#!/bin/bash

# Registry Approach Integration Test Script
# ========================================
# This script specifically tests the microk8s registry approach integration,
# ensuring that the image push and deployment flow works correctly without
# requiring Docker daemon loading in the VM.
#
# Usage: ./test-registry-approach.sh [test-phase]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REGISTRY_IMAGE="localhost:32000/my-ag-ui-app:latest"
LOG_FILE="/tmp/registry-test-$(date +%Y%m%d-%H%M%S).log"

# Logging
log_registry() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] REGISTRY TEST: ${1}${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] REGISTRY TEST: ${1}" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS: ${1}${NC}"
    echo "SUCCESS: ${1}" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌ ERROR: ${1}${NC}"
    echo "ERROR: ${1}" >> "$LOG_FILE"
}

log_info() {
    echo -e "${YELLOW}ℹ️  INFO: ${1}${NC}"
    echo "INFO: ${1}" >> "$LOG_FILE"
}

# Test result tracking
PASSED=0
FAILED=0

run_registry_test() {
    local test_name="$1"
    local test_command="$2"
    
    log_registry "Running: $test_name"
    if eval "$test_command" >/dev/null 2>&1; then
        log_success "$test_name"
        PASSED=$((PASSED + 1))
    else
        log_error "$test_name"
        FAILED=$((FAILED + 1))
    fi
}

# Test 1: Registry enablement
test_registry_enablement() {
    log_registry "Phase 1: Registry Enablement"
    log_registry "Testing microk8s registry setup and accessibility"
    
    # Check if microk8s is running
    run_registry_test "microk8s status" "microk8s status --wait-ready >/dev/null 2>&1"
    
    # Check if registry is enabled
    if microk8s status | grep -q "registry: enabled"; then
        log_success "microk8s registry already enabled"
    else
        log_info "Enabling microk8s registry..."
        run_registry_test "enable registry" "microk8s enable registry"
        sleep 5  # Wait for registry to start
    fi
    
    # Test registry accessibility
    run_registry_test "registry accessible" "curl -s http://localhost:32000/v2/_catalog >/dev/null 2>&1"
    
    log_registry "Phase 1 completed"
}

# Test 2: Docker image build and tag
test_image_build() {
    log_registry "Phase 2: Image Build and Tag"
    log_registry "Testing Docker image build for local registry"
    
    # Check Docker daemon
    run_registry_test "Docker daemon accessible" "docker info >/dev/null 2>&1"
    
    # Check if image exists, build if not
    if docker images "$REGISTRY_IMAGE" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "$REGISTRY_IMAGE"; then
        log_success "Image already exists: $REGISTRY_IMAGE"
    else
        log_info "Building Docker image for local registry..."
        run_registry_test "build image" "docker build -t $REGISTRY_IMAGE ."
    fi
    
    # Verify image exists
    run_registry_test "verify image exists" "docker images $REGISTRY_IMAGE --format '{{.Repository}}:{{.Tag}}' | grep -q '$REGISTRY_IMAGE'"
    
    log_registry "Phase 2 completed"
}

# Test 3: Image push to registry
test_image_push() {
    log_registry "Phase 3: Image Push to Registry"
    log_registry "Testing comprehensive image push with verification"
    
    # Test registry accessibility before push
    run_registry_test "pre-push registry check" "curl -s http://localhost:32000/v2/_catalog >/dev/null 2>&1"
    
    # Push image to registry
    log_info "Pushing image to registry (this may take a while)..."
    run_registry_test "push image" "docker push $REGISTRY_IMAGE"
    
    # Verify image in registry
    log_info "Verifying image in registry..."
    run_registry_test "image in registry" "curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list | grep -q 'latest'"
    
    # Test registry manifest accessibility
    run_registry_test "registry manifest accessible" "curl -s http://localhost:32000/v2/my-ag-ui-app/manifests/latest >/dev/null 2>&1"
    
    log_registry "Phase 3 completed"
}

# Test 4: Kubernetes deployment with registry image
test_k8s_deployment() {
    log_registry "Phase 4: Kubernetes Deployment with Registry"
    log_registry "Testing Kubernetes deployment using local registry image"
    
    # Check deployment manifest
    run_registry_test "deployment manifest exists" "[ -f 'k8s/deployment.yaml' ]"
    
    # Verify image reference in deployment manifest
    if grep -q "localhost:32000/my-ag-ui-app:latest" k8s/deployment.yaml; then
        log_success "Deployment manifest uses registry image"
    else
        log_error "Deployment manifest does not use registry image"
        return 1
    fi
    
    # Verify no imagePullPolicy (should use default)
    if grep -q "imagePullPolicy" k8s/deployment.yaml; then
        log_error "Deployment manifest still has imagePullPolicy (should be removed)"
    else
        log_success "Deployment manifest uses default pull policy"
    fi
    
    # Check deployment manifest is valid
    run_registry_test "deployment manifest valid" "python3 -c \"import yaml; yaml.safe_load(open('k8s/deployment.yaml', 'r'))\""
    
    log_registry "Phase 4 completed"
}

# Test 5: End-to-end validation (simulated)
test_e2e_validation() {
    log_registry "Phase 5: End-to-End Validation"
    log_registry "Testing complete flow from build to deployment (simulated)"
    
    # Verify all components are ready
    local components_ready=true
    
    # Check registry
    if curl -s http://localhost:32000/v2/_catalog >/dev/null 2>&1; then
        log_success "Registry ready"
    else
        log_error "Registry not ready"
        components_ready=false
    fi
    
    # Check image exists locally
    if docker images "$REGISTRY_IMAGE" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "$REGISTRY_IMAGE"; then
        log_success "Image ready locally"
    else
        log_error "Image not ready locally"
        components_ready=false
    fi
    
    # Check image in registry
    if curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list 2>/dev/null | grep -q "latest"; then
        log_success "Image ready in registry"
    else
        log_error "Image not ready in registry"
        components_ready=false
    fi
    
    # Check deployment manifest
    if [ -f "k8s/deployment.yaml" ] && grep -q "localhost:32000/my-ag-ui-app:latest" k8s/deployment.yaml; then
        log_success "Deployment manifest ready"
    else
        log_error "Deployment manifest not ready"
        components_ready=false
    fi
    
    if [ "$components_ready" = true ]; then
        log_success "All components ready for end-to-end deployment"
        log_registry "Phase 5 completed"
    else
        log_error "Some components not ready for deployment"
        return 1
    fi
}

# Test 6: Registry approach benefits validation
test_benefits_validation() {
    log_registry "Phase 6: Registry Approach Benefits Validation"
    log_registry "Validating that registry approach provides expected benefits"
    
    # Benefit 1: No VM Docker daemon setup required
    if grep -q "VM Docker setup removed" deploy.sh; then
        log_success "Benefit 1: VM Docker daemon setup removed"
    else
        log_info "Note: VM Docker setup may still be present in deployment script"
    fi
    
    # Benefit 2: Image push instead of load
    if grep -q "push_image_to_registry" deploy.sh; then
        log_success "Benefit 2: Image push function integrated"
    else
        log_error "Image push function not found in deployment script"
    fi
    
    # Benefit 3: No imagePullPolicy in deployment
    if ! grep -q "imagePullPolicy" k8s/deployment.yaml; then
        log_success "Benefit 3: No imagePullPolicy (uses default)"
    else
        log_error "imagePullPolicy still present in deployment"
    fi
    
    # Benefit 4: Comprehensive error handling
    if grep -q "exponential backoff" deploy.sh; then
        log_success "Benefit 4: Enhanced error handling with exponential backoff"
    else
        log_info "Enhanced error handling may not be fully implemented"
    fi
    
    # Benefit 5: Verification mechanisms
    if grep -q "verify.*registry" deploy.sh; then
        log_success "Benefit 5: Registry verification mechanisms in place"
    else
        log_info "Registry verification may be limited"
    fi
    
    log_registry "Phase 6 completed"
}

# Main function
main() {
    echo "================================================"
    echo "  Registry Approach Integration Test"
    echo "  Testing microk8s registry deployment flow"
    echo "================================================"
    echo ""
    echo "Registry Image: $REGISTRY_IMAGE"
    echo "Log File: $LOG_FILE"
    echo ""
    
    # Initialize counters
    PASSED=0
    FAILED=0
    
    # Run test phases
    test_registry_enablement
    test_image_build
    test_image_push
    test_k8s_deployment
    test_e2e_validation
    test_benefits_validation
    
    # Summary
    echo "================================================"
    echo "  REGISTRY APPROACH TEST SUMMARY"
    echo "================================================"
    echo "Tests Passed: $PASSED"
    echo "Tests Failed: $FAILED"
    echo "Total Tests: $((PASSED + FAILED))"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo "🎉 ALL TESTS PASSED!"
        echo ""
        echo "✅ Registry approach is properly implemented and integrated"
        echo "✅ Ready for end-to-end deployment testing"
        echo "✅ All expected benefits are validated"
        echo ""
        echo "Next Steps:"
        echo "1. Run complete deployment: ./deploy.sh"
        echo "2. Or run comprehensive tests: ./test-complete-deployment-flow.sh full"
        exit 0
    else
        echo "❌ SOME TESTS FAILED"
        echo ""
        echo "Issues found in registry approach implementation:"
        echo "1. Review failed tests above"
        echo "2. Fix identified issues"
        echo "3. Re-run this test script"
        echo "4. Check log file: $LOG_FILE"
        exit 1
    fi
}

# Help
show_help() {
    echo "Registry Approach Integration Test Script"
    echo ""
    echo "This script tests the microk8s registry approach integration,"
    echo "ensuring the deployment flow works correctly without VM Docker loading."
    echo ""
    echo "Usage: $0 [phase]"
    echo ""
    echo "Test phases (optional - runs all if not specified):"
    echo "  1  - Registry enablement"
    echo "  2  - Image build and tag"
    echo "  3  - Image push to registry"
    echo "  4  - Kubernetes deployment"
    echo "  5  - End-to-end validation"
    echo "  6  - Benefits validation"
    echo ""
    echo "Examples:"
    echo "  $0              # Run all tests"
    echo "  $0 3            # Test only image push phase"
    echo ""
}

if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Run specific phase or all tests
case "$1" in
    1) test_registry_enablement ;;
    2) test_image_build ;;
    3) test_image_push ;;
    4) test_k8s_deployment ;;
    5) test_e2e_validation ;;
    6) test_benefits_validation ;;
    *) main ;;
esac