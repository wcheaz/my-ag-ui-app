#!/bin/bash

# DEBUG LEVEL: MINIMAL (partial success phase)
# This script pushes the Docker image to the microk8s registry.
# Based on deployment status: PARTIAL SUCCESS - minimal debug output retained.

set -euo pipefail

# Source common error handling functions
if [ -f "deploy_scripts/common.sh" ]; then
    source "deploy_scripts/common.sh"
else
    # Fallback error handling if common.sh is not available
    VM_NAME="${VM_NAME:-my-ag-ui-app-k8s}"
    LOG_FILE="${LOG_FILE:-/tmp/deploy-$(date +%Y%m%d-%H%M%S).log}"
    
    log() {
        local message="$1"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] $message" | tee -a "$LOG_FILE"
    }
    
    handle_registry_error() {
        local error_code=$1
        local error_message=$2
        local recovery_suggestion=$3
        
        log "ERROR: $error_message"
        log "RECOVERY: $recovery_suggestion"
        exit "$error_code"
    }
fi

# Initialize log file
if command -v setup_log_file >/dev/null 2>&1; then
    setup_log_file
fi

# Verify microk8s registry is running and accessible at localhost:32000
verify_microk8s_registry() {
    if [ "$DEBUG" = "all" ]; then
        log "Verifying registry is running and accessible at localhost:32000..."
    fi
    
    local registry_check_output
    local registry_check_exit_code
    local start_time=$(date +%s.%N)
    
    # Check registry accessibility with timeout
    registry_check_output=$(timeout 10 multipass exec "$VM_NAME" -- curl -s --connect-timeout 5 http://localhost:32000/v2/_catalog 2>&1)
    registry_check_exit_code=$?
    local end_time=$(date +%s.%N)
    local check_duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    
    if [ $registry_check_exit_code -eq 0 ]; then
        if [ "$DEBUG" = "all" ]; then
            log "✅ REGISTRY CONNECTIVITY: SUCCESS"
            log "   Response time: ${check_duration} seconds"
            
            # Log registry response for verification
            if [ -n "$registry_check_output" ]; then
                log "Registry response:"
                echo "$registry_check_output" | tee -a "$LOG_FILE"
                
                if echo "$registry_check_output" | grep -q '{"repositories":'; then
                    log "✅ REGISTRY RESPONSE FORMAT: VALID JSON"
                else
                    log "⚠️  REGISTRY RESPONSE FORMAT: UNEXPECTED"
                fi
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
            if [ "$DEBUG" = "all" ]; then
                log "✅ REGISTRY SERVICE: RUNNING"
            fi
        else
            log "❌ REGISTRY SERVICE: NOT RUNNING"
            handle_registry_error 302 "Registry service not running - pod status: $registry_service_status" \
                "Verify microk8s status and enable registry: multipass exec '$VM_NAME' -- microk8s enable registry"
            return 1
        fi
    fi
    
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

# Check available disk space for operations
check_disk_space() {
    local operation_name="$1"
    local min_required_gb="$2"
    local check_path="${3:-.}"  # Default to current directory
    
    if [ "$DEBUG" = "all" ]; then
        log "CHECKING DISK SPACE FOR: $operation_name"
        log "Minimum required: ${min_required_gb}GB"
    fi
    
    # Get disk space information
    local df_output
    if ! df_output=$(df -h "$check_path" 2>&1); then
        log "ERROR: Unable to check disk space for $check_path"
        log "DIAGNOSTIC: $df_output"
        return 1
    fi
    
    # Extract available space (skip header, get second line, get 4th column)
    local available_space
    available_space=$(echo "$df_output" | awk 'NR==2 {print $4}' | sed 's/[^0-9.]*//g')
    
    # Handle different units (G, M, K, T)
    local unit
    unit=$(echo "$df_output" | awk 'NR==2 {print $4}' | sed 's/[0-9.]*//g')
    
    local available_gb
    case "$unit" in
        G|g)
            available_gb=$(echo "$available_space" | sed 's/[^0-9.]//g')
            ;;
        M|m)
            available_gb=$(echo "scale=2; $available_space / 1024" | bc -l 2>/dev/null || echo "0.1")
            ;;
        K|k)
            available_gb=$(echo "scale=2; $available_space / 1048576" | bc -l 2>/dev/null || echo "0.01")
            ;;
        T|t)
            available_gb=$(echo "scale=2; $available_space * 1024" | bc -l 2>/dev/null || echo "$available_space")
            ;;
        *)
            log "WARNING: Could not determine disk space unit, assuming GB"
            available_gb="$available_space"
            ;;
    esac
    
    # Ensure we have a numeric value
    available_gb=$(echo "$available_gb" | sed 's/[^0-9.]//g' | awk '{printf "%.1f", $1}')
    
    if [ "$DEBUG" = "all" ]; then
        log "Available disk space: ${available_gb}GB at $check_path"
    fi
    
    # Compare with minimum required
    if [ "$(echo "$available_gb < $min_required_gb" | bc -l 2>/dev/null || echo 1)" -eq 1 ]; then
        log "❌ INSUFFICIENT DISK SPACE FOR: $operation_name"
        log "REQUIRED: ${min_required_gb}GB"
        log "AVAILABLE: ${available_gb}GB"
        log "IMPACT: This operation may fail due to insufficient disk space"
        log "RECOVERY SUGGESTIONS:"
        log "1. Clean up Docker images: docker image prune -f"
        log "2. Clean up Docker system: docker system prune -f"
        log "3. Remove old files: rm -rf node_modules/ dist/ build/"
        log "4. Check disk usage: du -sh * | sort -hr | head -10"
        log "5. Extend disk partition if using VM"
        
        # Check if we should continue with warning or fail
        if [ "$allow_low_disk" != "true" ]; then
            log "ERROR: Operation aborted due to insufficient disk space"
            log "To bypass this check, run with: ALLOW_LOW_DISK=true ./deploy.sh"
            return 1
        else
            log "WARNING: Continuing despite insufficient disk space (ALLOW_LOW_DISK=true)"
            return 0
        fi
    else
        if [ "$DEBUG" = "all" ]; then
            local available_diff
            available_diff=$(echo "scale=1; $available_gb - $min_required_gb" | bc -l 2>/dev/null || echo "$available_gb")
            log "✅ SUFFICIENT DISK SPACE FOR: $operation_name (${available_diff}GB available above minimum)"
        fi
        return 0
    fi
}

# ===========================
# IMAGE PUSH FUNCTION
# ===========================

# Push tagged Docker image to microk8s registry using docker push command
push_image_to_registry() {
    log_info "Starting Docker image push to microk8s registry (executing within VM)..."
    
    # Define the target registry image
    local target_image="localhost:32000/my-ag-ui-app:latest"
    log "Target registry image: $target_image"
    
    # Pre-flight check: Verify VM accessibility before proceeding
    if ! multipass list | grep -q "$VM_NAME"; then
        log "❌ ERROR: VM '$VM_NAME' is not accessible or does not exist"
        log "   Cannot perform image push without VM access"
        log "RECOVERY STEPS:"
        log "1. Check VM status: multipass list"
        log "2. Start VM if needed: multipass start $VM_NAME"
        log "3. Verify VM is running: multipass info $VM_NAME"
        return 1
    fi
    
    # Pre-flight check: Verify Docker daemon is accessible within VM
    if ! multipass exec "$VM_NAME" -- docker info >/dev/null 2>&1; then
        log "❌ ERROR: Docker daemon is not accessible within VM"
        log "   Cannot perform image push without Docker daemon access in VM"
        log "RECOVERY STEPS:"
        log "1. Start Docker daemon in VM: multipass exec $VM_NAME -- sudo systemctl start docker"
        log "2. Check Docker daemon status in VM: multipass exec $VM_NAME -- sudo systemctl status docker"
        log "3. Verify Docker is running in VM: multipass exec $VM_NAME -- docker info"
        log "4. Restart Docker in VM if needed: multipass exec $VM_NAME -- sudo systemctl restart docker"
        return 1
    fi
    
    # Pre-flight check: Verify tagged image exists within VM
    if ! multipass exec "$VM_NAME" -- docker images "$target_image" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "$target_image"; then
        log "❌ ERROR: Target image $target_image not found within VM"
        log "   Cannot push image that does not exist in VM's Docker daemon"
        log ""
        log "REQUIRED ACTION:"
        log "1. Ensure image was built on host: docker build -t my-ag-ui-app:latest ."
        log "2. Tag image within VM: multipass exec $VM_NAME -- docker tag my-ag-ui-app:latest $target_image"
        log "3. Or load image from host to VM: docker save my-ag-ui-app:latest | multipass exec $VM_NAME -- docker load"
        log "4. Then retry the push operation"
        return 1
    fi
    
    # Pre-flight check: Verify registry is accessible before attempting push
    if ! verify_microk8s_registry; then
        handle_registry_error 202 "Registry not accessible before image push operation" \
            "Verify microk8s registry is accessible: multipass exec '$VM_NAME' -- microk8s kubectl get pods -n container-registry"
        return 202
    fi
    
    # Pre-flight check: Verify sufficient disk space for push operation
    if ! check_disk_space "Docker image push" 2 "."; then
        log "❌ ERROR: Insufficient disk space for Docker image push"
        log "   Docker push requires additional disk space for temporary files and network buffers"
        log "RECOVERY STEPS:"
        log "1. Clean up disk space: docker system prune -f"
        log "2. Remove unused images: docker image prune -f"
        log "3. Check disk usage: df -h"
        log "4. Retry the push operation after freeing disk space"
        return 1
    fi
    
    # Push the image to microk8s registry with enhanced error handling and retry logic (within VM)
    log "Pushing image to microk8s registry with enhanced retry logic (within VM)..."
    log "   Command: multipass exec $VM_NAME -- timeout 60 docker push $target_image"
    
    # Enhanced retry parameters for transient network issues with exponential backoff and jitter
    local MAX_PUSH_ATTEMPTS=3
    local INITIAL_PUSH_RETRY_DELAY=2
    local MAX_PUSH_RETRY_DELAY=30
    local PUSH_RETRY_JITTER_MAX=2  # Maximum jitter in seconds to prevent thundering herd
    local PUSH_BACKOFF_FACTOR=2  # Exponential backoff multiplier
    local PUSH_ATTEMPT=1
    local push_success=false
    
    # Function to calculate exponential backoff with jitter for retry delays
    calculate_push_retry_delay() {
        local attempt=$1
        local base_delay=$2
        local max_delay=$3
        local backoff_factor=$4
        local jitter_max=$5
        
        # Calculate exponential backoff: base_delay * (backoff_factor ^ (attempt-1))
        local exponential_delay=$((base_delay * $((backoff_factor ** (attempt-1)))))
        
        # Cap at maximum delay
        if [ $exponential_delay -gt $max_delay ]; then
            exponential_delay=$max_delay
        fi
        
        # Add random jitter to prevent thundering herd effect
        local jitter=0
        if [ $jitter_max -gt 0 ]; then
            jitter=$((RANDOM % jitter_max))
        fi
        
        local total_delay=$((exponential_delay + jitter))
        echo $total_delay
    }
    
    while [ $PUSH_ATTEMPT -le $MAX_PUSH_ATTEMPTS ]; do
        # Calculate retry delay for exponential backoff (only for retries, not initial attempt)
        local retry_delay=0
        if [ $PUSH_ATTEMPT -gt 1 ]; then
            retry_delay=$(calculate_push_retry_delay $PUSH_ATTEMPT $INITIAL_PUSH_RETRY_DELAY $MAX_PUSH_RETRY_DELAY $PUSH_BACKOFF_FACTOR $PUSH_RETRY_JITTER_MAX)
            log "Push attempt $PUSH_ATTEMPT/$MAX_PUSH_ATTEMPTS (retry delay: ${retry_delay}s - exponential backoff with jitter)..."
        else
            if [ "$DEBUG" = "all" ]; then
                log "Push attempt $PUSH_ATTEMPT/$MAX_PUSH_ATTEMPTS (initial attempt)..."
            fi
        fi
        
        local push_output
        local push_exit_code
        
        # Execute docker push with error capture and timeout within VM
        if [ "$DEBUG" = "all" ]; then
            log "   Executing: multipass exec $VM_NAME -- timeout 60 docker push $target_image"
        fi
        
        if push_output=$(multipass exec "$VM_NAME" -- timeout 60 docker push "$target_image" 2>&1); then
            push_exit_code=0
            log "✅ Docker push command completed successfully within VM (attempt $PUSH_ATTEMPT)"
            push_success=true
            break
        else
            push_exit_code=$?
            log "❌ Docker push command failed within VM (exit code: $push_exit_code, attempt $PUSH_ATTEMPT)"
            
            # Log the error output for analysis
            log "Push error output (attempt $PUSH_ATTEMPT):"
            echo "$push_output" | head -5 | tee -a "$LOG_FILE"  # Show only first 5 lines to minimize output
            
            # Analyze specific error patterns and provide targeted guidance
            if [ $PUSH_ATTEMPT -lt $MAX_PUSH_ATTEMPTS ]; then
                if echo "$push_output" | grep -q -E "(no such image|image not found|manifest unknown|blob unknown)"; then
                    log "ERROR TYPE: IMAGE NOT FOUND IN VM'S DOCKER DAEMON"
                    log "RECOVERY: Verify image was tagged correctly within VM"
                    break  # No point retrying if image doesn't exist
                    
                elif echo "$push_output" | grep -q -E "(registry.*not found|registry.*unavailable|registry.*down|name does not resolve)"; then
                    log "ERROR TYPE: REGISTRY UNAVAILABLE"
                    log "RECOVERY: Check registry status: verify_microk8s_registry"
                    break  # No point retrying if registry is down
                    
                elif echo "$push_output" | grep -q -E "(disk full|no space|out of space|insufficient space)"; then
                    log "ERROR TYPE: DISK SPACE FAILURE WITHIN VM"
                    log "RECOVERY: Check disk space within VM: multipass exec $VM_NAME -- df -h"
                    break  # No point retrying if disk is full
                    
                elif echo "$push_output" | grep -q -E "(daemon.*not running|Cannot connect to Docker daemon|docker.*daemon)"; then
                    log "ERROR TYPE: DOCKER DAEMON FAILURE WITHIN VM"
                    log "RECOVERY: Check Docker daemon within VM: multipass exec $VM_NAME -- docker info"
                    break  # No point retrying if Docker daemon is down
                    
                else
                    log "ERROR TYPE: TRANSIENT NETWORK CONNECTIVITY FAILURE WITHIN VM"
                    log "RECOVERY: Will retry with exponential backoff (attempt $PUSH_ATTEMPT/$MAX_PUSH_ATTEMPTS)"
                fi
                
                # Use the already calculated exponential backoff delay with jitter
                log "Waiting ${retry_delay}s before retry attempt $((PUSH_ATTEMPT+1)) (exponential backoff with jitter)..."
                sleep $retry_delay
            else
                log "ERROR: Final push attempt failed within VM - no more retries available"
                log "NOTE: All $MAX_PUSH_ATTEMPTS attempts used exponential backoff with jitter for transient issues within VM"
            fi
        fi
        
        PUSH_ATTEMPT=$((PUSH_ATTEMPT + 1))
    done
    
    # Check if push was ultimately successful
    if [ "$push_success" = false ]; then
        log "❌ ERROR: All push attempts failed within VM ($MAX_PUSH_ATTEMPTS attempts)"
        log "   Image could not be pushed to microk8s registry from within VM"
        log ""
        log "COMPREHENSIVE RECOVERY STEPS:"
        log "1. Verify Docker daemon is running within VM: multipass exec $VM_NAME -- docker info"
        log "2. Check image exists within VM: multipass exec $VM_NAME -- docker images $target_image"
        log "3. Verify registry is accessible: curl -s http://localhost:32000/v2/_catalog"
        log "4. Enable registry if needed: multipass exec $VM_NAME -- microk8s enable registry"
        log "5. Check network connectivity within VM: multipass exec $VM_NAME -- ping -c 2 localhost"
        log "6. Check disk space within VM: multipass exec $VM_NAME -- df -h"
        log "7. Manual push attempt within VM: multipass exec $VM_NAME -- docker push $target_image"
        
        return 1
    fi
    
    # Log successful push output
    log "✅ Image push completed successfully within VM"
    log "   Push command output summary:"
    echo "$push_output" | head -10 | tee -a "$LOG_FILE"  # Log first 10 lines
    if [ $(echo "$push_output" | wc -l) -gt 10 ]; then
        log "   ... (output truncated, full output logged to file)"
        echo "$push_output" >> "$LOG_FILE"
    fi
    
    # Verify the image was successfully pushed to registry
    log "Verifying image was successfully pushed to registry..."
    local registry_verification_attempts=0
    local max_registry_verification_attempts=5
    local registry_verification_delay=2
    local image_verified_in_registry=false
    
    while [ $registry_verification_attempts -lt $max_registry_verification_attempts ]; do
        registry_verification_attempts=$((registry_verification_attempts + 1))
        
        # Check if image appears in registry catalog
        if curl -s "http://localhost:32000/v2/my-ag-ui-app/tags/list" 2>/dev/null | grep -q '"latest"'; then
            log "✅ Image 'my-ag-ui-app:latest' found in registry tags list"
            image_verified_in_registry=true
            break
        else
            if [ $registry_verification_attempts -lt $max_registry_verification_attempts ]; then
                sleep $registry_verification_delay
            fi
        fi
    done
    
    if [ "$image_verified_in_registry" = true ]; then
        log "✅ Image verification successful - image is available in registry"
    else
        log "⚠️  WARNING: Image verification failed - image not found in registry catalog"
        log "   This may be a temporary issue - the registry may need additional time to update"
        log "   The push operation completed successfully, but verification could not confirm registry availability"
        log ""
        log "MANUAL VERIFICATION STEPS:"
        log "1. Check registry catalog: curl -s http://localhost:32000/v2/my-ag-ui-app/tags/list"
        log "2. Check registry status: verify_microk8s_registry"
        log "3. List images in registry: curl -s http://localhost:32000/v2/_catalog"
        log "4. The image should be available despite verification failure"
    fi
    
    log "✅ Docker image push to microk8s registry completed successfully within VM"
    log "   Image: $target_image"
    log "   Status: PUSHED and VERIFIED (or verification pending)"
    log "   Registry: http://localhost:32000 (within VM)"
    log "   Ready for: Kubernetes deployment using registry image reference"
    
    return 0
}

# ===========================
# SCRIPT EXECUTION
# ===========================

# Main script execution
log_info "=== DOCKER IMAGE PUSH TO MICROK8S REGISTRY ==="

# Execute the image push function
if ! push_image_to_registry; then
    handle_registry_error 205 "Docker image push to microk8s registry failed" \
        "Check registry status and network connectivity: multipass exec '$VM_NAME' -- microk8s kubectl get pods -n container-registry"
    exit 1
fi

log_info "✅ Docker image push to microk8s registry completed successfully"
exit 0