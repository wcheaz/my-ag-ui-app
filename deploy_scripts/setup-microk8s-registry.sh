#!/bin/bash

# Enable strict error handling
set -euo pipefail

# Source common error handling functions
if [ -f "deploy_scripts/common.sh" ]; then
    source "deploy_scripts/common.sh"
else
    echo "ERROR: deploy_scripts/common.sh not found. Please ensure common error handling functions are available."
    exit 1
fi

# Initialize log file
setup_log_file

# Start timing a deployment phase
start_phase_timing() {
    local phase_name="$1"
    local start_time=$(date +%s.%N)
    PHASE_START_TIMES["$phase_name"]=$start_time
    log_info "🔶 START: $phase_name"
}

# End timing a deployment phase and calculate duration
end_phase_timing() {
    local phase_name="$1"
    local end_time=$(date +%s.%N)
    
    if [ -z "${PHASE_START_TIMES[$phase_name]}" ]; then
        log_warning "Cannot end timing for '$phase_name' - phase was not started"
        return 1
    fi
    
    local start_time=${PHASE_START_TIMES[$phase_name]}
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    log_info "✅ END: $phase_name (duration: ${duration}s)"
}

# Initialize timing array
declare -A PHASE_START_TIMES



# Verify microk8s registry is running and accessible at localhost:32000
verify_microk8s_registry() {
    log_info "Verifying registry is running and accessible at localhost:32000..."
    
    local registry_check_output
    local registry_check_exit_code
    local start_time=$(date +%s.%N)
    
    # Check registry accessibility with timeout
    registry_check_output=$(timeout 10 multipass exec "$VM_NAME" -- curl -s --connect-timeout 5 http://localhost:32000/v2/_catalog 2>&1)
    registry_check_exit_code=$?
    local end_time=$(date +%s.%N)
    local check_duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    
    if [ $registry_check_exit_code -eq 0 ]; then
        log_info "✅ REGISTRY CONNECTIVITY: SUCCESS"
        log_info "   Response time: ${check_duration} seconds"
        
        # Log registry response for verification
        if [ -n "$registry_check_output" ]; then
            if [ "${VERBOSE:-false}" = "true" ]; then
                log_info "Registry response:"
                echo "$registry_check_output" | tee -a "$LOG_FILE"
            fi
            
            if echo "$registry_check_output" | grep -q '{"repositories":'; then
                log_info "✅ REGISTRY RESPONSE FORMAT: VALID JSON"
            else
                log_warning "REGISTRY RESPONSE FORMAT: UNEXPECTED"
            fi
        fi
    else
        log_error "❌ REGISTRY CONNECTIVITY: FAILED"
        log_error "   Exit code: $registry_check_exit_code"
        
        if [ "${VERBOSE:-false}" = "true" ]; then
            log_info "Registry check output:"
            echo "$registry_check_output" | tee -a "$LOG_FILE"
        fi
        
        # Check if registry service is running
        local registry_service_status
        registry_service_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n container-registry -l app=registry -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "unknown")
        
        if [ "$registry_service_status" = "Running" ]; then
            log_info "✅ REGISTRY SERVICE: RUNNING"
        else
            log_error "❌ REGISTRY SERVICE: NOT RUNNING"
            handle_registry_error "Registry service not running - pod status: $registry_service_status" \
                "Verify microk8s status and enable registry: multipass exec '$VM_NAME' -- microk8s enable registry"
            return 1
        fi
    fi
    
    # Get registry status information
    if [ "${VERBOSE:-false}" = "true" ]; then
        log_info "Getting detailed registry status..."
        local registry_pod_status
        local registry_service_info
        
        registry_pod_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n container-registry -l app=registry -o wide 2>&1 | tee -a "$LOG_FILE")
        registry_service_info=$(multipass exec "$VM_NAME" -- microk8s kubectl get svc -n container-registry -l app=registry 2>&1 | tee -a "$LOG_FILE")
        
        log_info "Registry pod status:"
        echo "$registry_pod_status" | tee -a "$LOG_FILE"
        log_info "Registry service info:"
        echo "$registry_service_info" | tee -a "$LOG_FILE"
    fi
    
    log_info "✅ Registry verification completed successfully"
    log_info "   Registry is accessible at: localhost:32000"
    
    return 0
}

# Check registry connectivity before enabling (pre-verification)
verify_registry_before_enable() {
    log_info "Performing pre-enablement registry connectivity check..."
    
    local registry_check_output
    local registry_check_exit_code
    
    # Try to connect to registry endpoint before enabling
    registry_check_output=$(timeout 10 multipass exec "$VM_NAME" -- curl -s --connect-timeout 5 http://localhost:32000/v2/_catalog 2>&1)
    registry_check_exit_code=$?
    
    if [ $registry_check_exit_code -eq 0 ]; then
        log_info "✅ PRE-ENABLEMENT VERIFICATION: Registry already accessible"
        
        # Check if response is valid JSON
        if echo "$registry_check_output" | grep -q '{"repositories":'; then
            log_info "✅ PRE-ENABLEMENT VERIFICATION: Registry response format is valid JSON"
            return 0  # Registry is already running and accessible
        else
            log_warning "⚠️  PRE-ENABLEMENT VERIFICATION: Registry accessible but response format unexpected"
            log_info "   Response: $registry_check_output"
            return 0  # Still accessible, proceed with enablement
        fi
    else
        log_info "ℹ️  PRE-ENABLEMENT VERIFICATION: Registry not accessible (expected - will enable)"
        log_info "   This is normal when registry is not yet enabled"
        log_info "   Exit code: $registry_check_exit_code"
        
        if [ "${VERBOSE:-false}" = "true" ]; then
            log_info "Pre-enablement check output:"
            echo "$registry_check_output" | tee -a "$LOG_FILE"
        fi
        
        return 0  # Continue with enablement - this is expected behavior
    fi
}

# Enable microk8s registry for local image distribution
enable_microk8s_registry() {
    log_info "Starting microk8s registry setup..."
    
    # Check if microk8s is available
    log_info "Checking microk8s availability..."
    if ! multipass exec "$VM_NAME" -- command -v microk8s >/dev/null 2>&1; then
        log_error "❌ ERROR: microk8s is not available in VM"
        log_error "   Please ensure microk8s is installed: sudo snap install microk8s --classic"
        handle_dependency_error "microk8s is not available in VM" "Please ensure microk8s is installed: sudo snap install microk8s --classic"
        return 1
    fi
    log_info "✅ microk8s is available in VM"
    
    # Perform pre-enablement registry connectivity verification
    log_info "Performing pre-enablement registry connectivity verification..."
    if ! verify_registry_before_enable; then
        log_error "❌ PRE-ENABLEMENT VERIFICATION FAILED"
        handle_registry_error "Pre-enablement registry verification failed" \
            "Check network connectivity and VM status: multipass exec '$VM_NAME' -- curl -v http://localhost:32000/v2/_catalog"
        return 1
    fi
    log_info "✅ Pre-enablement registry connectivity verification completed"
    
    # Enable microk8s registry with error handling
    log_info "Enabling microk8s registry..."
    log_info "   Command: microk8s enable registry"
    local registry_enable_output
    local registry_enable_exit_code
    
    # Execute registry enablement with timeout
    log_info "   Executing: timeout 30 multipass exec '$VM_NAME' -- microk8s enable registry"
    registry_enable_output=$(timeout 30 multipass exec "$VM_NAME" -- microk8s enable registry 2>&1)
    registry_enable_exit_code=$?
    
    if [ $registry_enable_exit_code -eq 0 ]; then
        log_info "✅ microk8s registry enable command completed successfully"
        
        # Log the output if verbose mode is enabled
        if [ "${VERBOSE:-false}" = "true" ] && [ -n "$registry_enable_output" ]; then
            log_info "Registry enablement output:"
            echo "$registry_enable_output" | tee -a "$LOG_FILE"
        fi
    else
        log_error "❌ ERROR: Failed to enable microk8s registry (exit code: $registry_enable_exit_code)"
        
        if [ "${VERBOSE:-false}" = "true" ]; then
            log_info "Error output:"
            echo "$registry_enable_output" | tee -a "$LOG_FILE"
        fi
        
        # Specific error handling
        if echo "$registry_enable_output" | grep -q "microk8s is not running"; then
            log_error "❌ ERROR: microk8s is not running"
            log_error "   RECOVERY: Start microk8s first: multipass exec '$VM_NAME' -- microk8s start"
        elif echo "$registry_enable_output" | grep -q "permission denied"; then
            log_error "❌ ERROR: Permission denied"
            log_error "   RECOVERY: Run with sudo: multipass exec '$VM_NAME' -- sudo microk8s enable registry"
        elif echo "$registry_enable_output" | grep -q "already enabled"; then
            log_info "ℹ️  INFO: Registry is already enabled"
            return 0
        fi
        
        return 1
    fi
    
    # Wait a moment for registry to start up
    log_info "Waiting 5 seconds for registry to fully start..."
    sleep 5
    
    # Verify registry is running and accessible
    if ! verify_microk8s_registry; then
        handle_registry_error "Registry verification failed after enablement" \
            "Verify microk8s registry is accessible: multipass exec '$VM_NAME' -- microk8s kubectl get pods -n container-registry"
        return 1
    fi
    
    log_info "✅ microk8s registry setup completed successfully"
    log_info "   Registry status: ENABLED and VERIFIED"
    log_info "   Registry endpoint: localhost:32000"
    
    return 0
}

# Main execution
start_phase_timing "MICROK8S_REGISTRY_SETUP"
log_info "Starting microk8s registry setup..."

if ! enable_microk8s_registry; then
    log_error "ERROR: microk8s registry setup failed"
    log_error "   This is required for local image distribution"
    handle_registry_error "Registry setup failed during initial microk8s registry enablement" \
        "Verify microk8s is running and try: multipass exec '$VM_NAME' -- microk8s enable registry"
    exit 1
fi

log_info "microk8s registry setup completed successfully"
end_phase_timing "MICROK8S_REGISTRY_SETUP"

log_info "🎉 Microk8s registry setup completed successfully!"
log_info "   Registry is ready for local image distribution"
log_info "   Next step: Push Docker image to registry"