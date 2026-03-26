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
    
    log_info() {
        local message="$1"
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
    
    log_structured_error() {
        local error_type="$1"
        local diagnostic="$2"
        local common_causes="$3"
        local recovery="$4"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        echo "[$timestamp] ══════════════════════════════════════════════════════════════════════════════" | tee -a "$LOG_FILE"
        echo "[$timestamp]                          STRUCTURED ERROR" | tee -a "$LOG_FILE"
        echo "[$timestamp] ══════════════════════════════════════════════════════════════════════════════" | tee -a "$LOG_FILE"
        echo "[$timestamp] ERROR TYPE: $error_type" | tee -a "$LOG_FILE"
        echo "[$timestamp] DIAGNOSTIC: $diagnostic" | tee -a "$LOG_FILE"
        echo "[$timestamp] COMMON CAUSES: $common_causes" | tee -a "$LOG_FILE"
        echo "[$timestamp] RECOVERY: $recovery" | tee -a "$LOG_FILE"
        echo "[$timestamp] ══════════════════════════════════════════════════════════════════════════════" | tee -a "$LOG_FILE"
    }
    
    handle_registry_error() {
        local error_code=$1
        local error_message=$2
        local recovery_suggestion=$3
        
        log_error "$error_message"
        log_structured_error "REGISTRY" "$error_message" "Registry connectivity issues, network problems, or service downtime" "$recovery_suggestion"
        exit "$error_code"
    }
    
    setup_log_file() {
        local log_dir="/tmp"
        local timestamp=$(date '+%Y%m%d-%H%M%S')
        
        # Ensure log directory exists
        mkdir -p "$log_dir"
        
        # Set global log file path if not already set
        if [[ -z "${LOG_FILE:-}" ]]; then
            LOG_FILE="$log_dir/deploy-$timestamp.log"
        fi
        
        # Create log file with header
        echo "=============================================" > "$LOG_FILE"
        echo "  DEPLOYMENT LOG - $timestamp" >> "$LOG_FILE"
        echo "=============================================" >> "$LOG_FILE"
        echo "" >> "$LOG_FILE"
        echo "Log file created: $LOG_FILE"
        echo "Deployment started at: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
        echo "" >> "$LOG_FILE"
        
        log_info "Log file initialized: $LOG_FILE"
    }
    
    verify_command() {
        local command_description="$1"
        local command_to_execute="$2"
        local error_type="${3:-GENERAL}"
        local recovery_suggestion="${4:-Check the command syntax and ensure all dependencies are available}"
        
        log_info "Executing: $command_description"
        
        # Execute the command and capture both output and exit code
        local output
        if ! output=$(${command_to_execute} 2>&1); then
            local exit_code=$?
            log_error "Command failed: $command_description"
            log_error "Exit code: $exit_code"
            log_error "Command output: $output"
            
            # Use structured error logging for detailed failure information
            log_structured_error "$error_type" "Command '$command_description' failed with exit code $exit_code" "Command syntax error, missing dependencies, permission issues, or system resource constraints" "$recovery_suggestion"
            
            # Exit with the original command's exit code, or use error code 1 if it's 0
            if [[ $exit_code -eq 0 ]]; then
                exit 1
            else
                exit $exit_code
            fi
        fi
        
        # Log success and output if verbose mode is enabled
        log_info "Command succeeded: $command_description"
        if [[ "${VERBOSE:-false}" == "true" ]]; then
            echo "Command output: $output" | tee -a "$LOG_FILE"
        fi
        
        return 0
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
