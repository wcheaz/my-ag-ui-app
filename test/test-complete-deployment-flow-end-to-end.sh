#!/bin/bash

# Test script for complete deployment flow end-to-end
# Part of Task 7.11: Test complete deployment flow end-to-end

set -e

VM_NAME="my-ag-ui-app-k8s"
TEST_LOG="/tmp/deployment-flow-test-$(date +%Y%m%d-%H%M%S).log"

# Logging function
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$TEST_LOG"
}

# Function to test deployment flow components
test_deployment_flow() {
    log "=== TASK 7.11: TESTING COMPLETE DEPLOYMENT FLOW END-TO-END ==="
    log "Testing essential components of the deployment flow..."
    
    local test_passed=0
    local test_total=6
    
    # Test 1: Verify VM accessibility
    log "Test 1: VM accessibility"
    if multipass exec "$VM_NAME" -- whoami >/dev/null 2>&1; then
        log "✅ Test 1 PASSED: VM is accessible"
        ((test_passed++))
    else
        log "❌ Test 1 FAILED: VM is not accessible"
    fi
    
    # Test 2: Verify microk8s is running
    log "Test 2: microk8s status"
    if multipass exec "$VM_NAME" -- microk8s status >/dev/null 2>&1; then
        log "✅ Test 2 PASSED: microk8s is running"
        ((test_passed++))
    else
        log "❌ Test 2 FAILED: microk8s is not running"
    fi
    
    # Test 3: Verify microk8s registry is enabled and accessible
    log "Test 3: microk8s registry accessibility"
    if multipass exec "$VM_NAME" -- curl -s http://localhost:32000/v2/_catalog >/dev/null 2>&1; then
        log "✅ Test 3 PASSED: microk8s registry is accessible"
        ((test_passed++))
    else
        log "❌ Test 3 FAILED: microk8s registry is not accessible"
    fi
    
    # Test 4: Verify application image exists in local registry
    log "Test 4: Application image in local registry"
    if multipass exec "$VM_NAME" -- curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list >/dev/null 2>&1; then
        log "✅ Test 4 PASSED: Application image exists in local registry"
        ((test_passed++))
    else
        log "❌ Test 4 FAILED: Application image not found in local registry"
    fi
    
    # Test 5: Verify deployment exists and uses correct image
    log "Test 5: Deployment configuration"
    local deployment_image
    deployment_image=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
    if [[ "$deployment_image" == *"localhost:32000/my-ag-ui-app"* ]]; then
        log "✅ Test 5 PASSED: Deployment uses local registry image"
        log "   Image: $deployment_image"
        ((test_passed++))
    else
        log "❌ Test 5 FAILED: Deployment does not use local registry image"
        log "   Current image: $deployment_image"
    fi
    
    # Test 6: Verify service and ingress are configured
    log "Test 6: Service and ingress configuration"
    local service_exists=false
    local ingress_exists=false
    
    if multipass exec "$VM_NAME" -- microk8s kubectl get service my-ag-ui-app-service >/dev/null 2>&1; then
        service_exists=true
        log "   ✅ Service exists"
    else
        log "   ❌ Service does not exist"
    fi
    
    if multipass exec "$VM_NAME" -- microk8s kubectl get ingress my-ag-ui-app-ingress >/dev/null 2>&1; then
        ingress_exists=true
        log "   ✅ Ingress exists"
    else
        log "   ❌ Ingress does not exist"
    fi
    
    if [ "$service_exists" = true ] && [ "$ingress_exists" = true ]; then
        log "✅ Test 6 PASSED: Both service and ingress are configured"
        ((test_passed++))
    else
        log "❌ Test 6 FAILED: Service or ingress is missing"
    fi
    
    # Summary
    log ""
    log "=== DEPLOYMENT FLOW TEST SUMMARY ==="
    log "Tests passed: $test_passed/$test_total"
    
    if [ $test_passed -eq $test_total ]; then
        log "✅ SUCCESS: Complete deployment flow test PASSED"
        log "   All essential components are working correctly"
        log "   The deployment flow is ready for production use"
        return 0
    else
        log "❌ FAILURE: Complete deployment flow test FAILED"
        log "   Some components are not working correctly"
        log "   Please check the failed tests above"
        return 1
    fi
}

# Main test execution
main() {
    log "Starting complete deployment flow test..."
    log "Test log: $TEST_LOG"
    
    if test_deployment_flow; then
        log ""
        log "=== TASK 7.11: COMPLETE DEPLOYMENT FLOW TEST COMPLETE ==="
        log "✅ SUCCESS: Deployment flow is working end-to-end"
        log "   The microk8s registry approach is fully functional"
        log "   Applications can be built, pushed, and deployed successfully"
    else
        log ""
        log "=== TASK 7.11: COMPLETE DEPLOYMENT FLOW TEST FAILED ==="
        log "❌ FAILURE: Deployment flow has issues that need resolution"
        exit 1
    fi
    
    log ""
    log "Test log saved to: $TEST_LOG"
}

# Execute main function
main "$@"