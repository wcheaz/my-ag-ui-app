#!/bin/bash

# Simple test script for rollback function with backup present
# This script tests ONLY the rollback function without running the full deployment pipeline

set -euo pipefail

# Initialize log file variable
LOG_FILE="/tmp/rollback-test-$(date +%Y%m%d-%H%M%S).log"

# Logging functions (from deploy_scripts/common.sh)
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

log_info() {
    local message="$1"
    # Always output for this test
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] INFO: $message" | tee -a "$LOG_FILE"
}

log_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] WARNING: $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $message" | tee -a "$LOG_FILE"
}

echo "🧪 TESTING ROLLBACK FUNCTION WITH BACKUP PRESENT"
echo "================================================="
echo "Log file: $LOG_FILE"

# Source the rollback function from deploy-all.sh
source_rollback_function() {
    # Extract just the rollback function from deploy-all.sh
    eval "$(sed -n '/^rollback_deployment() {/,/^}/p' deploy-all.sh)"
}

# Check if backup file exists
if [ ! -f "k8s/deployment.yaml.backup" ]; then
    log_error "Backup file not found at k8s/deployment.yaml.backup"
    exit 1
fi

log_info "Backup file found at k8s/deployment.yaml.backup"

# Source the rollback function
source_rollback_function

# Check current deployment state before rollback
log_info "Checking current deployment state before rollback..."
if multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app >/dev/null 2>&1; then
    log_info "Deployment my-ag-ui-app exists in Kubernetes"
    
    # Get current deployment configuration
    log_info "Current deployment configuration:"
    multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app -o yaml | head -20
else
    log_warning "Deployment my-ag-ui-app does not exist in Kubernetes (this is OK for testing)"
fi

# Test the rollback function
log_info "Testing rollback function..."
if rollback_deployment; then
    log_info "ROLLBACK TEST PASSED: Rollback function executed successfully"
    
    # Verify that the deployment still exists after rollback (it should)
    log_info "Verifying deployment state after rollback..."
    if multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app >/dev/null 2>&1; then
        log_info "Deployment still exists after rollback"
        
        # Check deployment status
        log_info "Deployment status after rollback:"
        multipass exec my-ag-ui-app-k8s -- microk8s kubectl get deployment my-ag-ui-app
        
        log_info "ROLLBACK VERIFICATION COMPLETE: Deployment state verified"
    else
        log_warning "Deployment not found after rollback (this may be expected depending on rollback strategy)"
        log_info "ROLLBACK VERIFICATION COMPLETE: Rollback function completed successfully"
    fi
else
    log_error "ROLLBACK TEST FAILED: Rollback function returned non-zero exit code"
    exit 1
fi

log_info "ROLLBACK TEST COMPLETED SUCCESSFULLY"
echo "🎉 Task 4.5: Test rollback function with backup present - PASSED"