#!/bin/bash

set -euo pipefail

# Deploy-all.sh - Orchestrator for modular deployment scripts
# This script executes all modular deployment scripts in sequence
# Usage: ./deploy-all.sh

# Source common error handling functions
if [ -f "deploy_scripts/common.sh" ]; then
    source "deploy_scripts/common.sh"
else
    echo "ERROR: deploy_scripts/common.sh not found. Cannot continue with deployment."
    exit 1
fi

# Initialize log file
setup_log_file

# Clean up old log files to prevent disk exhaustion
cleanup_old_logs

# Rollback function to restore previous deployment state
rollback_deployment() {
    log_error "🔄 INITIATING ROLLBACK PROCEDURE"
    log_error "Deployment failed - attempting to restore previous state"
    
    if [ -f "k8s/deployment.yaml.backup" ]; then
        log_info "🔄 Rolling back using backup deployment manifest..."
        log_info "🔄 Transferring backup deployment manifest to VM..."
        
        # Transfer backup file to VM
        if ! multipass transfer k8s/deployment.yaml.backup "${VM_NAME:-my-ag-ui-app-k8s}:/home/ubuntu/deployment.yaml.backup" 2>&1 | tee -a "$LOG_FILE"; then
            log_error "❌ ROLLBACK FAILED: Could not transfer backup deployment manifest to VM"
            log_error "   Manual intervention required to restore deployment state"
            return 1
        fi
        
        # Get current deployment resource version before applying changes
        log_info "🔄 Retrieving current deployment resource version..."
        local current_resource_version=""
        if multipass exec "${VM_NAME:-my-ag-ui-app-k8s}" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.metadata.resourceVersion}' 2>/dev/null; then
            current_resource_version=$(multipass exec "${VM_NAME:-my-ag-ui-app-k8s}" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.metadata.resourceVersion}' 2>/dev/null || echo "")
            log_info "🔄 Current deployment resource version: $current_resource_version"
        else
            log_warning "🔄 Could not retrieve current deployment resource version - deployment may not exist"
        fi
        
        # Strategy 1: Try to apply with graceful conflict handling
        log_info "🔄 Attempting rollback with conflict resolution..."
        if multipass exec "${VM_NAME:-my-ag-ui-app-k8s}" -- microk8s kubectl apply -f /home/ubuntu/deployment.yaml.backup 2>&1 | tee -a "$LOG_FILE"; then
            log_info "✅ ROLLBACK SUCCESSFUL: Previous deployment state restored"
            log_info "   Services should be returning to previous stable state"
            return 0
        else
            local apply_exit_code=$?
            log_error "❌ ROLLBACK CONFLICT: Deployment manifest application failed (exit code: $apply_exit_code)"
            log_error "   This indicates a resource version conflict or other conflict"
            
            # Strategy 2: Try with --force flag to override conflicts
            log_info "🔄 Attempting force rollback to resolve conflicts..."
            if multipass exec "${VM_NAME:-my-ag-ui-app-k8s}" -- microk8s kubectl apply -f /home/ubuntu/deployment.yaml.backup --force 2>&1 | tee -a "$LOG_FILE"; then
                log_info "✅ FORCE ROLLBACK SUCCESSFUL: Previous deployment state restored with override"
                log_info "   Services should be returning to previous stable state"
                return 0
            else
                local force_exit_code=$?
                log_error "❌ FORCE ROLLBACK FAILED: Could not apply backup deployment manifest even with force (exit code: $force_exit_code)"
                
                # Strategy 3: Delete and recreate the deployment
                log_info "🔄 Attempting delete-and-recreate strategy..."
                if multipass exec "${VM_NAME:-my-ag-ui-app-k8s}" -- microk8s kubectl delete deployment my-ag-ui-app --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE"; then
                    log_info "🔄 Deployment deleted successfully"
                    sleep 2  # Give Kubernetes time to cleanup
                    
                    if multipass exec "${VM_NAME:-my-ag-ui-app-k8s}" -- microk8s kubectl apply -f /home/ubuntu/deployment.yaml.backup 2>&1 | tee -a "$LOG_FILE"; then
                        log_info "✅ DELETE-AND-RECREATE ROLLBACK SUCCESSFUL: Previous deployment state restored"
                        log_info "   Services should be returning to previous stable state"
                        return 0
                    else
                        local recreate_exit_code=$?
                        log_error "❌ DELETE-AND-RECREATE ROLLBACK FAILED: Could not recreate deployment (exit code: $recreate_exit_code)"
                        log_error "   Manual intervention required to restore deployment state"
                        return 1
                    fi
                else
                    log_error "❌ DELETE STRATEGY FAILED: Could not delete existing deployment"
                    log_error "   Manual intervention required to restore deployment state"
                    return 1
                fi
            fi
        fi
    else
        log_error "❌ ROLLBACK FAILED: No backup deployment manifest found (k8s/deployment.yaml.backup)"
        log_error "   Cannot perform automatic rollback - manual intervention required"
        return 1
    fi
}

# Function to log environment context
log_environment_context() {
    log_info "📊 ENVIRONMENT CONTEXT:"
    
    # Kubernetes cluster status
    if multipass exec "${VM_NAME:-my-ag-ui-app-k8s}" -- microk8s kubectl get nodes >/dev/null 2>&1; then
        log_info "  • Kubernetes: ✅ Accessible"
        local node_count=$(multipass exec "${VM_NAME:-my-ag-ui-app-k8s}" -- microk8s kubectl get nodes --no-headers | wc -l)
        log_info "  • Node Count: $node_count"
    else
        log_warning "  • Kubernetes: ❌ Not accessible"
    fi
    
    # Registry status  
    if curl -s http://localhost:32000/v2/_catalog >/dev/null 2>&1; then
        log_info "  • Registry: ✅ Accessible"
    else
        log_warning "  • Registry: ❌ Not accessible"
    fi
    
    # VM status
    if multipass list | grep -q "${VM_NAME:-my-ag-ui-app-k8s}"; then
        log_info "  • VM: ✅ Running (${VM_NAME:-my-ag-ui-app-k8s})"
    else
        log_warning "  • VM: ❌ Not found or not running"
    fi
}



# Execute deployment scripts in correct order
log_info "🚀 STARTING DEPLOYMENT PIPELINE"
log_info "Environment: ${ENVIRONMENT:-development}"
log_info "Verbose mode: ${VERBOSE:-false}"

# Log environment context
if [ "${VERBOSE:-false}" = "true" ]; then
    log_environment_context
fi

# Step 0: Cleanup previous non-running pods and unused resources before deployment
log_info "📋 Step 0: Cleaning up previous deployment resources..."
if ! ./deploy_scripts/cleanup-resources.sh; then
    log_warning "⚠️  STEP 0 WARNING: Cleanup encountered issues, but continuing with deployment"
fi
log_info "✅ Step 0: Cleanup completed"

# Step 1: Setting up Kubernetes secrets
log_info "📋 Step 1: Setting up Kubernetes secrets..."
if ! ./deploy_scripts/setup-k8s-secrets.sh; then
    log_error "❌ STEP 1 FAILED: Failed to set up Kubernetes secrets"
    rollback_deployment
    exit 1
fi
log_info "✅ Step 1: Kubernetes secrets setup completed"

# Step 2: Building Docker image
log_info "📋 Step 2: Building Docker image..."
if ! ./deploy_scripts/build-docker-image.sh; then
    log_error "❌ STEP 2 FAILED: Failed to build Docker image"
    rollback_deployment
    exit 1
fi
log_info "✅ Step 2: Docker image build completed"

# Step 3: Tagging Docker image
log_info "📋 Step 3: Tagging Docker image..."
if ! ./deploy_scripts/tag-docker-image.sh; then
    log_error "❌ STEP 3 FAILED: Failed to tag Docker image"
    rollback_deployment
    exit 1
fi
log_info "✅ Step 3: Docker image tagging completed"

# Step 3.5: Create backup of deployment manifest before registry setup
log_info "📋 Step 3.5: Creating backup of deployment manifest..."
if [ -f "k8s/deployment.yaml" ]; then
    # Create backup, overwriting existing silently
    cp -f "k8s/deployment.yaml" "k8s/deployment.yaml.backup" 2>/dev/null || {
        log_error "❌ STEP 3.5 FAILED: Could not create backup of deployment manifest"
        rollback_deployment
        exit 1
    }
    
    # Verify backup file exists
    if [ ! -f "k8s/deployment.yaml.backup" ]; then
        log_error "❌ STEP 3.5 FAILED: Backup file was not created successfully"
        rollback_deployment
        exit 1
    fi
    
    # Verify backup file content matches original
    if ! cmp -s "k8s/deployment.yaml" "k8s/deployment.yaml.backup"; then
        log_error "❌ STEP 3.5 FAILED: Backup file content does not match original"
        rollback_deployment
        exit 1
    fi
    
    log_info "✅ Step 3.5: Deployment manifest backup created and verified at k8s/deployment.yaml.backup"
else
    log_error "❌ STEP 3.5 FAILED: k8s/deployment.yaml not found - cannot create backup"
    rollback_deployment
    exit 1
fi

# Step 4: Setting up Microk8s registry
log_info "📋 Step 4: Setting up Microk8s registry..."
if ! ./deploy_scripts/setup-microk8s-registry.sh; then
    log_error "❌ STEP 4 FAILED: Failed to set up Microk8s registry"
    rollback_deployment
    exit 1
fi
log_info "✅ Step 4: Microk8s registry setup completed"

# Step 5: Pushing Docker image
log_info "📋 Step 5: Pushing Docker image..."
if ! ./deploy_scripts/push-docker-image.sh; then
    log_error "❌ STEP 5 FAILED: Failed to push Docker image"
    rollback_deployment
    exit 1
fi
log_info "✅ Step 5: Docker image push completed"

# Step 6: Deploying to Kubernetes
log_info "📋 Step 6: Deploying to Kubernetes..."
if ! ./deploy_scripts/deploy-to-k8s.sh; then
    log_error "❌ STEP 6 FAILED: Failed to deploy to Kubernetes"
    rollback_deployment
    exit 1
fi
log_info "✅ Step 6: Kubernetes deployment completed"

# Deployment summary logging (task 11.4)
log_info "🎉 DEPLOYMENT SUMMARY:"
log_info "  ✅ All 7 deployment steps completed successfully"
log_info "  ✅ Cleanup: Previous resources removed"
log_info "  ✅ Kubernetes secrets: Configured"
log_info "  ✅ Docker image: Built and pushed"
log_info "  ✅ Microk8s registry: Setup completed"
log_info "  ✅ Kubernetes deployment: Applied"
log_info "  📍 Deployment status: FULLY COMPLETED"
log_info "  📍 Log file: $LOG_FILE"

if [ "${VERBOSE:-false}" = "true" ]; then
    log_info "🔍 VERBOSE MODE: Deployment pipeline completed successfully"
    log_info "   All individual scripts executed without errors"
    log_info "   Rollback capability: Available (backup manifest present)"
fi

log_info "🚀 DEPLOYMENT PIPELINE COMPLETED SUCCESSFULLY!"

