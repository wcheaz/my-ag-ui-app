#!/bin/bash

set -euo pipefail

# Cleanup Resources Script
# Removes non-running Kubernetes pods and unused Docker images
# Usage: ./deploy_scripts/cleanup-resources.sh

# Change to project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Source common error handling functions
if [ -f "deploy_scripts/common.sh" ]; then
    source "deploy_scripts/common.sh"
else
    echo "ERROR: deploy_scripts/common.sh not found. Cannot continue with cleanup."
    exit 1
fi

# Default values
VM_NAME="${VM_NAME:-my-ag-ui-app-k8s}"

# Main cleanup function
cleanup_resources() {
    log_info "🧹 CLEANUP: Removing previous non-running pods and unused resources..."
    
    local pods_cleaned=0
    local docker_images_cleaned=0
    
    # Clean up Kubernetes pods that are not running
    log_info "🧹 Cleaning up non-running Kubernetes pods..."
    
    # Get all pods that are not in Running state
    local non_running_pods=$(multipass exec "${VM_NAME}" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[?(@.status.phase!="Running")].metadata.name}' 2>/dev/null)
    
    if [ -n "$non_running_pods" ]; then
        log_info "🧹 Found non-running pods: $non_running_pods"
        
        # Delete evicted pods
        local evicted_pods=$(multipass exec "${VM_NAME}" -- microk8s kubectl get pods -l app=my-ag-ui-app --field-selector=status.phase==Failed -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
        if [ -n "$evicted_pods" ]; then
            log_info "🧹 Deleting evicted pods..."
            multipass exec "${VM_NAME}" -- microk8s kubectl delete pods -l app=my-ag-ui-app --field-selector=status.phase==Failed --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE" || true
            local evicted_count=$(echo "$evicted_pods" | wc -w)
            pods_cleaned=$((pods_cleaned + evicted_count))
            log_info "✅ Deleted $evicted_count evicted pods"
        fi
        
        # Delete pods with ImagePullBackOff or ErrImagePull
        local pull_error_pods=$(multipass exec "${VM_NAME}" -- microk8s kubectl get pods -l app=my-ag-ui-app -o json 2>/dev/null | grep -o '"reason":"ImagePullBackOff"\|"reason":"ErrImagePull"' | wc -l)
        if [ "$pull_error_pods" -gt 0 ]; then
            log_info "🧹 Deleting pods with image pull errors..."
            multipass exec "${VM_NAME}" -- microk8s kubectl delete pods -l app=my-ag-ui-app --field-selector=status.phase!=Running --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE" || true
            log_info "✅ Deleted pods with image pull errors"
        fi
        
        # Delete CrashLoopBackOff pods
        local crash_loop_pods=$(multipass exec "${VM_NAME}" -- microk8s kubectl get pods -l app=my-ag-ui-app -o json 2>/dev/null | grep -o '"reason":"CrashLoopBackOff"' | wc -l)
        if [ "$crash_loop_pods" -gt 0 ]; then
            log_info "🧹 Deleting CrashLoopBackOff pods..."
            multipass exec "${VM_NAME}" -- microk8s kubectl delete pods -l app=my-ag-ui-app --field-selector=status.phase!=Running --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE" || true
            log_info "✅ Deleted CrashLoopBackOff pods"
        fi
        
        # Delete any remaining non-running pods
        local remaining_non_running=$(multipass exec "${VM_NAME}" -- microk8s kubectl get pods -l app=my-ag-ui-app --field-selector=status.phase!=Running -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
        if [ -n "$remaining_non_running" ]; then
            local remaining_count=$(echo "$remaining_non_running" | wc -w)
            log_info "🧹 Deleting remaining non-running pods..."
            multipass exec "${VM_NAME}" -- microk8s kubectl delete pods -l app=my-ag-ui-app --field-selector=status.phase!=Running --ignore-not-found=true 2>&1 | tee -a "$LOG_FILE" || true
            pods_cleaned=$((pods_cleaned + remaining_count))
            log_info "✅ Deleted $remaining_count remaining non-running pods"
        fi
        
    else
        log_info "✅ No non-running pods found - all pods are healthy"
    fi
    
    # Stop and remove containers with label app=my-ag-ui-app before image deletion
    log_info "🧹 Stopping containers with label app=my-ag-ui-app..."
    
    # Get running containers with the app label
    local running_containers=$(docker ps -q -f "label=app=my-ag-ui-app" 2>/dev/null || echo "")
    if [ -n "$running_containers" ]; then
        local running_count=$(echo "$running_containers" | wc -l)
        log_info "🧹 Stopping $running_count running containers..."
        docker stop $running_containers 2>&1 | tee -a "$LOG_FILE" || true
        log_info "✅ Stopped $running_count running containers"
    fi
    
    log_info "🧹 Removing stopped containers with label app=my-ag-ui-app..."
    
    # Get all containers (including stopped) with the app label
    local all_containers=$(docker ps -a -q -f "label=app=my-ag-ui-app" 2>/dev/null || echo "")
    if [ -n "$all_containers" ]; then
        local all_count=$(echo "$all_containers" | wc -l)
        log_info "🧹 Removing $all_count stopped containers..."
        docker rm $all_containers 2>&1 | tee -a "$LOG_FILE" || true
        log_info "✅ Removed $all_count stopped containers"
    fi
    
    # Clean up unused Docker images
    log_info "🧹 Cleaning up unused Docker images..."
    
    # Remove dangling images
    local dangling_images=$(docker images -f "dangling=true" -q 2>/dev/null || echo "")
    if [ -n "$dangling_images" ]; then
        local dangling_count=$(echo "$dangling_images" | wc -l)
        log_info "🧹 Removing $dangling_count dangling Docker images..."
        docker rmi $dangling_images 2>&1 | tee -a "$LOG_FILE" || true
        docker_images_cleaned=$((docker_images_cleaned + dangling_count))
        log_info "✅ Removed dangling Docker images"
    fi
    
    # Remove old my-ag-ui-app images (keep only latest)
    local old_app_images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^my-ag-ui-app:" | grep -v ":latest$" | grep -v "localhost:32000/" 2>/dev/null || echo "")
    if [ -n "$old_app_images" ]; then
        local old_count=$(echo "$old_app_images" | wc -l)
        log_info "🧹 Removing $old_count old my-ag-ui-app images..."
        docker rmi $old_app_images 2>&1 | tee -a "$LOG_FILE" || true
        docker_images_cleaned=$((docker_images_cleaned + old_count))
        log_info "✅ Removed old my-ag-ui-app images"
    fi
    
    # Clean up Docker build cache
    log_info "🧹 Cleaning up Docker build cache..."
    docker builder prune -f 2>&1 | tee -a "$LOG_FILE" || true
    log_info "✅ Cleaned up Docker build cache"
    
    # Cleanup summary
    log_info "🧹 CLEANUP SUMMARY:"
    log_info "  • Pods cleaned: $pods_cleaned"
    log_info "  • Docker images cleaned: $docker_images_cleaned"
    
    if [ $pods_cleaned -eq 0 ] && [ $docker_images_cleaned -eq 0 ]; then
        log_info "  • Status: No cleanup needed (environment already clean)"
    else
        log_info "  • Status: Cleanup completed successfully"
    fi
    
    log_info "✅ PRE-DEPLOYMENT CLEANUP COMPLETED"
}

# Main execution
log_info "🚀 STARTING RESOURCE CLEANUP"
cleanup_resources
log_info "🎉 CLEANUP COMPLETED SUCCESSFULLY!"
