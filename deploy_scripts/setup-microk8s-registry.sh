#!/bin/bash

# DEBUG LEVEL: MINIMAL (successful phase)
# This script sets up the microk8s registry for local image distribution.
# Based on deploy.sh analysis, this phase is SUCCESSFUL - minimal debug output retained.

set -e

# Source common error handling functions
if [ -f "deploy_scripts/common.sh" ]; then
    source "deploy_scripts/common.sh"
    
    # Override log function for debug support
    log() {
        local message="$1"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Always log to file
        echo "[$timestamp] $message" >> "$LOG_FILE"
        
        # Only output to console if DEBUG=all or message is essential
        if [ "$DEBUG" = "all" ] || [[ "$message" =~ ^(✅|❌|⚠️|Starting|Completed|Failed|ERROR) ]]; then
            echo "[$timestamp] $message"
        fi
    }
else
    # Fallback error handling if common.sh is not available
    VM_NAME="${VM_NAME:-my-ag-ui-app-k8s}"
    LOG_FILE="${LOG_FILE:-/tmp/setup-microk8s-registry-$(date +%Y%m%d-%H%M%S).log}"
    DEBUG=${DEBUG:-""}
    
    log() {
        local message="$1"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Always log to file
        echo "[$timestamp] $message" >> "$LOG_FILE"
        
        # Only output to console if DEBUG=all or message is essential
        if [ "$DEBUG" = "all" ] || [[ "$message" =~ ^(✅|❌|⚠️|Starting|Completed|Failed|ERROR) ]]; then
            echo "[$timestamp] $message"
        fi
    }
    
    handle_registry_inaccessible_error() {
        local error_code=$1
        local error_context=$2
        local registry_endpoint=${3:-"localhost:32000"}
        
        log "ERROR: Registry accessibility error: $error_context"
        log "RECOVERY: Check microk8s status and enable registry if needed"
        exit "$error_code"
    }
fi

# Start timing a deployment phase
start_phase_timing() {
    local phase_name="$1"
    local start_time=$(date +%s.%N)
    PHASE_START_TIMES["$phase_name"]=$start_time
    log "🔶 START: $phase_name"
}

# End timing a deployment phase and calculate duration
end_phase_timing() {
    local phase_name="$1"
    local end_time=$(date +%s.%N)
    
    if [ -z "${PHASE_START_TIMES[$phase_name]}" ]; then
        log "⚠️  WARNING: Cannot end timing for '$phase_name' - phase was not started"
        return 1
    fi
    
    local start_time=${PHASE_START_TIMES[$phase_name]}
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    log "✅ END: $phase_name (duration: ${duration}s)"
}

# Initialize timing array
declare -A PHASE_START_TIMES



# Verify microk8s registry is running and accessible at localhost:32000
verify_microk8s_registry() {
    log "Verifying registry is running and accessible at localhost:32000..."
    
    local registry_check_output
    local registry_check_exit_code
    local start_time=$(date +%s.%N)
    
    # Check registry accessibility with timeout
    registry_check_output=$(timeout 10 multipass exec "$VM_NAME" -- curl -s --connect-timeout 5 http://localhost:32000/v2/_catalog 2>&1)
    registry_check_exit_code=$?
    local end_time=$(date +%s.%N)
    local check_duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    
    if [ $registry_check_exit_code -eq 0 ]; then
        log "✅ REGISTRY CONNECTIVITY: SUCCESS"
        log "   Response time: ${check_duration} seconds"
        
        # Log registry response for verification
        if [ -n "$registry_check_output" ]; then
            if [ "$DEBUG" = "all" ]; then
                log "Registry response:"
                echo "$registry_check_output" | tee -a "$LOG_FILE"
            fi
            
            if echo "$registry_check_output" | grep -q '{"repositories":'; then
                log "✅ REGISTRY RESPONSE FORMAT: VALID JSON"
            else
                log "⚠️  REGISTRY RESPONSE FORMAT: UNEXPECTED"
            fi
        fi
    else
        log "❌ REGISTRY CONNECTIVITY: FAILED"
        log "   Exit code: $registry_check_exit_code"
        
        if [ "$DEBUG" = "all" ]; then
            log "Registry check output:"
            echo "$registry_check_output" | tee -a "$LOG_FILE"
        fi
        
        # Check if registry service is running
        local registry_service_status
        registry_service_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n container-registry -l app=registry -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "unknown")
        
        if [ "$registry_service_status" = "Running" ]; then
            log "✅ REGISTRY SERVICE: RUNNING"
        else
            log "❌ REGISTRY SERVICE: NOT RUNNING"
            handle_registry_error 302 "Registry service not running - pod status: $registry_service_status" \
                "Verify microk8s status and enable registry: multipass exec '$VM_NAME' -- microk8s enable registry"
            return 1
        fi
    fi
    
    # Get registry status information
    if [ "$DEBUG" = "all" ]; then
        log "Getting detailed registry status..."
        local registry_pod_status
        local registry_service_info
        
        registry_pod_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n container-registry -l app=registry -o wide 2>&1 | tee -a "$LOG_FILE")
        registry_service_info=$(multipass exec "$VM_NAME" -- microk8s kubectl get svc -n container-registry -l app=registry 2>&1 | tee -a "$LOG_FILE")
        
        log "Registry pod status:"
        echo "$registry_pod_status" | tee -a "$LOG_FILE"
        log "Registry service info:"
        echo "$registry_service_info" | tee -a "$LOG_FILE"
    fi
    
    log "✅ Registry verification completed successfully"
    log "   Registry is accessible at: localhost:32000"
    
    return 0
}

# Enable microk8s registry for local image distribution
enable_microk8s_registry() {
    log "Starting microk8s registry setup..."
    
    # Check if microk8s is available
    log "Checking microk8s availability..."
    if ! multipass exec "$VM_NAME" -- command -v microk8s >/dev/null 2>&1; then
        log "❌ ERROR: microk8s is not available in VM"
        log "   Please ensure microk8s is installed: sudo snap install microk8s --classic"
        return 1
    fi
    log "✅ microk8s is available in VM"
    
    # Enable microk8s registry with error handling
    log "Enabling microk8s registry..."
    log "   Command: microk8s enable registry"
    local registry_enable_output
    local registry_enable_exit_code
    
    # Execute registry enablement with timeout
    log "   Executing: timeout 30 multipass exec '$VM_NAME' -- microk8s enable registry"
    registry_enable_output=$(timeout 30 multipass exec "$VM_NAME" -- microk8s enable registry 2>&1)
    registry_enable_exit_code=$?
    
    if [ $registry_enable_exit_code -eq 0 ]; then
        log "✅ microk8s registry enable command completed successfully"
        
        # Log the output if debug mode is enabled
        if [ "$DEBUG" = "all" ] && [ -n "$registry_enable_output" ]; then
            log "Registry enablement output:"
            echo "$registry_enable_output" | tee -a "$LOG_FILE"
        fi
    else
        log "❌ ERROR: Failed to enable microk8s registry (exit code: $registry_enable_exit_code)"
        
        if [ "$DEBUG" = "all" ]; then
            log "Error output:"
            echo "$registry_enable_output" | tee -a "$LOG_FILE"
        fi
        
        # Specific error handling
        if echo "$registry_enable_output" | grep -q "microk8s is not running"; then
            log "❌ ERROR: microk8s is not running"
            log "   RECOVERY: Start microk8s first: multipass exec '$VM_NAME' -- microk8s start"
        elif echo "$registry_enable_output" | grep -q "permission denied"; then
            log "❌ ERROR: Permission denied"
            log "   RECOVERY: Run with sudo: multipass exec '$VM_NAME' -- sudo microk8s enable registry"
        elif echo "$registry_enable_output" | grep -q "already enabled"; then
            log "ℹ️  INFO: Registry is already enabled"
            return 0
        fi
        
        return 1
    fi
    
    # Wait a moment for registry to start up
    log "Waiting 5 seconds for registry to fully start..."
    sleep 5
    
    # Verify registry is running and accessible
    if ! verify_microk8s_registry; then
        handle_registry_error 201 "Registry verification failed after enablement" \
            "Verify microk8s registry is accessible: multipass exec '$VM_NAME' -- microk8s kubectl get pods -n container-registry"
        return 201
    fi
    
    log "✅ microk8s registry setup completed successfully"
    log "   Registry status: ENABLED and VERIFIED"
    log "   Registry endpoint: localhost:32000"
    
    return 0
}

# Main execution
start_phase_timing "MICROK8S_REGISTRY_SETUP"
log "Starting microk8s registry setup..."

if ! enable_microk8s_registry; then
    log "ERROR: microk8s registry setup failed"
    log "   This is required for local image distribution"
    handle_registry_error 204 "Registry setup failed during initial microk8s registry enablement" \
        "Verify microk8s is running and try: multipass exec '$VM_NAME' -- microk8s enable registry"
    exit 1
fi

log "microk8s registry setup completed successfully"
end_phase_timing "MICROK8S_REGISTRY_SETUP"

log "🎉 Microk8s registry setup completed successfully!"
log "   Registry is ready for local image distribution"
log "   Next step: Push Docker image to registry"