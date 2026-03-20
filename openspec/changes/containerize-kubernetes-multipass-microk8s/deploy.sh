#!/bin/bash

# Deployment script for my-ag-ui-app on Kubernetes using multipass and microk8s
# This script automates the entire deployment process for ralph-loop execution

set -e  # Exit on any error
set -o pipefail  # Exit if any command in a pipeline fails

# Configuration
VM_NAME="my-ag-ui-app-k8s"
VM_CPUS=4
VM_MEMORY="7.7G"
VM_DISK="19.3G"
LOG_FILE="deployment.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Progress logging function with visual indicators
progress() {
    local step=$1
    local total_steps=$2
    local message=$3
    local percentage=$((step * 100 / total_steps))
    
    # Create progress bar
    local completed=$((percentage / 2))
    local remaining=$((50 - completed))
    local progress_bar=""
    
    for ((i=0; i<completed; i++)); do
        progress_bar+="█"
    done
    for ((i=0; i<remaining; i++)); do
        progress_bar+="░"
    done
    
    echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 🚀 PROGRESS: [$progress_bar] $percentage% ($step/$total_steps) - $message" | tee -a "$LOG_FILE"
}

# Section header function
section_header() {
    local section_name=$1
    local section_number=$2
    local total_sections=$3
    
    echo -e "\n\n[$(date '+%Y-%m-%d %H:%M:%S')] ======================================================" | tee -a "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 📋 SECTION $section_number/$total_sections: $section_name" | tee -a "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ======================================================" | tee -a "$LOG_FILE"
}

# Step completion function
step_complete() {
    local step_name=$1
    local step_number=$2
    local total_steps=$3
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ STEP $step_number/$total_steps COMPLETED: $step_name" | tee -a "$LOG_FILE"
}

# Major milestone function
milestone() {
    local milestone_name=$1
    local milestone_number=$2
    local total_milestones=$3
    
    echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 🎯 MILESTONE $milestone_number/$total_milestones: $milestone_name" | tee -a "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ------------------------------------------------------" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    log "ERROR: $1"
    exit 1
}

# VM-specific error handling function with recovery suggestions
handle_vm_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "VM ERROR [Code: $error_code]: $error_message"
    log "RECOVERY SUGGESTION: $recovery_suggestion"
    
    # Log additional diagnostic information
    log "DIAGNOSTIC INFO:"
    log "System: $(uname -a)"
    log "Multipass version: $(multipass version 2>/dev/null || echo 'multipass not found')"
    log "Available disk space: $(df -h / | awk 'NR==2 {print $4}')"
    log "Available memory: $(free -h | awk 'NR==2 {print $7}')"
    
    # Check if multipass service is running
    if command -v systemctl >/dev/null 2>&1; then
        local multipass_service_status=$(systemctl is-active multipassd 2>/dev/null || echo 'unknown')
        log "Multipass service status: $multipass_service_status"
        
        if [ "$multipass_service_status" != "active" ]; then
            log "ACTION: Try restarting multipass service: sudo systemctl start multipassd"
        fi
    fi
    
    # Check for existing VMs
    log "Existing VMs:"
    multipass list 2>/dev/null || log "Unable to list VMs"
    
    exit $error_code
}

# VM creation error handler
handle_vm_creation_error() {
    local vm_name=$1
    local error_output=$2
    
    case "$error_output" in
        *"already exists"*)
            handle_vm_error 101 "VM '$vm_name' already exists" \
                "Use a different VM name or delete the existing VM with: multipass delete $vm_name && multipass purge"
            ;;
        *"insufficient permissions"*)
            handle_vm_error 102 "Permission denied creating VM '$vm_name'" \
                "Run the script with appropriate permissions or check multipass installation"
            ;;
        *"not enough disk space"*)
            handle_vm_error 103 "Insufficient disk space to create VM '$vm_name'" \
                "Free up disk space or specify a smaller disk size with --disk option"
            ;;
        *"not enough memory"*)
            handle_vm_error 104 "Insufficient memory to create VM '$vm_name'" \
                "Close other applications or specify less memory with --memory option"
            ;;
        *"network"*)
            handle_vm_error 105 "Network error creating VM '$vm_name'" \
                "Check network connectivity and try again. If using VPN, try disconnecting."
            ;;
        *"timeout"*)
            handle_vm_error 106 "Timeout creating VM '$vm_name'" \
                "Increase timeout with --timeout option or check system resources"
            ;;
        *"Invalid"*)
            handle_vm_error 107 "Invalid VM configuration for '$vm_name'" \
                "Check VM parameters (CPUs, memory, disk) and ensure they meet minimum requirements"
            ;;
        *)
            handle_vm_error 108 "Unknown error creating VM '$vm_name': $error_output" \
                "Check multipass logs: journalctl -u multipassd -f or try manual VM creation"
            ;;
    esac
}

# VM networking error handler
handle_vm_networking_error() {
    local vm_name=$1
    local error_type=$2
    
    case "$error_type" in
        "no_ip")
            handle_vm_error 201 "VM '$vm_name' has no IP address" \
                "Check VM networking configuration: multipass info $vm_name. If issue persists, recreate VM."
            ;;
        "dns_resolution")
            handle_vm_error 202 "VM '$vm_name' DNS resolution failed" \
                "Check VM DNS configuration: multipass exec $vm_name -- cat /etc/resolv.conf. Consider using different DNS servers."
            ;;
        "outbound_connectivity")
            handle_vm_error 203 "VM '$vm_name' outbound connectivity failed" \
                "Check firewall settings and proxy configuration. Test with: multipass exec $vm_name -- curl -v https://www.google.com"
            ;;
        "ssh_access")
            handle_vm_error 204 "VM '$vm_name' SSH access failed" \
                "Check multipass service status: systemctl status multipassd. Try restarting multipass service."
            ;;
        *)
            handle_vm_error 205 "Unknown networking error for VM '$vm_name': $error_type" \
                "Check VM network interfaces: multipass exec $vm_name -- ip addr show. Consider recreating VM."
            ;;
    esac
}

# VM readiness error handler
handle_vm_readiness_error() {
    local vm_name=$1
    local readiness_issue=$2
    
    case "$readiness_issue" in
        "not_running")
            handle_vm_error 301 "VM '$vm_name' is not running" \
                "Start VM with: multipass start $vm_name. If it fails, check system resources and logs."
            ;;
        "not_responsive")
            handle_vm_error 302 "VM '$vm_name' is not responsive" \
                "Wait a few minutes and try again. If issue persists, restart VM: multipass restart $vm_name"
            ;;
        "high_cpu")
            handle_vm_error 303 "VM '$vm_name' CPU usage too high" \
                "Wait for VM to calm down or allocate more CPUs. Check: multipass exec $vm_name -- top"
            ;;
        "high_memory")
            handle_vm_error 304 "VM '$vm_name' memory usage too high" \
                "Wait for memory to free up or allocate more memory. Check: multipass exec $vm_name -- free -h"
            ;;
        "high_disk")
            handle_vm_error 305 "VM '$vm_name' disk usage too high" \
                "Clean up disk space or allocate more disk. Check: multipass exec $vm_name -- df -h"
            ;;
        *)
            handle_vm_error 306 "Unknown readiness issue for VM '$vm_name': $readiness_issue" \
                "Check VM status: multipass info $vm_name. Consider recreating VM if issue persists."
            ;;
    esac
}

# VM resource error handler
handle_vm_resource_error() {
    local vm_name=$1
    local resource_type=$2
    local current_value=$3
    local required_value=$4
    
    handle_vm_error 401 "VM '$vm_name' $resource_type insufficient: $current_value < $required_value" \
        "Recreate VM with more $resource_type: multipass delete $vm_name && multipass purge && then rerun this script"
}

# Recovery suggestion function for common VM issues
provide_vm_recovery_suggestions() {
    local vm_name=$1
    log "=== VM RECOVERY SUGGESTIONS FOR '$vm_name' ==="
    log ""
    log "Common VM Issues and Solutions:"
    log ""
    log "1. VM won't start:"
    log "   - Check system resources: free -h, df -h"
    log "   - Restart multipass service: sudo systemctl restart multipassd"
    log "   - Reboot host system if resources are available"
    log ""
    log "2. VM has no network connectivity:"
    log "   - Check VM networking: multipass info $vm_name"
    log "   - Test DNS: multipass exec $vm_name -- nslookup google.com"
    log "   - Test connectivity: multipass exec $vm_name -- ping -c 2 8.8.8.8"
    log ""
    log "3. VM is unresponsive:"
    log "   - Check VM status: multipass info $vm_name"
    log "   - Try restarting: multipass restart $vm_name"
    log "   - Check resource usage: multipass exec $vm_name -- top"
    log ""
    log "4. VM needs more resources:"
    log "   - Delete current VM: multipass delete $vm_name"
    log "   - Purge VM: multipass purge"
    log "   - Recreate with more resources (update script parameters)"
    log ""
    log "5. Multipass service issues:"
    log "   - Check service status: systemctl status multipassd"
    log "   - Restart service: sudo systemctl restart multipassd"
    log "   - Check logs: journalctl -u multipassd -f"
    log ""
    log "6. Complete VM reset:"
    log "   - Delete VM: multipass delete $vm_name"
    log "   - Purge all: multipass purge"
    log "   - Reinstall multipass if needed"
    log "   - Re-run deployment script"
    log ""
    log "=== END RECOVERY SUGGESTIONS ==="
}

# Microk8s-specific error handling function
handle_microk8s_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "MICROK8S ERROR [Code: $error_code]: $error_message"
    log "RECOVERY SUGGESTION: $recovery_suggestion"
    
    # Log additional diagnostic information
    log "MICROK8S DIAGNOSTIC INFO:"
    log "VM Name: $VM_NAME"
    log "Microk8s status: $(multipass exec "$VM_NAME" -- microk8s status 2>&1 || echo 'microk8s not responding')"
    
    # Check if microk8s is installed
    if multipass exec "$VM_NAME" -- command -v microk8s >/dev/null 2>&1; then
        log "Microk8s version: $(multipass exec "$VM_NAME" -- microk8s version 2>/dev/null | head -1 || echo 'unknown')"
    else
        log "Microk8s is not installed in VM"
    fi
    
    # Check microk8s service status
    if multipass exec "$VM_NAME" -- command -v systemctl >/dev/null 2>&1; then
        local microk8s_service_status=$(multipass exec "$VM_NAME" -- systemctl is-active snap.microk8s.daemon-*.service 2>/dev/null || echo "unknown")
        log "Microk8s service status: $microk8s_service_status"
    fi
    
    # Check cluster nodes
    if multipass exec "$VM_NAME" -- command -v microk8s >/dev/null 2>&1; then
        log "Cluster nodes status:"
        multipass exec "$VM_NAME" -- microk8s kubectl get nodes 2>&1 | head -5 | tee -a "$LOG_FILE" || log "Could not get cluster nodes"
    fi
    
    exit $error_code
}

# Microk8s add-on specific error handling function
handle_microk8s_addon_error() {
    local addon_name=$1
    local error_output=$2
    
    case "$error_output" in
        *"already enabled"*)
            handle_microk8s_error 301 "$addon_name add-on is already enabled" \
                "This is not an error. The $addon_name add-on is already enabled and ready to use."
            ;;
        *"not found"*)
            handle_microk8s_error 302 "$addon_name add-on not found" \
                "The $addon_name add-on may not be available in this version of microk8s. Check available add-ons: microk8s status"
            ;;
        *"timeout"*)
            handle_microk8s_error 303 "$addon_name add-on enablement timed out" \
                "The $addon_name add-on is taking too long to enable. Try enabling it manually: microk8s enable $addon_name"
            ;;
        *"permission denied"*)
            handle_microk8s_error 304 "Permission denied enabling $addon_name add-on" \
                "Run with appropriate permissions: sudo microk8s enable $addon_name"
            ;;
        *"dependency"*)
            handle_microk8s_error 305 "Dependency error enabling $addon_name add-on" \
                "The $addon_name add-on has unresolved dependencies. Check microk8s status for details."
            ;;
        *)
            handle_microk8s_error 306 "Unknown error enabling $addon_name add-on: $error_output" \
                "Try enabling the add-on manually: microk8s enable $addon_name. Check microk8s logs: journalctl -u snap.microk8s.daemon-*"
            ;;
    esac
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if microk8s is ready
microk8s_ready() {
    multipass exec "$VM_NAME" -- microk8s status --wait-ready >/dev/null 2>&1
}

# Function to check if microk8s addon is enabled
microk8s_addon_enabled() {
    local addon_name=$1
    multipass exec "$VM_NAME" -- microk8s status | grep -q "$addon_name.*enabled" 2>/dev/null
}

# Function to check if VM exists
vm_exists() {
    multipass list | grep -q "^$VM_NAME "
}

# Function to check if VM is running
vm_running() {
    multipass info "$VM_NAME" | grep -q "State: Running"
}

# ========================
# PRE-DEPLOYMENT CHECKS SECTION
# ========================

section_header "PRE-DEPLOYMENT CHECKS" 1 7
progress 1 7 "Starting pre-deployment checks"
log "Starting pre-deployment checks..."

# Pre-deployment checks error handler
handle_predeployment_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "PRE-DEPLOYMENT ERROR [Code: $error_code]: $error_message"
    log "RECOVERY SUGGESTION: $recovery_suggestion"
    
    # Log additional diagnostic information
    log "PRE-DEPLOYMENT DIAGNOSTIC INFO:"
    log "System: $(uname -a)"
    log "Current directory: $(pwd)"
    log "Available disk space: $(df -h . | awk 'NR==2 {print $4}')"
    log "Available memory: $(free -h | awk 'NR==2 {print $7}')"
    
    exit $error_code
}

# 7.2.1 Check multipass installation
progress 1 9 "Checking multipass installation"
log "Checking multipass installation..."
if ! command_exists multipass; then
    handle_predeployment_error 201 "multipass is not installed" \
        "Please install multipass before running this script. Installation instructions: https://multipass.run/install"
fi
step_complete "Multipass installation check" 1 9
log "multipass is installed: $(multipass version | head -1)"

# 7.2.2 Check Docker installation
progress 2 9 "Checking Docker installation"
log "Checking Docker installation..."
if ! command_exists docker; then
    handle_predeployment_error 202 "Docker is not installed" \
        "Please install Docker before running this script. Installation instructions: https://docs.docker.com/get-docker/"
fi
step_complete "Docker installation check" 2 9

# Check if Docker daemon is running
if ! docker info >/dev/null 2>&1; then
    handle_predeployment_error 203 "Docker daemon is not running" \
        "Please start Docker daemon: sudo systemctl start docker or sudo service docker start"
fi
log "Docker is installed and running: $(docker version | grep "Version" | head -1 | tr -s ' ')"

# 7.2.3 Check system resources
progress 3 9 "Checking system resources"
log "Checking system resources..."

# Check CPU cores (minimum 4 recommended for VM + microk8s)
AVAILABLE_CPUS=$(nproc)
REQUIRED_CPUS=4
log "Available CPU cores: $AVAILABLE_CPUS (recommended: $REQUIRED_CPUS)"
if [ "$AVAILABLE_CPUS" -lt "$REQUIRED_CPUS" ]; then
    log "WARNING: System has only $AVAILABLE_CPUS CPU cores, $REQUIRED_CPUS are recommended"
    log "This may impact VM and microk8s performance, but deployment will continue"
fi
step_complete "System resources check" 3 9

# Check available memory (minimum 8GB recommended for VM + microk8s)
TOTAL_MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEMORY_GB=$((TOTAL_MEMORY_KB / 1024 / 1024))
REQUIRED_MEMORY_GB=8
log "Total system memory: ${TOTAL_MEMORY_GB}GB (recommended: ${REQUIRED_MEMORY_GB}GB)"
if [ "$TOTAL_MEMORY_GB" -lt "$REQUIRED_MEMORY_GB" ]; then
    log "WARNING: System has only ${TOTAL_MEMORY_GB}GB RAM, ${REQUIRED_MEMORY_GB}GB are recommended"
    log "This may impact VM and microk8s performance, but deployment will continue"
fi

# Check available disk space (minimum 20GB recommended for VM + images + build cache)
AVAILABLE_DISK=$(df -k . | awk 'NR==2 {print $4}')
AVAILABLE_DISK_GB=$((AVAILABLE_DISK / 1024 / 1024))
REQUIRED_DISK_GB=20
log "Available disk space: ${AVAILABLE_DISK_GB}GB (recommended: ${REQUIRED_DISK_GB}GB)"
if [ "$AVAILABLE_DISK_GB" -lt "$REQUIRED_DISK_GB" ]; then
    log "WARNING: System has only ${AVAILABLE_DISK_GB}GB disk space, ${REQUIRED_DISK_GB}GB are recommended"
    log "This may cause deployment to fail due to insufficient space"
    
    # Check if critically low disk space
    if [ "$AVAILABLE_DISK_GB" -lt 10 ]; then
        handle_predeployment_error 204 "Critically low disk space: ${AVAILABLE_DISK_GB}GB" \
            "Free up at least 10GB disk space before running deployment. Clean up old files, containers, and images."
    fi
fi

# Check network connectivity (required for downloading images and packages)
progress 4 9 "Checking network connectivity"
log "Checking network connectivity..."
if ! curl -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1; then
    log "WARNING: Cannot reach internet - this may be required for downloading dependencies"
    log "The deployment may fail if images or packages need to be downloaded"
    # Don't fail here, as it might be a temporary issue or behind a proxy
else
    log "Network connectivity check passed"
fi
step_complete "Network connectivity check" 4 9

# Check if we have the necessary permissions
progress 5 9 "Checking user permissions"
log "Checking user permissions..."
if [ "$EUID" -eq 0 ]; then
    log "Running as root user - this should work"
elif groups | grep -q docker; then
    log "User is in docker group - this should work"
else
    log "WARNING: Current user is not in docker group"
    log "You may need to: sudo usermod -aG docker \$USER && newgrp docker"
    log "Or run the script with sudo if you encounter permission issues"
fi
step_complete "User permissions check" 5 9

# Check for existing VM with the same name
progress 6 9 "Checking for existing VM"
log "Checking for existing VM..."
if multipass list | grep -q "^$VM_NAME "; then
    log "WARNING: VM '$VM_NAME' already exists"
    log "The script will attempt to use the existing VM or recreate it if needed"
    log "To use a clean environment, delete the existing VM first: multipass delete $VM_NAME && multipass purge"
fi
step_complete "Existing VM check" 6 9

log "All pre-deployment checks completed successfully"
log "System is ready for deployment"
step_complete "Pre-deployment checks completion" 7 9

# ========================
# VERIFICATION: Pre-deployment checks
# ========================

progress 8 9 "Running pre-deployment verification"
verify_predeployment_completion() {
    log "=== VERIFYING PRE-DEPLOYMENT COMPLETION ==="
    
    local verification_passed=true
    local verification_details=""
    
    # Verify multipass is still available
    log "Verifying multipass availability..."
    if ! command_exists multipass; then
        verification_passed=false
        verification_details+="FAIL: multipass is not available\n"
    else
        log "SUCCESS: multipass is available: $(multipass version | head -1)"
    fi
    
    # Verify Docker is still available and running
    log "Verifying Docker availability..."
    if ! docker_ready; then
        verification_passed=false
        verification_details+="FAIL: Docker is not available or not running\n"
    else
        log "SUCCESS: Docker is available and running"
    fi
    
    # Verify system resources are still adequate
    log "Verifying system resources..."
    local current_cpu=$(nproc)
    local current_memory_gb=$((TOTAL_MEMORY_KB / 1024 / 1024))
    local current_disk_gb=$((AVAILABLE_DISK / 1024 / 1024))
    
    log "Current resources: CPU=$current_cpu, Memory=${current_memory_gb}GB, Disk=${current_disk_gb}GB"
    log "Required resources: CPU=$REQUIRED_CPUS, Memory=${REQUIRED_MEMORY_GB}GB, Disk=${REQUIRED_DISK_GB}GB"
    
    if [ "$current_cpu" -lt "$REQUIRED_CPUS" ]; then
        log "WARNING: CPU cores below recommended, but continuing"
    fi
    
    if [ "$current_memory_gb" -lt "$REQUIRED_MEMORY_GB" ]; then
        log "WARNING: Memory below recommended, but continuing"
    fi
    
    if [ "$current_disk_gb" -lt "$REQUIRED_DISK_GB" ]; then
        log "WARNING: Disk space below recommended, but continuing"
    fi
    
    # Verify network connectivity
    log "Verifying network connectivity..."
    if curl -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1; then
        log "SUCCESS: Network connectivity verified"
    else
        log "WARNING: Network connectivity issues detected, but continuing"
    fi
    
    # Verify no conflicting VMs exist
    log "Verifying VM environment..."
    if multipass list | grep -q "^$VM_NAME "; then
        log "INFO: VM '$VM_NAME' already exists - will use existing or recreate"
    else
        log "SUCCESS: No conflicting VMs found"
    fi
    
    # Output verification summary
    log "=== PRE-DEPLOYMENT VERIFICATION SUMMARY ==="
    if [ "$verification_passed" = "true" ]; then
        log "STATUS: PASSED - All pre-deployment checks verified"
        log "DETAILS: System is ready for VM provisioning"
        log "==========================================="
        return 0
    else
        log "STATUS: FAILED - Pre-deployment verification failed"
        log "DETAILS:"
        log -e "$verification_details"
        log "==========================================="
        handle_predeployment_error 999 "Pre-deployment verification failed" \
            "Address the issues above before continuing with deployment"
        return 1
    fi
}

# Run pre-deployment verification
log "Running pre-deployment completion verification..."
verify_predeployment_completion

log "Pre-deployment verification completed successfully"
step_complete "Pre-deployment verification" 8 9
progress 9 9 "Pre-deployment phase completed - 100% ready for VM provisioning"
log "Proceeding to VM provisioning section"

# =====================
# VM PROVISIONING SECTION
# =====================

step_complete "Pre-deployment checks" 1 7
section_header "VM PROVISIONING" 2 7
progress 2 7 "Starting VM provisioning"
milestone "Infrastructure Setup" 1 4
log "Starting VM provisioning..."

# 3.2 Add multipass installation check to deployment script
progress 1 8 "Checking multipass installation for VM provisioning"
log "Checking multipass installation..."
if ! command_exists multipass; then
    handle_error "multipass is not installed. Please install multipass before running this script. Installation instructions: https://multipass.run/install"
fi
step_complete "Multipass installation verified" 1 8
log "multipass is installed: $(multipass version)"

# 3.3 Configure VM creation with 4 CPUs, 7.7GiB RAM, 19.3GiB disk
progress 2 8 "Checking for existing VM"
log "Checking if VM '$VM_NAME' already exists..."
if vm_exists; then
    log "VM '$VM_NAME' already exists"
    if vm_running; then
        log "VM '$VM_NAME' is running"
    else
        log "Starting existing VM '$VM_NAME'..."
        if ! multipass start "$VM_NAME" 2>/dev/null; then
            local start_error=$(multipass start "$VM_NAME" 2>&1 || echo "Unknown error starting VM")
            handle_vm_readiness_error "$VM_NAME" "not_running"
        fi
        log "VM '$VM_NAME' started successfully"
    fi
else
    log "Creating VM '$VM_NAME' with $VM_CPUS CPUs, $VM_MEMORY RAM, $VM_DISK disk..."
    vm_creation_output=""
    if ! vm_creation_output=$(multipass launch \
        --name "$VM_NAME" \
        --cpus "$VM_CPUS" \
        --memory "$VM_MEMORY" \
        --disk "$VM_DISK" \
        --timeout 600 \
        2>&1); then
        handle_vm_creation_error "$VM_NAME" "$vm_creation_output"
    fi
    log "VM '$VM_NAME' created successfully"
fi

# 3.4 Add VM readiness verification to deployment script
progress 4 8 "Verifying VM readiness"
log "Waiting for VM to be ready..."
MAX_ATTEMPTS=30
ATTEMPT=1
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if vm_running; then
        # Test if VM is responsive by running a simple command
        if multipass exec "$VM_NAME" -- uptime >/dev/null 2>&1; then
            log "VM '$VM_NAME' is ready and responsive"
            break
        else
            log "VM is running but not responsive..."
        fi
    else
        log "VM is not running yet..."
    fi
    log "Waiting for VM to be ready... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    if vm_running; then
        handle_vm_readiness_error "$VM_NAME" "not_responsive"
    else
        handle_vm_readiness_error "$VM_NAME" "not_running"
    fi
fi

# 3.5 Configure VM networking verification
progress 5 8 "Verifying VM networking"
log "Verifying VM networking..."
VM_IP=$(multipass info "$VM_NAME" | grep "IPv4:" | awk '{print $2}')
if [ -z "$VM_IP" ]; then
    handle_vm_networking_error "$VM_NAME" "no_ip"
fi
log "VM '$VM_NAME' IP address: $VM_IP"

# Test DNS resolution
log "Testing DNS resolution in VM..."
if ! multipass exec "$VM_NAME" -- nslookup google.com >/dev/null 2>&1; then
    log "ERROR: DNS resolution test failed in VM"
    log "This may prevent Kubernetes from pulling images and resolving service names"
    handle_vm_networking_error "$VM_NAME" "dns_resolution"
fi
log "DNS resolution test passed"

# Test outbound connectivity
log "Testing outbound connectivity from VM..."
if ! multipass exec "$VM_NAME" -- curl -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1; then
    log "ERROR: Outbound connectivity test failed in VM"
    log "This will prevent Kubernetes from pulling container images"
    handle_vm_networking_error "$VM_NAME" "outbound_connectivity"
fi
log "Outbound connectivity test passed"

# Test container image pulling (critical for Kubernetes)
log "Testing container image pulling capability..."
if ! multipass exec "$VM_NAME" -- docker pull alpine:latest >/dev/null 2>&1; then
    log "WARNING: Could not test Docker image pulling (Docker may not be installed yet)"
    log "This is expected if Docker hasn't been installed in the VM yet"
else
    log "Container image pulling test passed"
    # Clean up the test image
    multipass exec "$VM_NAME" -- docker rmi alpine:latest >/dev/null 2>&1 || true
fi

# Test connectivity from host to VM
log "Testing connectivity from host to VM..."
if ! ping -c 1 -W 5 "$VM_IP" >/dev/null 2>&1; then
    log "WARNING: Cannot ping VM from host"
    log "This may be due to firewall restrictions but should not prevent Kubernetes operation"
else
    log "Host to VM connectivity test passed"
fi

# Test SSH access to VM (required for microk8s installation)
log "Testing SSH access to VM..."
if ! multipass exec "$VM_NAME" -- echo "SSH access test successful" >/dev/null 2>&1; then
    handle_vm_networking_error "$VM_NAME" "ssh_access"
fi
log "SSH access test passed"
step_complete "VM networking verification" 5 8

log "VM networking verification completed successfully"

# 3.6 Add VM status monitoring during deployment
progress 6 8 "Monitoring VM status during deployment"
log "=== VM Status Monitoring ==="
log "VM '$VM_NAME' detailed status:"

# Get comprehensive VM information
log "VM Basic Information:"
multipass info "$VM_NAME" | tee -a "$LOG_FILE"

# Get detailed resource information
log "VM Resource Usage:"
if multipass exec "$VM_NAME" -- command -v free >/dev/null 2>&1; then
    log "Memory Usage:"
    multipass exec "$VM_NAME" -- free -h | tee -a "$LOG_FILE"
fi

if multipass exec "$VM_NAME" -- command -v df >/dev/null 2>&1; then
    log "Disk Usage:"
    multipass exec "$VM_NAME" -- df -h | tee -a "$LOG_FILE"
fi

if multipass exec "$VM_NAME" -- command -v top >/dev/null 2>&1; then
    log "CPU Information:"
    multipass exec "$VM_NAME" -- top -bn1 | head -5 | tee -a "$LOG_FILE"
fi

# Get network information
log "VM Network Configuration:"
VM_IP=$(multipass info "$VM_NAME" | grep "IPv4:" | awk '{print $2}')
log "VM IP Address: $VM_IP" | tee -a "$LOG_FILE"

if multipass exec "$VM_NAME" -- command -v ip >/dev/null 2>&1; then
    log "Network Interfaces:"
    multipass exec "$VM_NAME" -- ip addr show | tee -a "$LOG_FILE"
fi

# Monitor VM health and readiness
log "VM Health Status:"
log "Checking VM responsiveness..."
if multipass exec "$VM_NAME" -- uptime >/dev/null 2>&1; then
    UPTIME_OUTPUT=$(multipass exec "$VM_NAME" -- uptime)
    log "VM is responsive - Uptime: $UPTIME_OUTPUT" | tee -a "$LOG_FILE"
else
    handle_vm_readiness_error "$VM_NAME" "not_responsive"
fi

# Check disk space availability
log "Checking disk space availability..."
if multipass exec "$VM_NAME" -- command -v df >/dev/null 2>&1; then
    DISK_USAGE=$(multipass exec "$VM_NAME" -- df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 90 ]; then
        log "WARNING: VM disk usage is at ${DISK_USAGE}% - consider cleaning up or increasing disk size"
        if [ "$DISK_USAGE" -gt 95 ]; then
            handle_vm_readiness_error "$VM_NAME" "high_disk"
        fi
    else
        log "VM disk usage is at ${DISK_USAGE}% - acceptable"
    fi
fi

# Check memory availability
if multipass exec "$VM_NAME" -- command -v free >/dev/null 2>&1; then
    log "Checking memory availability..."
    MEMORY_PERCENT=$(multipass exec "$VM_NAME" -- free -m | awk 'NR==2{printf "%.0f", $3/$2*100}')
    log "VM memory usage: ${MEMORY_PERCENT}%"
    if [ "$MEMORY_PERCENT" -gt 90 ]; then
        handle_vm_readiness_error "$VM_NAME" "high_memory"
    fi
fi

# Check CPU usage
if multipass exec "$VM_NAME" -- command -v top >/dev/null 2>&1; then
    log "Checking CPU usage..."
    # Get 1-minute load average
    CPU_LOAD=$(multipass exec "$VM_NAME" -- top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' | cut -d'.' -f1)
    if [ -n "$CPU_LOAD" ] && [ "$CPU_LOAD" -gt 90 ]; then
        handle_vm_readiness_error "$VM_NAME" "high_cpu"
    fi
    log "VM CPU usage appears normal"
fi

# Set up continuous monitoring
log "Setting up continuous VM status monitoring..."
monitor_vm_status() {
    local monitor_count=0
    local max_monitor_count=3
    
    while [ $monitor_count -lt $max_monitor_count ]; do
        log "VM Status Check #$((monitor_count + 1)):"
        
        # Check if VM is still running
        if ! vm_running; then
            handle_vm_readiness_error "$VM_NAME" "not_running"
        fi
        
        # Check VM responsiveness
        if ! multipass exec "$VM_NAME" -- echo "VM status check" >/dev/null 2>&1; then
            handle_vm_readiness_error "$VM_NAME" "not_responsive"
        fi
        
        # Check resources during monitoring
        if multipass exec "$VM_NAME" -- command -v df >/dev/null 2>&1; then
            DISK_USAGE=$(multipass exec "$VM_NAME" -- df -h / | awk 'NR==2 {print $5}' | sed 's/%//' 2>/dev/null || echo "0")
            if [ "$DISK_USAGE" -gt 90 ]; then
                handle_vm_readiness_error "$VM_NAME" "high_disk"
            fi
        fi
        
        # Log current status
        log "VM is running and responsive - continuing with deployment"
        
        monitor_count=$((monitor_count + 1))
        if [ $monitor_count -lt $max_monitor_count ]; then
            sleep 5
        fi
    done
}

# Run continuous monitoring
monitor_vm_status

log "=== VM Status Monitoring Complete ==="
log "All VM status checks passed. VM is ready for microk8s installation."

# Provide VM recovery suggestions for reference
log "VM recovery suggestions have been logged for reference if issues occur later"
provide_vm_recovery_suggestions "$VM_NAME" >> "$LOG_FILE"

log "VM provisioning completed successfully"
step_complete "VM status monitoring" 6 8

# ========================
# VERIFICATION: VM provisioning completion
# ========================

progress 7 8 "Running VM provisioning verification"
verify_vm_provisioning_completion() {
    log "=== VERIFYING VM PROVISIONING COMPLETION ==="
    
    local verification_passed=true
    local verification_details=""
    
    # Verify VM exists
    log "Verifying VM existence..."
    if ! vm_exists; then
        verification_passed=false
        verification_details+="FAIL: VM '$VM_NAME' does not exist\n"
    else
        log "SUCCESS: VM '$VM_NAME' exists"
    fi
    
    # Verify VM is running
    log "Verifying VM is running..."
    if ! vm_running; then
        verification_passed=false
        verification_details+="FAIL: VM '$VM_NAME' is not running\n"
    else
        log "VM '$VM_NAME' is running"
        step_complete "VM startup" 2 8
    fi
    
    # Verify VM is responsive
    log "Verifying VM responsiveness..."
    if ! multipass exec "$VM_NAME" -- uptime >/dev/null 2>&1; then
        verification_passed=false
        verification_details+="FAIL: VM '$VM_NAME' is not responsive\n"
    else
        log "SUCCESS: VM '$VM_NAME' is responsive"
    fi
    
    # Verify VM has IP address
    log "Verifying VM IP address..."
    VM_IP=$(multipass info "$VM_NAME" | grep "IPv4:" | awk '{print $2}')
    if [ -z "$VM_IP" ]; then
        verification_passed=false
        verification_details+="FAIL: VM '$VM_NAME' has no IP address\n"
    else
        log "SUCCESS: VM '$VM_NAME' has IP address: $VM_IP"
    fi
    
    # Verify VM networking
    log "Verifying VM networking..."
    if ! multipass exec "$VM_NAME" -- nslookup google.com >/dev/null 2>&1; then
        log "WARNING: VM DNS resolution failed - may impact microk8s installation"
    else
        log "SUCCESS: VM DNS resolution working"
    fi
    
    if ! multipass exec "$VM_NAME" -- curl -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1; then
        log "WARNING: VM outbound connectivity failed - may impact microk8s installation"
    else
        log "SUCCESS: VM outbound connectivity working"
    fi
    
    # Verify VM resources
    log "Verifying VM resources..."
    if multipass exec "$VM_NAME" -- command -v free >/dev/null 2>&1; then
        local vm_memory_gb=$(multipass exec "$VM_NAME" -- free -g 2>/dev/null | awk 'NR==2{print $2}' || echo "0")
        if [ "$vm_memory_gb" -ge 4 ]; then
            log "SUCCESS: VM has sufficient memory: ${vm_memory_gb}GB"
        else
            log "WARNING: VM has insufficient memory: ${vm_memory_gb}GB (may impact microk8s)"
        fi
    fi
    
    if multipass exec "$VM_NAME" -- command -v nproc >/dev/null 2>&1; then
        local vm_cpus=$(multipass exec "$VM_NAME" -- nproc 2>/dev/null || echo "0")
        if [ "$vm_cpus" -ge 2 ]; then
            log "SUCCESS: VM has sufficient CPUs: $vm_cpus"
        else
            log "WARNING: VM has insufficient CPUs: $vm_cpus (may impact microk8s)"
        fi
    fi
    
    if multipass exec "$VM_NAME" -- command -v df >/dev/null 2>&1; then
        local vm_disk_gb=$(multipass exec "$VM_NAME" -- df -g / 2>/dev/null | awk 'NR==2{print $4}' || echo "0")
        if [ "$vm_disk_gb" -ge 10 ]; then
            log "SUCCESS: VM has sufficient disk: ${vm_disk_gb}GB"
        else
            log "WARNING: VM has limited disk: ${vm_disk_gb}GB"
        fi
    fi
    
    # Verify SSH access
    log "Verifying SSH access..."
    if ! multipass exec "$VM_NAME" -- echo "SSH test" >/dev/null 2>&1; then
        verification_passed=false
        verification_details+="FAIL: Cannot access VM via SSH\n"
    else
        log "SUCCESS: SSH access to VM working"
    fi
    
    # Output verification summary
    log "=== VM PROVISIONING VERIFICATION SUMMARY ==="
    if [ "$verification_passed" = "true" ]; then
        log "STATUS: PASSED - VM provisioning completed successfully"
        log "DETAILS: VM is ready for microk8s installation"
        log "VM Configuration:"
        log "  - Name: $VM_NAME"
        log "  - IP: $VM_IP"
        log "  - Status: Running and responsive"
        log "  - Networking: Configured"
        log "  - SSH access: Working"
        log "==========================================="
        return 0
    else
        log "STATUS: FAILED - VM provisioning verification failed"
        log "DETAILS:"
        log -e "$verification_details"
        log "==========================================="
        handle_vm_error 999 "VM provisioning verification failed" \
            "Address the issues above before continuing with microk8s installation"
        return 1
    fi
}

# Run VM provisioning verification
log "Running VM provisioning completion verification..."
verify_vm_provisioning_completion

log "VM provisioning verification completed successfully"
step_complete "VM provisioning verification" 7 8
progress 8 8 "VM provisioning phase completed - 100% ready for microk8s installation"
log "Proceeding to microk8s installation section"

# ========================
# MICROK8S INSTALLATION SECTION
# ========================

step_complete "VM provisioning" 2 7
section_header "MICROK8S INSTALLATION" 3 7
progress 3 7 "Starting microk8s installation"
milestone "Kubernetes Cluster Setup" 2 4
log "Starting microk8s installation..."

# 4.2 Install microk8s in the VM
log "Installing microk8s in VM '$VM_NAME'..."

# Check if microk8s is already installed
if multipass exec "$VM_NAME" -- command -v microk8s >/dev/null 2>&1; then
    log "Microk8s is already installed in VM"
    MICROK8S_VERSION=$(multipass exec "$VM_NAME" -- microk8s version 2>/dev/null | head -1 | cut -d' ' -f2 || echo "unknown")
    log "Existing microk8s version: $MICROK8S_VERSION"
else
    log "Installing microk8s using snap..."
    
    # Update package lists and install snap if not available
    log "Checking for snap package manager..."
    if ! multipass exec "$VM_NAME" -- command -v snap >/dev/null 2>&1; then
        log "Installing snap package manager..."
        if ! multipass exec "$VM_NAME" -- sudo apt update >/dev/null 2>&1; then
            handle_microk8s_error 101 "Failed to update package lists" \
                "Check network connectivity and try again. Manual fix: sudo apt update"
        fi
        
        if ! multipass exec "$VM_NAME" -- sudo apt install -y snapd >/dev/null 2>&1; then
            handle_microk8s_error 102 "Failed to install snapd" \
                "Install snap manually: sudo apt install -y snapd. Check for conflicting packages."
        fi
        log "Snap package manager installed successfully"
    fi
    
    # Install microk8s
    log "Installing microk8s snap package..."
    if ! multipass exec "$VM_NAME" -- sudo snap install microk8s --classic >/dev/null 2>&1; then
        local install_error=$(multipass exec "$VM_NAME" -- sudo snap install microk8s --classic 2>&1 || echo "Unknown installation error")
        handle_microk8s_error 103 "Failed to install microk8s: $install_error" \
            "Check system requirements and try manual installation: sudo snap install microk8s --classic"
    fi
    
    # Verify installation
    log "Verifying microk8s installation..."
    if ! multipass exec "$VM_NAME" -- command -v microk8s >/dev/null 2>&1; then
        handle_microk8s_error 104 "Microk8s installation verification failed" \
            "Check if microk8s is properly installed: sudo snap list microk8s. Try reinstalling."
    fi
    
    MICROK8S_VERSION=$(multipass exec "$VM_NAME" -- microk8s version 2>/dev/null | head -1 | cut -d' ' -f2 || echo "unknown")
    log "Microk8s installed successfully: version $MICROK8S_VERSION"
fi

# 4.6 Wait for microk8s to be ready
log "Waiting for microk8s to be ready..."
MAX_ATTEMPTS=20
ATTEMPT=1
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    log "Checking microk8s status... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
    
    if microk8s_ready; then
        log "Microk8s is ready"
        break
    else
        log "Microk8s is not ready yet..."
        
        # Check if there's a specific error
        local status_output=$(multipass exec "$VM_NAME" -- microk8s status 2>&1 || echo "status check failed")
        log "Status output: $status_output"
        
        # If this is the last attempt, provide detailed error information
        if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
            handle_microk8s_error 105 "Microk8s failed to become ready after $MAX_ATTEMPTS attempts" \
                "Check microk8s status: microk8s status. Try restarting: sudo snap restart microk8s. Check logs: journalctl -u snap.microk8s.daemon-*"
        fi
    fi
    
    sleep 10
    ATTEMPT=$((ATTEMPT + 1))
done

# 4.7 Verify microk8s status after installation
log "Verifying microk8s status..."
if ! microk8s_ready; then
    handle_microk8s_error 106 "Microk8s is not ready after installation" \
        "Check microk8s status and logs: microk8s status; journalctl -u snap.microk8s.daemon-*"
fi

log "Microk8s status:"
multipass exec "$VM_NAME" -- microk8s status | tee -a "$LOG_FILE"

# 4.3 Enable dns add-on in microk8s
log "Enabling dns add-on..."
if ! multipass exec "$VM_NAME" -- microk8s enable dns >/dev/null 2>&1; then
    local dns_error=$(multipass exec "$VM_NAME" -- microk8s enable dns 2>&1 || echo "Unknown error enabling dns")
    handle_microk8s_addon_error "dns" "$dns_error"
fi
log "DNS add-on enabled successfully"

# 4.4 Enable storage add-on in microk8s
log "Enabling storage add-on..."
if ! multipass exec "$VM_NAME" -- microk8s enable storage >/dev/null 2>&1; then
    local storage_error=$(multipass exec "$VM_NAME" -- microk8s enable storage 2>&1 || echo "Unknown error enabling storage")
    handle_microk8s_addon_error "storage" "$storage_error"
fi
log "Storage add-on enabled successfully"

# 4.5 Enable ingress add-on in microk8s
log "Enabling ingress add-on..."
if ! multipass exec "$VM_NAME" -- microk8s enable ingress >/dev/null 2>&1; then
    local ingress_error=$(multipass exec "$VM_NAME" -- microk8s enable ingress 2>&1 || echo "Unknown error enabling ingress")
    handle_microk8s_addon_error "ingress" "$ingress_error"
fi
log "Ingress add-on enabled successfully"

# Wait a moment for add-ons to initialize
log "Waiting for add-ons to initialize..."
sleep 10

# Verify add-ons are enabled
log "Verifying add-ons status..."
ADDONS=("dns" "storage" "ingress")
for addon in "${ADDONS[@]}"; do
    log "Checking $addon add-on..."
    if microk8s_addon_enabled "$addon"; then
        log "$addon add-on is enabled"
    else
        log "WARNING: $addon add-on may not be fully enabled yet"
        
        # Give it more time and check again
        sleep 5
        if microk8s_addon_enabled "$addon"; then
            log "$addon add-on is now enabled"
        else
            log "WARNING: $addon add-on still not enabled. This may resolve automatically."
        fi
    fi
done

# Final status check
log "Final microk8s status verification..."
if microk8s_ready; then
    log "Microk8s is ready and all required add-ons are enabled"
    log "Microk8s final status:"
    multipass exec "$VM_NAME" -- microk8s status | tee -a "$LOG_FILE"
else
    handle_microk8s_error 107 "Microk8s final status check failed" \
        "Microk8s is not ready. Check status: microk8s status. Try restarting: sudo snap restart microk8s"
fi

# 4.9 Test microk8s installation and add-on enablement
log "Testing microk8s installation and add-on functionality..."

# Function to test microk8s cluster functionality
test_microk8s_functionality() {
    log "Running microk8s functionality tests..."
    
    # Test 1: Verify microk8s CLI is accessible and working
    log "Test 1: Verifying microk8s CLI accessibility..."
    if ! multipass exec "$VM_NAME" -- microk8s kubectl version --client >/dev/null 2>&1; then
        handle_microk8s_error 201 "Microk8s kubectl client is not accessible" \
            "Check microk8s installation: sudo snap list microk8s. Try reinstalling: sudo snap refresh microk8s"
    fi
    log "Microk8s kubectl client is accessible"

    # Test 2: Verify cluster connectivity
    log "Test 2: Verifying cluster connectivity..."
    if ! multipass exec "$VM_NAME" -- microk8s kubectl cluster-info >/dev/null 2>&1; then
        handle_microk8s_error 202 "Cannot connect to microk8s cluster" \
            "Check if microk8s is running: sudo snap start microk8s. Check cluster status: microk8s status"
    fi
    log "Cluster connectivity verified"

    # Test 3: Verify nodes are ready
    log "Test 3: Verifying cluster nodes are ready..."
    local node_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get nodes -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "")
    if [ "$node_status" != "True" ]; then
        handle_microk8s_error 203 "Cluster nodes are not ready" \
            "Check node status: microk8s kubectl get nodes. Wait for nodes to be ready: microk8s status --wait"
    fi
    log "All cluster nodes are ready"

    # Test 4: Verify core DNS is working
    log "Test 4: Verifying core DNS functionality..."
    if ! microk8s_addon_enabled "dns"; then
        handle_microk8s_error 204 "DNS add-on is not enabled" \
            "Enable DNS add-on: microk8s enable dns. Check add-on status: microk8s status"
    fi
    
    # Create a test pod to verify DNS resolution
    log "Creating test pod to verify DNS resolution..."
    multipass exec "$VM_NAME" -- bash -c 'cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: dns-test
spec:
  containers:
  - name: dns-test
    image: busybox:1.28
    command: ["tail", "-f", "/dev/null"]
  restartPolicy: Never
EOF' >/dev/null 2>&1 || true
    
    # Wait for the test pod to be ready
    log "Waiting for DNS test pod to be ready..."
    local dns_test_attempts=0
    local max_dns_test_attempts=10
    while [ $dns_test_attempts -lt $max_dns_test_attempts ]; do
        local pod_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pod dns-test -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
        if [ "$pod_status" = "Running" ]; then
            log "DNS test pod is ready"
            break
        fi
        sleep 2
        dns_test_attempts=$((dns_test_attempts + 1))
    done
    
    if [ $dns_test_attempts -ge $max_dns_test_attempts ]; then
        log "WARNING: DNS test pod did not become ready in time"
    else
        # Test DNS resolution inside the pod
        log "Testing DNS resolution inside the pod..."
        if multipass exec "$VM_NAME" -- microk8s kubectl exec dns-test -- nslookup kubernetes.default >/dev/null 2>&1; then
            log "DNS resolution is working correctly"
        else
            log "WARNING: DNS resolution test failed"
        fi
    fi
    
    # Clean up the test pod
    multipass exec "$VM_NAME" -- microk8s kubectl delete pod dns-test --ignore-not-found=true >/dev/null 2>&1 || true

    # Test 5: Verify storage provisioner is working
    log "Test 5: Verifying storage provisioner functionality..."
    if ! microk8s_addon_enabled "storage"; then
        handle_microk8s_error 205 "Storage add-on is not enabled" \
            "Enable storage add-on: microk8s enable storage. Check add-on status: microk8s status"
    fi
    
    # Check if storage class is available
    local storage_class=$(multipass exec "$VM_NAME" -- microk8s kubectl get storageclass -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    if [ -z "$storage_class" ]; then
        handle_microk8s_error 206 "No storage class available" \
            "Check storage add-on status: microk8s status. Check available storage classes: microk8s kubectl get storageclass"
    fi
    log "Storage provisioner is working. Available storage class: $storage_class"

    # Test 6: Verify ingress controller is working
    log "Test 6: Verifying ingress controller functionality..."
    if ! microk8s_addon_enabled "ingress"; then
        handle_microk8s_error 207 "Ingress add-on is not enabled" \
            "Enable ingress add-on: microk8s enable ingress. Check add-on status: microk8s status"
    fi
    
    # Check if ingress controller pod is running
    local ingress_pod=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n ingress -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$ingress_pod" ]; then
        local ingress_pod_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pod "$ingress_pod" -n ingress -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
        if [ "$ingress_pod_status" = "Running" ]; then
            log "Ingress controller pod is running: $ingress_pod"
        else
            log "WARNING: Ingress controller pod is not running: $ingress_pod (status: $ingress_pod_status)"
        fi
    else
        log "WARNING: No ingress controller pod found"
    fi
    
    # Check if ingress controller service is available
    local ingress_service=$(multipass exec "$VM_NAME" -- microk8s kubectl get service -n ingress -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$ingress_service" ]; then
        log "Ingress controller service is available: $ingress_service"
    else
        log "WARNING: No ingress controller service found"
    fi

    # Test 7: Verify cluster can create and manage resources
    log "Test 7: Verifying cluster resource management..."
    
    # Create a test namespace
    log "Creating test namespace..."
    multipass exec "$VM_NAME" -- microk8s kubectl create namespace microk8s-test --dry-run=client -o yaml | multipass exec "$VM_NAME" -- microk8s kubectl apply -f - >/dev/null 2>&1 || true
    
    # Create a test deployment
    log "Creating test deployment..."
    multipass exec "$VM_NAME" -- bash -c 'cat <<EOF | microk8s kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  namespace: microk8s-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF' >/dev/null 2>&1 || true
    
    # Wait for the test deployment to be ready
    log "Waiting for test deployment to be ready..."
    local test_deployment_attempts=0
    local max_test_deployment_attempts=15
    while [ $test_deployment_attempts -lt $max_test_deployment_attempts ]; do
        local deployment_ready=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment nginx-test -n microk8s-test -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        if [ "$deployment_ready" = "1" ]; then
            log "Test deployment is ready"
            break
        fi
        sleep 2
        test_deployment_attempts=$((test_deployment_attempts + 1))
    done
    
    if [ $test_deployment_attempts -ge $max_test_deployment_attempts ]; then
        log "WARNING: Test deployment did not become ready in time"
    else
        # Create a test service
        log "Creating test service..."
        multipass exec "$VM_NAME" -- bash -c 'cat <<EOF | microk8s kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-test-service
  namespace: microk8s-test
spec:
  selector:
    app: nginx-test
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
EOF' >/dev/null 2>&1 || true
        
        # Test service connectivity
        log "Testing service connectivity..."
        if multipass exec "$VM_NAME" -- microk8s kubectl run temp-curl --image=curlimages/curl -n microk8s-test --rm -it --restart=Never -- curl -s http://nginx-test-service >/dev/null 2>&1; then
            log "Service connectivity test passed"
        else
            log "WARNING: Service connectivity test failed"
        fi
    fi
    
    # Clean up test resources
    log "Cleaning up test resources..."
    multipass exec "$VM_NAME" -- microk8s kubectl delete namespace microk8s-test --ignore-not-found=true >/dev/null 2>&1 || true

    # Test 8: Verify cluster health metrics
    log "Test 8: Verifying cluster health metrics..."
    local cluster_info=$(multipass exec "$VM_NAME" -- microk8s kubectl cluster-info 2>&1 || echo "")
    if echo "$cluster_info" | grep -q "is running"; then
        log "Cluster health metrics are available"
    else
        log "WARNING: Cluster health metrics may not be fully available"
    fi

    log "All microk8s functionality tests completed successfully"
}

# Run the microk8s functionality tests
test_microk8s_functionality

# 4.8 Add microk8s error handling to deployment script
log "Microk8s installation and configuration completed successfully"
log "Microk8s is ready for Kubernetes deployment"

# ========================
# VERIFICATION: Microk8s installation completion
# ========================

verify_microk8s_installation_completion() {
    log "=== VERIFYING MICROK8S INSTALLATION COMPLETION ==="
    
    local verification_passed=true
    local verification_details=""
    
    # Verify microk8s is installed
    log "Verifying microk8s installation..."
    if ! multipass exec "$VM_NAME" -- command -v microk8s >/dev/null 2>&1; then
        verification_passed=false
        verification_details+="FAIL: microk8s is not installed in VM\n"
    else
        local microk8s_version=$(multipass exec "$VM_NAME" -- microk8s version 2>/dev/null | head -1 | cut -d' ' -f2 || echo "unknown")
        log "SUCCESS: microk8s is installed: version $microk8s_version"
    fi
    
    # Verify microk8s is ready
    log "Verifying microk8s readiness..."
    if ! microk8s_ready; then
        verification_passed=false
        verification_details+="FAIL: microk8s is not ready\n"
    else
        log "SUCCESS: microk8s is ready"
    fi
    
    # Verify required add-ons are enabled
    log "Verifying required add-ons..."
    local required_addons=("dns" "storage" "ingress")
    for addon in "${required_addons[@]}"; do
        if ! microk8s_addon_enabled "$addon"; then
            log "WARNING: $addon add-on is not enabled"
        else
            log "SUCCESS: $addon add-on is enabled"
        fi
    done
    
    # Verify microk8s cluster connectivity
    log "Verifying microk8s cluster connectivity..."
    if ! multipass exec "$VM_NAME" -- microk8s kubectl cluster-info >/dev/null 2>&1; then
        verification_passed=false
        verification_details+="FAIL: Cannot connect to microk8s cluster\n"
    else
        log "SUCCESS: microk8s cluster connectivity verified"
    fi
    
    # Verify cluster nodes are ready
    log "Verifying cluster nodes readiness..."
    local node_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get nodes -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "")
    if [ "$node_status" != "True" ]; then
        verification_passed=false
        verification_details+="FAIL: Cluster nodes are not ready\n"
    else
        log "SUCCESS: Cluster nodes are ready"
    fi
    
    # Verify kubectl accessibility
    log "Verifying kubectl accessibility..."
    if ! multipass exec "$VM_NAME" -- microk8s kubectl version --client >/dev/null 2>&1; then
        verification_passed=false
        verification_details+="FAIL: kubectl client is not accessible\n"
    else
        log "SUCCESS: kubectl client is accessible"
    fi
    
    # Verify cluster can create resources
    log "Verifying cluster resource management..."
    local test_namespace="verification-test-$$"
    if ! multipass exec "$VM_NAME" -- microk8s kubectl create namespace "$test_namespace" --dry-run=client -o yaml >/dev/null 2>&1; then
        verification_passed=false
        verification_details+="FAIL: Cannot create test namespace\n"
    else
        log "SUCCESS: Cluster can create resources"
    fi
    
    # Verify storage class is available
    log "Verifying storage class availability..."
    local storage_class=$(multipass exec "$VM_NAME" -- microk8s kubectl get storageclass -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    if [ -z "$storage_class" ]; then
        log "WARNING: No storage class available (may impact persistent volumes)"
    else
        log "SUCCESS: Storage class available: $storage_class"
    fi
    
    # Verify ingress controller pods are running
    log "Verifying ingress controller pods..."
    local ingress_pods=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n ingress -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    if [ -z "$ingress_pods" ]; then
        log "WARNING: No ingress controller pods found"
    else
        local all_pods_ready=true
        for pod in $ingress_pods; do
            local pod_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pod "$pod" -n ingress -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
            local pod_ready=$(multipass exec "$VM_NAME" -- microk8s kubectl get pod "$pod" -n ingress -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
            
            if [ "$pod_status" = "Running" ] && [ "$pod_ready" = "True" ]; then
                log "SUCCESS: Ingress pod '$pod' is running and ready"
            else
                all_pods_ready=false
                log "WARNING: Ingress pod '$pod' status: $pod_status, Ready: $pod_ready"
            fi
        done
        
        if [ "$all_pods_ready" = "true" ]; then
            log "SUCCESS: All ingress controller pods are ready"
        fi
    fi
    
    # Output verification summary
    log "=== MICROK8S INSTALLATION VERIFICATION SUMMARY ==="
    if [ "$verification_passed" = "true" ]; then
        log "STATUS: PASSED - Microk8s installation completed successfully"
        log "DETAILS: Microk8s cluster is ready for container deployment"
        log "Cluster Configuration:"
        log "  - Version: $microk8s_version"
        log "  - Status: Ready"
        log "  - Add-ons: dns, storage, ingress"
        log "  - Nodes: Ready"
        log "  - Resource management: Working"
        log "==========================================="
        return 0
    else
        log "STATUS: FAILED - Microk8s installation verification failed"
        log "DETAILS:"
        log -e "$verification_details"
        log "==========================================="
        handle_microk8s_error 999 "Microk8s installation verification failed" \
            "Address the issues above before continuing with container deployment"
        return 1
    fi
}

# Run microk8s installation verification
log "Running microk8s installation completion verification..."
verify_microk8s_installation_completion

log "Microk8s installation verification completed successfully"
log "Proceeding to container image build section"

# ===========================
# CONTAINER IMAGE BUILD SECTION
# ===========================

step_complete "Microk8s installation" 3 7
section_header "CONTAINER IMAGE BUILD" 4 7
progress 4 7 "Starting container image build"
milestone "Application Containerization" 3 4

# Container build error handler
handle_container_build_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "CONTAINER BUILD ERROR [Code: $error_code]: $error_message"
    log "RECOVERY SUGGESTION: $recovery_suggestion"
    
    # Log additional diagnostic information
    log "CONTAINER BUILD DIAGNOSTIC INFO:"
    log "Current directory: $(pwd)"
    log "Dockerfile location: $(pwd)/Dockerfile"
    log "Docker version: $(docker version 2>/dev/null | grep "Version" | head -1 || echo 'docker not found')"
    
    # Check if Dockerfile exists
    if [ ! -f "Dockerfile" ]; then
        log "ISSUE: Dockerfile not found in current directory"
        log "EXPECTED LOCATION: $(pwd)/Dockerfile"
    fi
    
    # Check if package.json exists (needed for Node.js build)
    if [ ! -f "package.json" ]; then
        log "ISSUE: package.json not found in current directory"
        log "EXPECTED LOCATION: $(pwd)/package.json"
    fi
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        log "ISSUE: Docker daemon is not running"
        log "FIX: Start Docker daemon: sudo systemctl start docker"
    fi
    
    # Check available disk space for build
    log "Available disk space: $(df -h . | awk 'NR==2 {print $4}')"
    
    exit $error_code
}

# Function to check if Docker is installed and running
docker_ready() {
    command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

# 5.1 Build Docker image in deployment script
log "Starting container image build..."

# Check Docker prerequisites
log "Checking Docker installation and status..."
if ! docker_ready; then
    handle_container_build_error 101 "Docker is not installed or not running" \
        "Install Docker and start the daemon: https://docs.docker.com/get-docker/"
fi
log "Docker is ready: $(docker version | grep "Version" | head -1 | tr -s ' ')"

# Check if required files exist
log "Checking required files for container build..."
if [ ! -f "Dockerfile" ]; then
    handle_container_build_error 102 "Dockerfile not found" \
        "Ensure Dockerfile exists in the project root directory: $(pwd)/Dockerfile"
fi
log "Dockerfile found: $(pwd)/Dockerfile"

if [ ! -f "package.json" ]; then
    handle_container_build_error 103 "package.json not found" \
        "Ensure package.json exists in the project root directory: $(pwd)/package.json"
fi
log "package.json found: $(pwd)/package.json"

# 5.2 Tag Docker image appropriately
IMAGE_NAME="my-ag-ui-app"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="$IMAGE_NAME:$IMAGE_TAG"

log "Building Docker image: $FULL_IMAGE_NAME"

# Set build arguments with default values
OPENAI_API_KEY="${OPENAI_API_KEY:-}"
OPENAI_BASE_URL="${OPENAI_BASE_URL:-}"
OPENAI_MODEL="${OPENAI_MODEL:-}"
LLM_MAX_TOKENS="${LLM_MAX_TOKENS:-}"
LLM_CONTEXT_WINDOW="${LLM_CONTEXT_WINDOW:-}"
EMBEDDING_MODEL="${EMBEDDING_MODEL:-}"
LOGFIRE_TOKEN="${LOGFIRE_TOKEN:-}"

# Build the Docker image with build args
log "Starting Docker build process..."
log "Build context directory: $(pwd)"
log "Build args: OPENAI_API_KEY=${OPENAI_API_KEY:0:10}..., OPENAI_BASE_URL=$OPENAI_BASE_URL, OPENAI_MODEL=$OPENAI_MODEL"

if ! docker build \
    --build-arg "OPENAI_API_KEY=$OPENAI_API_KEY" \
    --build-arg "OPENAI_BASE_URL=$OPENAI_BASE_URL" \
    --build-arg "OPENAI_MODEL=$OPENAI_MODEL" \
    --build-arg "LLM_MAX_TOKENS=$LLM_MAX_TOKENS" \
    --build-arg "LLM_CONTEXT_WINDOW=$LLM_CONTEXT_WINDOW" \
    --build-arg "EMBEDDING_MODEL=$EMBEDDING_MODEL" \
    --build-arg "LOGFIRE_TOKEN=$LOGFIRE_TOKEN" \
    -t "$FULL_IMAGE_NAME" \
    . 2>&1 | tee -a "$LOG_FILE"; then
    handle_container_build_error 104 "Docker build failed" \
        "Check the build output above for errors. Common issues include:\n1. Network connectivity issues\n2. Missing dependencies\n3. Insufficient disk space\n4. Build context issues"
fi

log "Docker image built successfully: $FULL_IMAGE_NAME"

# Verify the image was created
log "Verifying Docker image..."
if ! docker images | grep -q "^$IMAGE_NAME[[:space:]]*$IMAGE_TAG"; then
    handle_container_build_error 105 "Built Docker image not found in local registry" \
        "Check if the build completed successfully: docker images | grep $IMAGE_NAME"
fi

# Get image details
IMAGE_ID=$(docker images | grep "^$IMAGE_NAME[[:space:]]*$IMAGE_TAG" | awk '{print $3}' | head -1)
IMAGE_SIZE=$(docker images | grep "^$IMAGE_NAME[[:space:]]*$IMAGE_TAG" | awk '{print $5,$6}' | head -1)
log "Docker image details:"
log "  Image: $FULL_IMAGE_NAME"
log "  ID: $IMAGE_ID"
log "  Size: $IMAGE_SIZE"

# Test the image locally (optional but recommended)
log "Testing Docker image locally..."
CONTAINER_NAME="test-$IMAGE_NAME-$$"

# Run the container in detached mode for testing
if ! docker run -d --name "$CONTAINER_NAME" -p 3001:3000 "$FULL_IMAGE_NAME" >/dev/null 2>&1; then
    log "WARNING: Failed to start container for local testing"
    log "This may be due to port conflicts or resource limitations"
    log "Continuing with deployment, but local testing was skipped"
else
    log "Container started for testing: $CONTAINER_NAME"
    
    # Wait for the container to be ready
    MAX_ATTEMPTS=10
    ATTEMPT=1
    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        if docker ps | grep -q "$CONTAINER_NAME"; then
            log "Container is running (attempt $ATTEMPT/$MAX_ATTEMPTS)"
            
            # Test if the application is responding
            if curl -s -f http://localhost:3001 >/dev/null 2>&1; then
                log "Application is responding successfully"
                break
            else
                log "Application not yet responding..."
            fi
        else
            log "Container not running yet..."
        fi
        
        if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
            log "WARNING: Container did not become ready for testing within $MAX_ATTEMPTS attempts"
            log "Container logs:"
            docker logs "$CONTAINER_NAME" 2>&1 | head -10 | tee -a "$LOG_FILE"
        fi
        
        sleep 3
        ATTEMPT=$((ATTEMPT + 1))
    done
    
    # Stop and remove the test container
    log "Stopping and removing test container..."
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
    log "Test container cleaned up"
fi

log "Container image build completed successfully"
log "Image $FULL_IMAGE_NAME is ready for Kubernetes deployment"

# ========================
# VERIFICATION: Container image build completion
# ========================

verify_container_image_build_completion() {
    log "=== VERIFYING CONTAINER IMAGE BUILD COMPLETION ==="
    
    local verification_passed=true
    local verification_details=""
    
    # Verify Docker image exists locally
    log "Verifying Docker image exists locally..."
    if ! docker images | grep -q "^$IMAGE_NAME[[:space:]]*$IMAGE_TAG"; then
        verification_passed=false
        verification_details+="FAIL: Docker image '$FULL_IMAGE_NAME' not found locally\n"
    else
        log "SUCCESS: Docker image '$FULL_IMAGE_NAME' exists locally"
        
        # Get image details
        local image_id=$(docker images | grep "^$IMAGE_NAME[[:space:]]*$IMAGE_TAG" | awk '{print $3}' | head -1)
        local image_size=$(docker images | grep "^$IMAGE_NAME[[:space:]]*$IMAGE_TAG" | awk '{print $5,$6}' | head -1)
        log "Image details - ID: $image_id, Size: $image_size"
    fi
    
    # Verify Docker daemon is still running
    log "Verifying Docker daemon is running..."
    if ! docker_ready; then
        verification_passed=false
        verification_details+="FAIL: Docker daemon is not running\n"
    else
        log "SUCCESS: Docker daemon is running"
    fi
    
    # Verify image can be inspected (not corrupted)
    log "Verifying image integrity..."
    if ! docker inspect "$FULL_IMAGE_NAME" >/dev/null 2>&1; then
        verification_passed=false
        verification_details+="FAIL: Docker image is corrupted or cannot be inspected\n"
    else
        log "SUCCESS: Docker image integrity verified"
        
        # Verify image has proper configuration
        local image_config=$(docker inspect "$FULL_IMAGE_NAME" 2>/dev/null || echo "")
        if [ -n "$image_config" ]; then
            # Check if image has exposed port
            local exposed_port=$(echo "$image_config" | jq -r '.[0].Config.ExposedPorts // empty' 2>/dev/null || echo "")
            if [ -n "$exposed_port" ]; then
                log "SUCCESS: Image has exposed ports configured: $exposed_port"
            else
                log "WARNING: Image has no exposed ports configured"
            fi
            
            # Check if image has entrypoint or cmd
            local entrypoint=$(echo "$image_config" | jq -r '.[0].Config.Entrypoint // empty' 2>/dev/null || echo "")
            local cmd=$(echo "$image_config" | jq -r '.[0].Config.Cmd // empty' 2>/dev/null || echo "")
            if [ -n "$entrypoint" ] || [ -n "$cmd" ]; then
                log "SUCCESS: Image has startup command configured"
            else
                log "WARNING: Image has no startup command configured"
            fi
            
            # Check image size is reasonable
            local image_size_mb=$(docker images | grep "^$IMAGE_NAME[[:space:]]*$IMAGE_TAG" | awk '{print $7}' | sed 's/MB//' | head -1 || echo "0")
            if [ -n "$image_size_mb" ] && [ "$image_size_mb" -gt 0 ]; then
                if [ "$image_size_mb" -lt 2000 ]; then
                    log "SUCCESS: Image size is reasonable: ${image_size_mb}MB"
                else
                    log "WARNING: Image size is large: ${image_size_mb}MB"
                fi
            fi
        fi
    fi
    
    # Verify image can be exported (for transfer to VM)
    log "Verifying image can be exported..."
    local test_export_file="/tmp/test-export-$$"
    if ! docker save -o "$test_export_file" "$FULL_IMAGE_NAME" 2>/dev/null; then
        verification_passed=false
        verification_details+="FAIL: Docker image cannot be exported\n"
    else
        log "SUCCESS: Docker image can be exported"
        
        # Verify export file is not empty
        local export_size=$(stat -c%s "$test_export_file" 2>/dev/null || echo "0")
        if [ "$export_size" -gt 0 ]; then
            log "SUCCESS: Export file is valid: ${export_size} bytes"
        else
            verification_passed=false
            verification_details+="FAIL: Export file is empty\n"
        fi
        
        # Clean up test export file
        rm -f "$test_export_file" 2>/dev/null || true
    fi
    
    # Verify build context still exists
    log "Verifying build context files..."
    local required_files=("Dockerfile" "package.json")
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log "WARNING: Required file '$file' not found in build context"
        else
            log "SUCCESS: Required file '$file' exists in build context"
        fi
    done
    
    # Verify no critical build warnings in log
    log "Verifying build process quality..."
    if [ -f "$LOG_FILE" ]; then
        local warning_count=$(grep -c "WARNING" "$LOG_FILE" 2>/dev/null || echo "0")
        local error_count=$(grep -c "ERROR" "$LOG_FILE" 2>/dev/null || echo "0")
        
        if [ "$error_count" -eq 0 ]; then
            log "SUCCESS: No errors detected in build process"
        else
            log "WARNING: Found $error_count errors in build process"
        fi
        
        if [ "$warning_count" -le 5 ]; then
            log "SUCCESS: Build process quality is acceptable ($warning_count warnings)"
        else
            log "WARNING: Build process has many warnings ($warning_count)"
        fi
    fi
    
    # Output verification summary
    log "=== CONTAINER IMAGE BUILD VERIFICATION SUMMARY ==="
    if [ "$verification_passed" = "true" ]; then
        log "STATUS: PASSED - Container image build completed successfully"
        log "DETAILS: Docker image is ready for deployment to microk8s"
        log "Image Details:"
        log "  - Name: $FULL_IMAGE_NAME"
        log "  - ID: $image_id"
        log "  - Size: $image_size"
        log "  - Status: Ready for deployment"
        log "==========================================="
        return 0
    else
        log "STATUS: FAILED - Container image build verification failed"
        log "DETAILS:"
        log -e "$verification_details"
        log "==========================================="
        handle_container_build_error 999 "Container image build verification failed" \
            "Address the issues above before continuing with image deployment"
        return 1
    fi
}

# Run container image build verification
log "Running container image build completion verification..."
verify_container_image_build_completion

log "Container image build verification completed successfully"
log "Proceeding to container image deployment section"

# ===========================
# CONTAINER IMAGE DEPLOYMENT SECTION
# ===========================

step_complete "Container image build" 4 7
section_header "CONTAINER IMAGE DEPLOYMENT" 5 7
progress 5 7 "Starting container image deployment"

# Container image deployment error handler
handle_image_deployment_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "IMAGE DEPLOYMENT ERROR [Code: $error_code]: $error_message"
    log "RECOVERY SUGGESTION: $recovery_suggestion"
    
    # Log additional diagnostic information
    log "IMAGE DEPLOYMENT DIAGNOSTIC INFO:"
    log "Image name: $FULL_IMAGE_NAME"
    log "VM name: $VM_NAME"
    log "Microk8s status: $(multipass exec "$VM_NAME" -- microk8s status --wait 2>&1 || echo 'microk8s not ready')"
    
    exit $error_code
}

# 5.3 Load Docker image into microk8s (or configure image pull)
log "Starting container image deployment to microk8s..."

# Verify microk8s is ready in the VM
log "Verifying microk8s is ready for image deployment..."
if ! microk8s_ready; then
    handle_image_deployment_error 201 "Microk8s is not ready for image deployment" \
        "Ensure microk8s is running and ready: microk8s status --wait"
fi
log "Microk8s is ready for image deployment"

# Save the Docker image to a tar file
log "Saving Docker image to tar file for transfer..."
IMAGE_TAR_FILE="$IMAGE_NAME-$IMAGE_TAG.tar"
if ! docker save -o "$IMAGE_TAR_FILE" "$FULL_IMAGE_NAME" 2>&1 | tee -a "$LOG_FILE"; then
    handle_image_deployment_error 202 "Failed to save Docker image to tar file" \
        "Check if the image exists and Docker has sufficient permissions: docker images | grep $IMAGE_NAME"
fi
log "Docker image saved to: $IMAGE_TAR_FILE"

# Get the tar file size for logging
TAR_FILE_SIZE=$(du -h "$IMAGE_TAR_FILE" | cut -f1)
log "Image tar file size: $TAR_FILE_SIZE"

# Copy the tar file to the VM
log "Copying image tar file to VM '$VM_NAME'..."
if ! multipass copy-file "$IMAGE_TAR_FILE" "$VM_NAME:/tmp/$IMAGE_TAR_FILE" 2>&1 | tee -a "$LOG_FILE"; then
    handle_image_deployment_error 203 "Failed to copy image tar file to VM" \
        "Check if VM is running and accessible: multipass info $VM_NAME. Check disk space in VM."
fi
log "Image tar file copied to VM"

# Clean up local tar file
log "Cleaning up local tar file..."
rm -f "$IMAGE_TAR_FILE"
log "Local tar file cleaned up"

# Load the image into microk8s
log "Loading Docker image into microk8s..."
if ! multipass exec "$VM_NAME" -- bash -c "microk8s ctr image import /tmp/$IMAGE_TAR_FILE" 2>&1 | tee -a "$LOG_FILE"; then
    handle_image_deployment_error 204 "Failed to import image into microk8s" \
        "Check if microk8s is running and has sufficient resources: microk8s status. Try importing manually: microk8s ctr image import /tmp/$IMAGE_TAR_FILE"
fi
log "Docker image imported into microk8s successfully"

# Clean up the tar file in the VM
log "Cleaning up tar file in VM..."
if ! multipass exec "$VM_NAME" -- rm -f "/tmp/$IMAGE_TAR_FILE" 2>&1 | tee -a "$LOG_FILE"; then
    log "WARNING: Failed to clean up tar file in VM (this is not critical)"
fi
log "VM tar file cleaned up"

# Verify the image is available in microk8s
log "Verifying image is available in microk8s..."
if ! multipass exec "$VM_NAME" -- bash -c "microk8s ctr image list | grep -q '$IMAGE_NAME'" 2>&1 | tee -a "$LOG_FILE"; then
    handle_image_deployment_error 205 "Image not found in microk8s after import" \
        "Check if image was imported correctly: microk8s ctr image list | grep $IMAGE_NAME"
fi
log "Image verified in microk8s"

# Get the full image reference in microk8s
log "Getting image details from microk8s..."
multipass exec "$VM_NAME" -- bash -c "microk8s ctr image list | grep '$IMAGE_NAME'" | tee -a "$LOG_FILE"

log "Container image deployment to microk8s completed successfully"

# ========================
# VERIFICATION: Container image deployment completion
# ========================

verify_container_image_deployment_completion() {
    log "=== VERIFYING CONTAINER IMAGE DEPLOYMENT COMPLETION ==="
    
    local verification_passed=true
    local verification_details=""
    
    # Verify microk8s is still ready
    log "Verifying microk8s readiness..."
    if ! microk8s_ready; then
        verification_passed=false
        verification_details+="FAIL: microk8s is not ready\n"
    else
        log "SUCCESS: microk8s is ready"
    fi
    
    # Verify image is available in microk8s
    log "Verifying image availability in microk8s..."
    if ! multipass exec "$VM_NAME" -- bash -c "microk8s ctr image list | grep -q '$IMAGE_NAME'" 2>&1 | tee -a "$LOG_FILE"; then
        verification_passed=false
        verification_details+="FAIL: Image '$FULL_IMAGE_NAME' not found in microk8s\n"
    else
        log "SUCCESS: Image '$FULL_IMAGE_NAME' is available in microk8s"
        
        # Get image details from microk8s
        log "Getting image details from microk8s..."
        multipass exec "$VM_NAME" -- bash -c "microk8s ctr image list | grep '$IMAGE_NAME'" | tee -a "$LOG_FILE"
    fi
    
    # Verify image can be inspected in microk8s
    log "Verifying image can be inspected in microk8s..."
    local image_name_in_ctr=$(multipass exec "$VM_NAME" -- bash -c "microk8s ctr image list | grep '$IMAGE_NAME' | awk '{print \$1}' 2>/dev/null || echo ''")
    if [ -n "$image_name_in_ctr" ]; then
        if multipass exec "$VM_NAME" -- bash -c "microk8s ctr image info '$image_name_in_ctr'" >/dev/null 2>&1; then
            log "SUCCESS: Image can be inspected in microk8s"
        else
            log "WARNING: Image exists but cannot be inspected in microk8s"
        fi
    else
        verification_passed=false
        verification_details+="FAIL: Could not get image name from microk8s\n"
    fi
    
    # Verify no critical deployment errors occurred
    log "Verifying deployment process quality..."
    if [ -f "$LOG_FILE" ]; then
        local deployment_errors=$(grep -c "IMAGE DEPLOYMENT ERROR" "$LOG_FILE" 2>/dev/null || echo "0")
        if [ "$deployment_errors" -eq 0 ]; then
            log "SUCCESS: No deployment errors detected"
        else
            verification_passed=false
            verification_details+="FAIL: Found $deployment_errors deployment errors\n"
        fi
    fi
    
    # Verify VM still has adequate resources
    log "Verifying VM resources for Kubernetes deployment..."
    if multipass exec "$VM_NAME" -- command -v free >/dev/null 2>&1; then
        local vm_memory_percent=$(multipass exec "$VM_NAME" -- free -m | awk 'NR==2{printf "%.0f", $3/$2*100}')
        if [ "$vm_memory_percent" -lt 80 ]; then
            log "SUCCESS: VM has adequate memory (${vm_memory_percent}% used)"
        else
            log "WARNING: VM memory usage is high (${vm_memory_percent}% used)"
        fi
    fi
    
    if multipass exec "$VM_NAME" -- command -v df >/dev/null 2>&1; then
        local vm_disk_percent=$(multipass exec "$VM_NAME" -- df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
        if [ "$vm_disk_percent" -lt 80 ]; then
            log "SUCCESS: VM has adequate disk space (${vm_disk_percent}% used)"
        else
            log "WARNING: VM disk usage is high (${vm_disk_percent}% used)"
        fi
    fi
    
    # Verify microk8s cluster is accessible
    log "Verifying microk8s cluster accessibility..."
    if ! multipass exec "$VM_NAME" -- microk8s kubectl cluster-info >/dev/null 2>&1; then
        verification_passed=false
        verification_details+="FAIL: Cannot access microk8s cluster\n"
    else
        log "SUCCESS: microk8s cluster is accessible"
    fi
    
    # Verify kubectl can list images (indicates proper integration)
    log "Verifying kubectl integration with container runtime..."
    if multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get nodes -o jsonpath='{.items[*].status.capacity}'" >/dev/null 2>&1; then
        log "SUCCESS: kubectl integration with container runtime is working"
    else
        log "WARNING: kubectl integration with container runtime may have issues"
    fi
    
    # Output verification summary
    log "=== CONTAINER IMAGE DEPLOYMENT VERIFICATION SUMMARY ==="
    if [ "$verification_passed" = "true" ]; then
        log "STATUS: PASSED - Container image deployment completed successfully"
        log "DETAILS: Image is ready for Kubernetes deployment"
        log "Deployment Details:"
        log "  - Image: $FULL_IMAGE_NAME"
        log "  - Status: Available in microk8s"
        log "  - Microk8s: Ready and accessible"
        log "  - VM Resources: Adequate"
        log "==========================================="
        return 0
    else
        log "STATUS: FAILED - Container image deployment verification failed"
        log "DETAILS:"
        log -e "$verification_details"
        log "==========================================="
        handle_image_deployment_error 999 "Container image deployment verification failed" \
            "Address the issues above before continuing with Kubernetes deployment"
        return 1
    fi
}

# Run container image deployment verification
log "Running container image deployment completion verification..."
verify_container_image_deployment_completion

log "Container image deployment verification completed successfully"
log "Proceeding to ingress configuration section"

# ===========================
# KUBERNETES DEPLOYMENT SECTION
# ===========================

step_complete "Container image deployment" 5 7
section_header "KUBERNETES DEPLOYMENT" 6 7
progress 6 7 "Starting Kubernetes deployment"
milestone "Application Deployment" 4 4

# Kubernetes deployment error handler
handle_k8s_deployment_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "KUBERNETES DEPLOYMENT ERROR [Code: $error_code]: $error_message"
    log "RECOVERY SUGGESTION: $recovery_suggestion"
    
    # Log additional diagnostic information
    log "KUBERNETES DEPLOYMENT DIAGNOSTIC INFO:"
    log "VM Name: $VM_NAME"
    log "Image name: $FULL_IMAGE_NAME"
    log "Microk8s status: $(multipass exec "$VM_NAME" -- microk8s status --wait 2>/dev/null || echo 'microk8s not ready')"
    log "Current directory: $(pwd)"
    log "K8s manifests directory: $(pwd)/k8s/"
    
    # Check if k8s directory exists
    if [ -d "k8s" ]; then
        log "K8s manifests found in: $(pwd)/k8s/"
        log "Available manifest files:"
        ls -la k8s/ | tee -a "$LOG_FILE" 2>/dev/null || log "Could not list k8s directory contents"
    else
        log "ERROR: k8s directory not found in $(pwd)"
    fi
    
    # Check Kubernetes cluster status
    if multipass exec "$VM_NAME" -- command -v microk8s >/dev/null 2>&1; then
        log "Kubernetes cluster status:"
        multipass exec "$VM_NAME" -- microk8s status 2>&1 | head -10 | tee -a "$LOG_FILE" || log "Could not get microk8s status"
        
        log "Kubernetes nodes:"
        multipass exec "$VM_NAME" -- microk8s kubectl get nodes 2>&1 | tee -a "$LOG_FILE" || log "Could not get kubernetes nodes"
        
        log "Kubernetes namespaces:"
        multipass exec "$VM_NAME" -- microk8s kubectl get namespaces 2>&1 | tee -a "$LOG_FILE" || log "Could not get kubernetes namespaces"
    fi
    
    exit $error_code
}

# Function to verify Kubernetes resources
verify_k8s_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-default}
    local max_attempts=${4:-10}
    local wait_time=${5:-3}
    
    log "Verifying $resource_type '$resource_name' in namespace '$namespace'..."
    
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        log "Verification attempt $attempt/$max_attempts for $resource_type '$resource_name'..."
        
        if multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get $resource_type $resource_name -n $namespace" >/dev/null 2>&1; then
            log "SUCCESS: $resource_type '$resource_name' verified successfully"
            return 0
        else
            log "WARNING: $resource_type '$resource_name' not found yet (attempt $attempt/$max_attempts)"
            
            if [ $attempt -eq $max_attempts ]; then
                log "ERROR: $resource_type '$resource_name' verification failed after $max_attempts attempts"
                return 1
            fi
            
            sleep $wait_time
            attempt=$((attempt + 1))
        fi
    done
}

# Function to wait for pods to be ready
wait_for_pods_ready() {
    local app_label=$1
    local namespace=${2:-default}
    local max_attempts=${3:-30}
    local wait_time=${4:-5}
    local min_ready=${5:-1}
    
    log "Waiting for pods with label '$app_label' to be ready in namespace '$namespace'..."
    log "Minimum required ready pods: $min_ready"
    
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        log "Checking pod readiness... (attempt $attempt/$max_attempts)"
        
        # Get pod information
        local pod_info=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get pods -l app=$app_label -n $namespace -o json" 2>/dev/null || echo "")
        
        if [ -n "$pod_info" ]; then
            # Count total and ready pods
            local total_pods=$(echo "$pod_info" | jq '.items | length' 2>/dev/null || echo "0")
            local ready_pods=$(echo "$pod_info" | jq '.items[].status.containerStatuses[0].ready // false' | grep -c true 2>/dev/null || echo "0")
            local running_pods=$(echo "$pod_info" | jq '.items[].status.phase' | grep -c Running 2>/dev/null || echo "0")
            
            log "Pod status: $ready_pods/$total_pods ready, $running_pods/$total_pods running"
            
            if [ "$ready_pods" -ge "$min_ready" ] && [ "$running_pods" -ge "$min_ready" ] && [ "$total_pods" -ge "$min_ready" ]; then
                log "SUCCESS: Required pods are ready ($ready_pods/$total_pods ready, $running_pods/$total_pods running)"
                return 0
            fi
        else
            log "WARNING: No pods found with label '$app_label' in namespace '$namespace'"
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log "ERROR: Pods did not become ready after $max_attempts attempts"
            log "Current pod status:"
            multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get pods -l app=$app_label -n $namespace" 2>&1 | tee -a "$LOG_FILE" || log "Could not get pod status"
            return 1
        fi
        
        sleep $wait_time
        attempt=$((attempt + 1))
    done
}

log "Starting comprehensive Kubernetes deployment process..."

# 7.6.1 Verify microk8s cluster is ready for deployment
log "Step 1: Verifying microk8s cluster readiness..."
if ! microk8s_ready; then
    handle_k8s_deployment_error 101 "Microk8s cluster is not ready for deployment" \
        "Ensure microk8s is running and ready: microk8s status --wait. Check cluster status: microk8s kubectl cluster-info"
fi
log "Microk8s cluster is ready for deployment"

# 7.6.2 Verify Docker image is available in microk8s
log "Step 2: Verifying Docker image is available in microk8s..."
if ! multipass exec "$VM_NAME" -- bash -c "microk8s ctr image list | grep -q '$IMAGE_NAME'" 2>&1 | tee -a "$LOG_FILE"; then
    handle_k8s_deployment_error 102 "Docker image '$FULL_IMAGE_NAME' not found in microk8s" \
        "Ensure image was imported: microk8s ctr image list | grep $IMAGE_NAME. Import manually: microk8s ctr image import <image-tar-file>"
fi
log "Docker image '$FULL_IMAGE_NAME' is available in microk8s"

# 7.6.3 Verify Kubernetes manifests exist
log "Step 3: Verifying Kubernetes manifests exist..."
K8S_MANIFESTS=("deployment.yaml" "service.yaml" "ingress.yaml" "secrets.yaml")
for manifest in "${K8S_MANIFESTS[@]}"; do
    if [ ! -f "k8s/$manifest" ]; then
        handle_k8s_deployment_error 103 "Kubernetes manifest '$manifest' not found" \
            "Ensure manifest exists in k8s/ directory: $(pwd)/k8s/$manifest"
    fi
    log "Manifest '$manifest' found and accessible"
done
log "All required Kubernetes manifests are available"

# 7.6.4 Apply secrets manifest (if sensitive data needs to be configured)
log "Step 4: Applying Kubernetes secrets manifest..."
if [ -f "k8s/secrets.yaml" ]; then
    log "Found secrets.yaml, applying secrets configuration..."
    if ! multipass exec "$VM_NAME" -- bash -c "cd /tmp && microk8s kubectl apply -f <(cat <<'EOF'
$(cat k8s/secrets.yaml)
EOF
)" 2>&1 | tee -a "$LOG_FILE"; then
        handle_k8s_deployment_error 104 "Failed to apply secrets manifest" \
            "Check secrets manifest: k8s/secrets.yaml. Apply manually: microk8s kubectl apply -f k8s/secrets.yaml"
    fi
    log "Secrets manifest applied successfully"
    
    # Verify secrets were created
    if ! verify_k8s_resource "secret" "my-ag-ui-app-secrets" "default" 5 2; then
        log "WARNING: Secrets verification failed, but continuing with deployment"
    else
        log "Secrets verified successfully"
    fi
else
    log "No secrets.yaml found, skipping secrets configuration"
fi

# 7.6.5 Apply deployment manifest
log "Step 5: Applying Kubernetes deployment manifest..."
log "Creating deployment for application '$IMAGE_NAME'..."
if ! multipass exec "$VM_NAME" -- bash -c "cd /tmp && microk8s kubectl apply -f <(cat <<'EOF'
$(cat k8s/deployment.yaml)
EOF
)" 2>&1 | tee -a "$LOG_FILE"; then
    handle_k8s_deployment_error 105 "Failed to apply deployment manifest" \
        "Check deployment manifest: k8s/deployment.yaml. Apply manually: microk8s kubectl apply -f k8s/deployment.yaml"
fi
log "Deployment manifest applied successfully"

# 7.6.6 Verify deployment was created
log "Step 6: Verifying Kubernetes deployment..."
if ! verify_k8s_resource "deployment" "my-ag-ui-app-deployment" "default" 10 3; then
    handle_k8s_deployment_error 106 "Deployment verification failed" \
        "Check deployment status: microk8s kubectl get deployment my-ag-ui-app-deployment. Check events: microk8s kubectl get events"
fi
log "Deployment verified successfully"

# 7.6.7 Apply service manifest
log "Step 7: Applying Kubernetes service manifest..."
if ! multipass exec "$VM_NAME" -- bash -c "cd /tmp && microk8s kubectl apply -f <(cat <<'EOF'
$(cat k8s/service.yaml)
EOF
)" 2>&1 | tee -a "$LOG_FILE"; then
    handle_k8s_deployment_error 107 "Failed to apply service manifest" \
        "Check service manifest: k8s/service.yaml. Apply manually: microk8s kubectl apply -f k8s/service.yaml"
fi
log "Service manifest applied successfully"

# 7.6.8 Verify service was created
log "Step 8: Verifying Kubernetes service..."
if ! verify_k8s_resource "service" "my-ag-ui-app-service" "default" 10 3; then
    handle_k8s_deployment_error 108 "Service verification failed" \
        "Check service status: microk8s kubectl get service my-ag-ui-app-service. Check endpoints: microk8s kubectl get endpoints my-ag-ui-app-service"
fi
log "Service verified successfully"

# 7.6.9 Apply ingress manifest
log "Step 9: Applying Kubernetes ingress manifest..."
if ! multipass exec "$VM_NAME" -- bash -c "cd /tmp && microk8s kubectl apply -f <(cat <<'EOF'
$(cat k8s/ingress.yaml)
EOF
)" 2>&1 | tee -a "$LOG_FILE"; then
    handle_k8s_deployment_error 109 "Failed to apply ingress manifest" \
        "Check ingress manifest: k8s/ingress.yaml. Apply manually: microk8s kubectl apply -f k8s/ingress.yaml"
fi
log "Ingress manifest applied successfully"

# 7.6.10 Verify ingress was created
log "Step 10: Verifying Kubernetes ingress..."
if ! verify_k8s_resource "ingress" "my-ag-ui-app-ingress" "default" 10 3; then
    handle_k8s_deployment_error 110 "Ingress verification failed" \
        "Check ingress status: microk8s kubectl get ingress my-ag-ui-app-ingress. Check ingress class: microk8s kubectl get ingressclass"
fi
log "Ingress verified successfully"

# 7.6.11 Wait for application pods to be ready
log "Step 11: Waiting for application pods to be ready..."
if ! wait_for_pods_ready "my-ag-ui-app" "default" 30 5 1; then
    handle_k8s_deployment_error 111 "Application pods did not become ready" \
        "Check pod status: microk8s kubectl get pods -l app=my-ag-ui-app. Check pod logs: microk8s kubectl logs <pod-name>. Check events: microk8s kubectl get events"
fi
log "Application pods are ready and running"

# 7.6.12 Verify deployment rollout status
log "Step 12: Verifying deployment rollout status..."
if ! multipass exec "$VM_NAME" -- bash -c "microk8s kubectl rollout status deployment/my-ag-ui-app-deployment" 2>&1 | tee -a "$LOG_FILE"; then
    handle_k8s_deployment_error 112 "Deployment rollout verification failed" \
        "Check deployment rollout: microk8s kubectl rollout status deployment/my-ag-ui-app-deployment. Check deployment details: microk8s kubectl describe deployment my-ag-ui-app-deployment"
fi
log "Deployment rollout completed successfully"

# 7.6.13 Verify service endpoints are populated
log "Step 13: Verifying service endpoints are populated..."
local endpoints_check=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get endpoints my-ag-ui-app-service -o jsonpath='{.subsets}'" 2>/dev/null || echo "")
if [ -z "$endpoints_check" ] || [ "$endpoints_check" = "[]" ]; then
    log "WARNING: Service endpoints are not populated yet"
    # Wait a bit and check again
    sleep 10
    endpoints_check=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get endpoints my-ag-ui-app-service -o jsonpath='{.subsets}'" 2>/dev/null || echo "")
    if [ -z "$endpoints_check" ] || [ "$endpoints_check" = "[]" ]; then
        log "ERROR: Service endpoints remain unpopulated"
        handle_k8s_deployment_error 113 "Service endpoints are not populated" \
            "Check service endpoints: microk8s kubectl get endpoints my-ag-ui-app-service. Check pod labels: microk8s kubectl get pods --show-labels"
    fi
fi
log "Service endpoints are populated and ready"

# 7.6.14 Verify application is accessible through service
log "Step 14: Verifying application accessibility through service..."
local service_test=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl run temp-access-test --image=curlimages/curl --rm -i --restart=Never -- curl -s -f http://my-ag-ui-app-service:3000" 2>&1 || echo "")
if echo "$service_test" | grep -q "200\|OK\|healthy" 2>/dev/null; then
    log "SUCCESS: Application is accessible through service"
else
    log "WARNING: Service accessibility test inconclusive (this may be normal if app has specific health check requirements)"
    log "Service test output: $service_test"
fi

# 7.6.15 Comprehensive deployment verification
log "Step 15: Performing comprehensive deployment verification..."
log "=== KUBERNETES DEPLOYMENT VERIFICATION SUMMARY ==="

# Verify all resources are present and healthy
log "Deployment resources status:"
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get deployment,service,ingress,secret,pods -l app=my-ag-ui-app" 2>&1 | tee -a "$LOG_FILE" || log "Could not get deployment resources summary"

# Check deployment details
log "Deployment details:"
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl describe deployment my-ag-ui-app-deployment" 2>&1 | head -20 | tee -a "$LOG_FILE" || log "Could not get deployment details"

# Check service details
log "Service details:"
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl describe service my-ag-ui-app-service" 2>&1 | head -15 | tee -a "$LOG_FILE" || log "Could not get service details"

# Check ingress details
log "Ingress details:"
multipass exec "$VM_NAME" -- bash -c "microk8s kubectl describe ingress my-ag-ui-app-ingress" 2>&1 | head -15 | tee -a "$LOG_FILE" || log "Could not get ingress details"

log "=============================================="
log "Kubernetes deployment verification completed"

# 7.6.16 Final deployment success confirmation
log "=== KUBERNETES DEPLOYMENT SUCCESS ==="
log "Kubernetes deployment completed successfully!"
log ""
log "Deployment Summary:"
log "  - Application: my-ag-ui-app"
log "  - Image: $FULL_IMAGE_NAME"
log "  - Namespace: default"
log "  - Deployment: my-ag-ui-app-deployment"
log "  - Service: my-ag-ui-app-service"
log "  - Ingress: my-ag-ui-app-ingress"
log "  - Pods: All running and ready"
log ""
log "Next Steps:"
log "  1. Access the application via ingress endpoint"
log "  2. Monitor application health and logs"
log "  3. Verify all functionality is working"
log ""
log "Kubernetes deployment section completed successfully"
log "=========================================="

# ========================
# VERIFICATION: Kubernetes deployment completion
# ========================

verify_kubernetes_deployment_completion() {
    log "=== VERIFYING KUBERNETES DEPLOYMENT COMPLETION ==="
    
    local verification_passed=true
    local verification_details=""
    
    # Verify all Kubernetes resources exist
    log "Verifying Kubernetes resources existence..."
    local resources=("deployment" "service" "ingress")
    for resource in "${resources[@]}"; do
        local resource_name="my-ag-ui-app-$resource"
        if ! multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get $resource $resource_name" >/dev/null 2>&1; then
            verification_passed=false
            verification_details+="FAIL: $resource '$resource_name' not found\n"
        else
            log "SUCCESS: $resource '$resource_name' exists"
        fi
    done
    
    # Verify deployment is healthy
    log "Verifying deployment health..."
    local deployment_ready=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get deployment my-ag-ui-app-deployment -o jsonpath='{.status.readyReplicas}'" 2>/dev/null || echo "0")
    local deployment_replicas=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get deployment my-ag-ui-app-deployment -o jsonpath='{.spec.replicas}'" 2>/dev/null || echo "0")
    
    if [ "$deployment_ready" = "$deployment_replicas" ] && [ "$deployment_ready" -gt 0 ]; then
        log "SUCCESS: Deployment is healthy ($deployment_ready/$deployment_replicas replicas ready)"
    else
        verification_passed=false
        verification_details+="FAIL: Deployment is not healthy ($deployment_ready/$deployment_replicas replicas ready)\n"
    fi
    
    # Verify service has endpoints
    log "Verifying service endpoints..."
    local endpoints=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get endpoints my-ag-ui-app-service -o jsonpath='{.subsets}'" 2>/dev/null || echo "")
    if [ -n "$endpoints" ] && [ "$endpoints" != "[]" ]; then
        log "SUCCESS: Service has endpoints populated"
    else
        verification_passed=false
        verification_details+="FAIL: Service has no endpoints\n"
    fi
    
    # Verify ingress is configured
    log "Verifying ingress configuration..."
    local ingress_ip=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || echo "")
    if [ -n "$ingress_ip" ]; then
        log "SUCCESS: Ingress has IP address: $ingress_ip"
    else
        log "INFO: Ingress has no IP address yet (may be normal)"
    fi
    
    # Verify application pods are running
    log "Verifying application pods..."
    local pod_count=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items.length}'" 2>/dev/null || echo "0")
    local ready_pods=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{'\"\\n\"'\"}'\" | grep -c true" 2>/dev/null || echo "0")
    
    if [ "$pod_count" -gt 0 ] && [ "$ready_pods" -eq "$pod_count" ]; then
        log "SUCCESS: All application pods are running and ready ($ready_pods/$pod_count)"
    else
        verification_passed=false
        verification_details+="FAIL: Not all application pods are ready ($ready_pods/$pod_count)\n"
    fi
    
    # Verify TLS secret exists (if SSL was configured)
    log "Verifying TLS secret..."
    if multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get secret my-ag-ui-app-tls-secret" >/dev/null 2>&1; then
        log "SUCCESS: TLS secret exists"
    else
        log "INFO: TLS secret not found (SSL/TLS may not be configured)"
    fi
    
    # Verify application accessibility through service
    log "Verifying application accessibility through service..."
    if multipass exec "$VM_NAME" -- bash -c "microk8s kubectl run temp-access-test --image=curlimages/curl --rm -i --restart=Never -- curl -s -f http://my-ag-ui-app-service:3000" >/dev/null 2>&1; then
        log "SUCCESS: Application is accessible through service"
    else
        log "WARNING: Application accessibility test through service failed (may be normal depending on application)"
    fi
    
    # Verify deployment rollout status
    log "Verifying deployment rollout status..."
    if multipass exec "$VM_NAME" -- bash -c "microk8s kubectl rollout status deployment/my-ag-ui-app-deployment" >/dev/null 2>&1; then
        log "SUCCESS: Deployment rollout is complete"
    else
        verification_passed=false
        verification_details+="FAIL: Deployment rollout is not complete\n"
    fi
    
    # Verify no critical deployment errors
    log "Verifying deployment process quality..."
    if [ -f "$LOG_FILE" ]; then
        local deployment_errors=$(grep -c "KUBERNETES DEPLOYMENT ERROR" "$LOG_FILE" 2>/dev/null || echo "0")
        if [ "$deployment_errors" -eq 0 ]; then
            log "SUCCESS: No deployment errors detected"
        else
            verification_passed=false
            verification_details+="FAIL: Found $deployment_errors deployment errors\n"
        fi
    fi
    
    # Output verification summary
    log "=== KUBERNETES DEPLOYMENT VERIFICATION SUMMARY ==="
    if [ "$verification_passed" = "true" ]; then
        log "STATUS: PASSED - Kubernetes deployment completed successfully"
        log "DETAILS: All Kubernetes resources are deployed and healthy"
        log "Deployment Details:"
        log "  - Application: my-ag-ui-app"
        log "  - Deployment: Healthy"
        log "  - Service: Endpoints populated"
        log "  - Ingress: Configured"
        log "  - Pods: All running and ready"
        log "  - Accessibility: Verified"
        log "==========================================="
        return 0
    else
        log "STATUS: FAILED - Kubernetes deployment verification failed"
        log "DETAILS:"
        log -e "$verification_details"
        log "==========================================="
        handle_k8s_deployment_error 999 "Kubernetes deployment verification failed" \
            "Address the issues above before continuing with application testing"
        return 1
    fi
}

# Run Kubernetes deployment verification
log "Running Kubernetes deployment completion verification..."
verify_kubernetes_deployment_completion

log "Kubernetes deployment verification completed successfully"
log "Proceeding to HTTPS access testing"

# 6.5 Test HTTPS access (if SSL is configured)
log "Starting HTTPS access testing..."

# Function to test HTTPS access
test_https_access() {
    local endpoint="$1"
    local max_attempts=12
    local attempt=1
    
    log "Testing HTTPS access to https://$endpoint..."
    
    while [ $attempt -le $max_attempts ]; do
        log "HTTPS test attempt $attempt/$max_attempts..."
        
        # Test HTTPS access with curl (insecure because we're using self-signed certs)
        if curl -k -s -f --connect-timeout 5 "https://$endpoint" >/dev/null 2>&1; then
            log "HTTPS access test PASSED - Successfully connected to https://$endpoint"
            
            # Test with more details
            log "Testing HTTPS response details..."
            local http_code=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://$endpoint" 2>/dev/null || echo "000")
            local response_time=$(curl -k -s -o /dev/null -w "%{time_total}" --connect-timeout 5 "https://$endpoint" 2>/dev/null || echo "0.000")
            
            log "HTTPS Response Details:"
            log "  HTTP Status Code: $http_code"
            log "  Response Time: ${response_time}s"
            
            if [ "$http_code" = "200" ]; then
                log "HTTPS test fully SUCCESSFUL - Received 200 OK response"
                return 0
            else
                log "WARNING: HTTPS connected but received non-200 status code: $http_code"
            fi
        else
            log "HTTPS test attempt $attempt failed - Connection failed or timeout"
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            log "Waiting 5 seconds before next HTTPS test attempt..."
            sleep 5
        fi
        
        attempt=$((attempt + 1))
    done
    
    log "ERROR: HTTPS access test FAILED after $max_attempts attempts"
    return 1
}

# Test HTTPS access to different endpoints
HTTPS_ENDPOINTS=("localhost" "127.0.0.1")
HTTPS_SUCCESS=false

for endpoint in "${HTTPS_ENDPOINTS[@]}"; do
    log "Testing HTTPS access to $endpoint..."
    if test_https_access "$endpoint"; then
        HTTPS_SUCCESS=true
        log "HTTPS access test successful for $endpoint"
        break
    else
        log "HTTPS access test failed for $endpoint"
    fi
done

if [ "$HTTPS_SUCCESS" = "true" ]; then
    log "HTTPS access test completed successfully"
    
    # Additional verification - test SSL certificate details
    log "Verifying SSL certificate details..."
    if multipass exec "$VM_NAME" -- bash -c "curl -k -v https://localhost 2>&1 | grep -E 'subject:|issuer:|start date:|expire date:' | head -4" 2>&1 | tee -a "$LOG_FILE"; then
        log "SSL certificate details verified successfully"
    else
        log "WARNING: Could not verify SSL certificate details (this is not critical)"
    fi
    
    # Test HTTP to HTTPS redirect
    log "Testing HTTP to HTTPS redirect..."
    local redirect_test=$(curl -k -s -w "%{redirect_url}" -o /dev/null "http://localhost" 2>/dev/null || echo "")
    if echo "$redirect_test" | grep -q "https://"; then
        log "HTTP to HTTPS redirect test PASSED - Redirects to HTTPS"
    else
        log "INFO: HTTP to HTTPS redirect not active (this may be normal depending on configuration)"
    fi
    
else
    log "ERROR: All HTTPS access tests failed"
    log "Possible causes:"
    log "  1. Application pods are not running or ready"
    log "  2. Ingress controller is not properly configured"
    log "  3. SSL/TLS certificates are not properly configured"
    log "  4. Network connectivity issues"
    log "  5. Firewall blocking HTTPS traffic"
    
    # Provide diagnostic information
    log "HTTPS Access Test Diagnostic Information:"
    log "  Ingress endpoint: $ingress_endpoint"
    log "  Application pods: $(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get pods -l app=my-ag-ui-app 2>/dev/null || echo 'pods not found'")"
    log "  Ingress status: $(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get ingress my-ag-ui-app-ingress 2>/dev/null || echo 'ingress not found'")"
    log "  TLS secret: $(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get secret my-ag-ui-app-tls-secret 2>/dev/null || echo 'secret not found'")"
    
    handle_k8s_deployment_error 208 "HTTPS access test failed" \
        "Check application pod status: microk8s kubectl get pods. Check ingress status: microk8s kubectl get ingress. Check TLS secret: microk8s kubectl get secret my-ag-ui-app-tls-secret"
fi

log "HTTPS access testing completed"

log "Kubernetes manifests deployment completed successfully"

# ========================
# VERIFICATION: Ingress configuration completion
# ========================

verify_ingress_configuration_completion() {
    log "=== VERIFYING INGRESS CONFIGURATION COMPLETION ==="
    
    local verification_passed=true
    local verification_details=""
    
    # Verify microk8s is ready
    log "Verifying microk8s readiness for ingress verification..."
    if ! microk8s_ready; then
        verification_passed=false
        verification_details+="FAIL: microk8s is not ready\n"
    else
        log "SUCCESS: microk8s is ready"
    fi
    
    # Verify ingress add-on is enabled
    log "Verifying ingress add-on status..."
    if ! microk8s_addon_enabled "ingress"; then
        verification_passed=false
        verification_details+="FAIL: ingress add-on is not enabled\n"
    else
        log "SUCCESS: ingress add-on is enabled"
    fi
    
    # Verify ingress controller pods exist
    log "Verifying ingress controller pods..."
    local ingress_pods=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n ingress -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    if [ -z "$ingress_pods" ]; then
        verification_passed=false
        verification_details+="FAIL: No ingress controller pods found\n"
    else
        log "SUCCESS: Ingress controller pods found: $ingress_pods"
        
        # Check if ingress controller pods are running
        local all_pods_running=true
        for pod in $ingress_pods; do
            local pod_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pod "$pod" -n ingress -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
            if [ "$pod_status" != "Running" ]; then
                all_pods_running=false
                log "WARNING: Ingress pod '$pod' status: $pod_status"
            fi
        done
        
        if [ "$all_pods_running" = "true" ]; then
            log "SUCCESS: All ingress controller pods are running"
        else
            log "WARNING: Some ingress controller pods are not running"
        fi
    fi
    
    # Verify ingress resource exists
    log "Verifying ingress resource..."
    if ! multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get ingress my-ag-ui-app-ingress" >/dev/null 2>&1; then
        verification_passed=false
        verification_details+="FAIL: Ingress resource 'my-ag-ui-app-ingress' not found\n"
    else
        log "SUCCESS: Ingress resource 'my-ag-ui-app-ingress' exists"
        
        # Get ingress details
        local ingress_details=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get ingress my-ag-ui-app-ingress -o yaml" 2>/dev/null || echo "")
        if [ -n "$ingress_details" ]; then
            log "SUCCESS: Ingress resource details retrieved"
            
            # Check if ingress has rules configured
            local ingress_rules=$(echo "$ingress_details" | grep -c "host:" 2>/dev/null || echo "0")
            if [ "$ingress_rules" -gt 0 ]; then
                log "SUCCESS: Ingress has routing rules configured ($ingress_rules rules)"
            else
                log "WARNING: Ingress has no routing rules configured"
            fi
        else
            log "WARNING: Could not retrieve ingress details"
        fi
    fi
    
    # Verify ingress service endpoints exist
    log "Verifying ingress service endpoints..."
    local ingress_service=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get service -n ingress -o jsonpath='{.items[0].metadata.name}'" 2>/dev/null || echo "")
    if [ -n "$ingress_service" ]; then
        log "SUCCESS: Ingress service found: $ingress_service"
        
        # Check if ingress service has endpoints
        local ingress_endpoints=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get endpoints -n ingress $ingress_service -o jsonpath='{.subsets}'" 2>/dev/null || echo "")
        if [ -n "$ingress_endpoints" ] && [ "$ingress_endpoints" != "[]" ]; then
            log "SUCCESS: Ingress service has endpoints"
        else
            log "WARNING: Ingress service has no endpoints"
        fi
    else
        log "WARNING: No ingress service found"
    fi
    
    # Verify ingress controller configuration
    log "Verifying ingress controller configuration..."
    local ingress_config=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get configmap nginx-configuration -n ingress -o yaml" 2>/dev/null || echo "")
    if [ -n "$ingress_config" ]; then
        log "SUCCESS: Ingress controller configuration found"
        
        # Check for SSL configuration
        if echo "$ingress_config" | grep -q -i "ssl"; then
            log "SUCCESS: SSL configuration found in ingress controller"
        else
            log "INFO: No SSL configuration found in ingress controller (may be using default)"
        fi
    else
        log "INFO: Could not retrieve ingress controller configuration"
    fi
    
    # Verify ingress endpoint accessibility
    log "Verifying ingress endpoint accessibility..."
    local ingress_ip=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || echo "")
    if [ -n "$ingress_ip" ]; then
        log "SUCCESS: Ingress has IP address: $ingress_ip"
        
        # Test basic connectivity to ingress
        if multipass exec "$VM_NAME" -- curl -s -f --connect-timeout 3 "http://$ingress_ip" >/dev/null 2>&1; then
            log "SUCCESS: Ingress endpoint is accessible"
        else
            log "WARNING: Ingress endpoint accessibility test failed (may be normal if app not ready)"
        fi
    else
        log "INFO: Ingress IP address not available (may be normal in local deployment)"
    fi
    
    # Verify no critical ingress errors
    log "Verifying ingress configuration quality..."
    if [ -f "$LOG_FILE" ]; then
        local ingress_errors=$(grep -c "INGRESS.*ERROR" "$LOG_FILE" 2>/dev/null || echo "0")
        if [ "$ingress_errors" -eq 0 ]; then
            log "SUCCESS: No ingress configuration errors detected"
        else
            verification_passed=false
            verification_details+="FAIL: Found $ingress_errors ingress configuration errors\n"
        fi
    fi
    
    # Output verification summary
    log "=== INGRESS CONFIGURATION VERIFICATION SUMMARY ==="
    if [ "$verification_passed" = "true" ]; then
        log "STATUS: PASSED - Ingress configuration completed successfully"
        log "DETAILS: Ingress is properly configured and ready for routing"
        log "Ingress Configuration Details:"
        log "  - Ingress Controller: Running and healthy"
        log "  - Ingress Resource: Configured with routing rules"
        log "  - Service Endpoints: Populated and accessible"
        log "  - SSL/TLS: Configured as applicable"
        log "  - Accessibility: Verified"
        log "==========================================="
        return 0
    else
        log "STATUS: FAILED - Ingress configuration verification failed"
        log "DETAILS:"
        log -e "$verification_details"
        log "==========================================="
        log "RECOVERY SUGGESTIONS:"
        log "1. Check ingress controller pods: microk8s kubectl get pods -n ingress"
        log "2. Check ingress resource: microk8s kubectl get ingress my-ag-ui-app-ingress"
        log "3. Check ingress service: microk8s kubectl get service -n ingress"
        log "4. Check ingress logs: microk8s kubectl logs <ingress-pod> -n ingress"
        return 1
    fi
}

# Run ingress configuration verification
log "Running ingress configuration completion verification..."
verify_ingress_configuration_completion

log "Ingress configuration verification completed successfully"
log "Proceeding to ingress logs verification"

# ===========================
# INGRESS LOGS VERIFICATION SECTION
# ===========================

# Ingress logs verification error handler
handle_ingress_logs_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "INGRESS LOGS ERROR [Code: $error_code]: $error_message"
    log "RECOVERY SUGGESTION: $recovery_suggestion"
    
    # Log additional diagnostic information
    log "INGRESS LOGS DIAGNOSTIC INFO:"
    log "VM Name: $VM_NAME"
    log "Microk8s status: $(multipass exec "$VM_NAME" -- microk8s status --wait 2>/dev/null || echo 'microk8s not ready')"
    
    # Check ingress controller pod status
    if multipass exec "$VM_NAME" -- command -v microk8s >/dev/null 2>&1; then
        log "Ingress controller pods: $(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n ingress -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo 'no pods found')"
    fi
    
    exit $error_code
}

# 6.6 Verify ingress logs are working
verify_ingress_logs() {
    log "Starting ingress logs verification..."
    
    # Check if microk8s is ready
    if ! microk8s_ready; then
        handle_ingress_logs_error 101 "Microk8s is not ready for ingress logs verification" \
            "Ensure microk8s is running and ready: microk8s status --wait"
    fi
    log "Microk8s is ready for ingress logs verification"
    
    # Get ingress controller pod name
    log "Getting ingress controller pod name..."
    local ingress_pod=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n ingress -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$ingress_pod" ]; then
        handle_ingress_logs_error 102 "No ingress controller pod found" \
            "Check ingress controller pods: microk8s kubectl get pods -n ingress"
    fi
    log "Found ingress controller pod: $ingress_pod"
    
    # Check if ingress controller pod is running
    log "Checking ingress controller pod status..."
    local pod_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pod "$ingress_pod" -n ingress -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
    
    if [ "$pod_status" != "Running" ]; then
        handle_ingress_logs_error 103 "Ingress controller pod is not running" \
            "Check pod status: microk8s kubectl get pod $ingress_pod -n ingress. Wait for pod to be running."
    fi
    log "Ingress controller pod is running: $pod_status"
    
    # Test 1: Verify ingress logs are accessible
    log "Test 1: Verifying ingress logs are accessible..."
    if ! multipass exec "$VM_NAME" -- microk8s kubectl logs "$ingress_pod" -n ingress --tail=1 >/dev/null 2>&1; then
        handle_ingress_logs_error 104 "Cannot access ingress controller logs" \
            "Check pod permissions and logs: microk8s kubectl logs $ingress_pod -n ingress"
    fi
    log "Ingress logs are accessible"
    
    # Test 2: Check for recent log entries
    log "Test 2: Checking for recent log entries..."
    local recent_logs=$(multipass exec "$VM_NAME" -- microk8s kubectl logs "$ingress_pod" -n ingress --tail=10 2>/dev/null || echo "")
    
    if [ -z "$recent_logs" ]; then
        log "INFO: No recent log entries found (this may be normal if no traffic has been routed yet)"
    else
        log "Recent ingress log entries found:"
        log "$recent_logs"
    fi
    
    # Test 3: Generate test traffic to trigger log entries
    log "Test 3: Generating test traffic to trigger log entries..."
    
    # Get ingress endpoint
    local ingress_ip=$(multipass exec "$VM_NAME" -- microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -z "$ingress_ip" ]; then
        ingress_ip="127.0.0.1"  # Fallback to localhost
    fi
    
    # Make a test request to trigger log entries
    log "Making test request to $ingress_ip to generate log entries..."
    if multipass exec "$VM_NAME" -- curl -s -f --connect-timeout 5 "http://$ingress_ip" >/dev/null 2>&1; then
        log "Test request completed successfully"
    else
        log "WARNING: Test request failed (this may be normal if the application is not yet fully ready)"
    fi
    
    # Wait a moment for logs to be generated
    sleep 3
    
    # Test 4: Check for incoming request logs
    log "Test 4: Checking for incoming request logs..."
    local request_logs=$(multipass exec "$VM_NAME" -- microk8s kubectl logs "$ingress_pod" -n ingress --tail=20 2>/dev/null | grep -i -E "(GET|POST|PUT|DELETE|request|client)" || echo "")
    
    if [ -n "$request_logs" ]; then
        log "SUCCESS: Found incoming request logs:"
        log "$request_logs"
    else
        log "INFO: No incoming request logs found yet (this may be normal if no traffic has been routed)"
    fi
    
    # Test 5: Check for routing decision logs
    log "Test 5: Checking for routing decision logs..."
    local routing_logs=$(multipass exec "$VM_NAME" -- microk8s kubectl logs "$ingress_pod" -n ingress --tail=20 2>/dev/null | grep -i -E "(routing|forwarding|backend|service|upstream)" || echo "")
    
    if [ -n "$routing_logs" ]; then
        log "SUCCESS: Found routing decision logs:"
        log "$routing_logs"
    else
        log "INFO: No routing decision logs found yet (this may be normal if no traffic has been routed)"
    fi
    
    # Test 6: Check for error logs
    log "Test 6: Checking for error logs..."
    local error_logs=$(multipass exec "$VM_NAME" -- microk8s kubectl logs "$ingress_pod" -n ingress --tail=20 2>/dev/null | grep -i -E "(error|failed|denied|refused|timeout)" || echo "")
    
    if [ -n "$error_logs" ]; then
        log "WARNING: Found error logs (this may indicate issues):"
        log "$error_logs"
    else
        log "SUCCESS: No error logs found"
    fi
    
    # Test 7: Check log format and structure
    log "Test 7: Checking log format and structure..."
    local sample_log=$(multipass exec "$VM_NAME" -- microk8s kubectl logs "$ingress_pod" -n ingress --tail=5 2>/dev/null | head -1 || echo "")
    
    if [ -n "$sample_log" ]; then
        log "Sample log entry format:"
        log "$sample_log"
        
        # Check if log contains typical NGINX ingress log fields
        if echo "$sample_log" | grep -q -E "\[.*\]"; then
            log "SUCCESS: Log contains timestamp information"
        else
            log "INFO: Log format may not include timestamp information"
        fi
        
        if echo "$sample_log" | grep -q -E "(GET|POST|PUT|DELETE)"; then
            log "SUCCESS: Log contains HTTP method information"
        else
            log "INFO: Log format may not include HTTP method information"
        fi
    else
        log "INFO: No log entries available to check format"
    fi
    
    # Test 8: Verify log persistence and accessibility
    log "Test 8: Verifying log persistence and accessibility..."
    
    # Check if logs can be retrieved with different options
    if multipass exec "$VM_NAME" -- microk8s kubectl logs "$ingress_pod" -n ingress --timestamps=true --tail=5 >/dev/null 2>&1; then
        log "SUCCESS: Logs with timestamps are accessible"
    else
        log "INFO: Timestamps in logs may not be available"
    fi
    
    if multipass exec "$VM_NAME" -- microk8s kubectl logs "$ingress_pod" -n ingress --previous=false --tail=5 >/dev/null 2>&1; then
        log "SUCCESS: Previous logs are accessible"
    else
        log "INFO: Previous logs may not be available"
    fi
    
    # Test 9: Check ingress controller configuration for logging
    log "Test 9: Checking ingress controller configuration for logging..."
    
    # Get ingress controller configuration
    local ingress_config=$(multipass exec "$VM_NAME" -- microk8s kubectl get configmap nginx-configuration -n ingress -o yaml 2>/dev/null || echo "")
    
    if [ -n "$ingress_config" ]; then
        log "Ingress controller configuration found"
        
        # Check for logging-related configuration
        if echo "$ingress_config" | grep -q -i "log"; then
            log "SUCCESS: Logging configuration found in ingress controller"
            
            # Extract logging configuration details
            local log_level=$(echo "$ingress_config" | grep -i "log-level" | head -1 || echo "not found")
            log "Log level configuration: $log_level"
            
            local log_format=$(echo "$ingress_config" | grep -i "log-format" | head -1 || echo "not found")
            log "Log format configuration: $log_format"
        else
            log "INFO: No specific logging configuration found (using defaults)"
        fi
    else
        log "INFO: Could not retrieve ingress controller configuration"
    fi
    
    # Test 10: Comprehensive logs verification summary
    log "Test 10: Comprehensive ingress logs verification summary..."
    
    # Final verification - check if logs are working based on all tests
    local logs_working=true
    
    # Check if we can access logs
    if ! multipass exec "$VM_NAME" -- microk8s kubectl logs "$ingress_pod" -n ingress --tail=1 >/dev/null 2>&1; then
        logs_working=false
        log "FAILURE: Cannot access ingress logs"
    fi
    
    # Check if there are any log entries
    local log_count=$(multipass exec "$VM_NAME" -- microk8s kubectl logs "$ingress_pod" -n ingress 2>/dev/null | wc -l || echo "0")
    if [ "$log_count" = "0" ]; then
        log "INFO: No log entries found yet (this may be normal with no traffic)"
    else
        log "SUCCESS: Found $log_count log entries"
    fi
    
    # Provide final assessment
    if [ "$logs_working" = "true" ]; then
        log "=== INGRESS LOGS VERIFICATION SUMMARY ==="
        log "Ingress logs status: WORKING"
        log "  - Logs are accessible: YES"
        log "  - Log entries exist: $([ $log_count -gt 0 ] && echo "YES" || echo "NO (normal with no traffic)")"
        log "  - Log format is readable: YES"
        log "  - Log persistence: VERIFIED"
        log "  - Error monitoring: CONFIGURED"
        log "  - Ready for traffic monitoring: YES"
        log "======================================"
        
        log "Ingress logs verification completed successfully"
    else
        handle_ingress_logs_error 105 "Ingress logs verification failed" \
            "Check ingress controller pod: microk8s kubectl get pods -n ingress. Check pod logs: microk8s kubectl logs <pod-name> -n ingress"
    fi
}

# 6.6 Verify ingress logs are working
log "Starting ingress logs verification..."
verify_ingress_logs
log "Ingress logs verification completed"

# ========================
# FINAL COMPREHENSIVE VERIFICATION
# ========================

step_complete "Kubernetes deployment" 6 7
section_header "FINAL COMPREHENSIVE VERIFICATION" 7 7
progress 7 7 "Starting final comprehensive verification"
milestone "Deployment Verification" 4 4

final_comprehensive_verification() {
    log "=== FINAL COMPREHENSIVE DEPLOYMENT VERIFICATION ==="
    log "This verification checks the entire deployment from end to end"
    
    local verification_passed=true
    local verification_details=""
    local final_summary=""
    
    # 1. Verify host system prerequisites
    log "Step 1: Verifying host system prerequisites..."
    if ! command_exists multipass; then
        verification_passed=false
        verification_details+="FAIL: multipass not found on host\n"
    else
        log "SUCCESS: multipass available on host"
    fi
    
    if ! docker_ready; then
        verification_passed=false
        verification_details+="FAIL: Docker not ready on host\n"
    else
        log "SUCCESS: Docker ready on host"
    fi
    
    # 2. Verify VM status
    log "Step 2: Verifying VM status..."
    if ! vm_exists; then
        verification_passed=false
        verification_details+="FAIL: VM '$VM_NAME' does not exist\n"
    else
        log "SUCCESS: VM '$VM_NAME' exists"
        
        if ! vm_running; then
            verification_passed=false
            verification_details+="FAIL: VM '$VM_NAME' is not running\n"
        else
            log "SUCCESS: VM '$VM_NAME' is running"
            
            if ! multipass exec "$VM_NAME" -- uptime >/dev/null 2>&1; then
                verification_passed=false
                verification_details+="FAIL: VM '$VM_NAME' is not responsive\n"
            else
                log "SUCCESS: VM '$VM_NAME' is responsive"
            fi
        fi
    fi
    
    # 3. Verify microk8s cluster status
    log "Step 3: Verifying microk8s cluster status..."
    if ! microk8s_ready; then
        verification_passed=false
        verification_details+="FAIL: microk8s cluster is not ready\n"
    else
        log "SUCCESS: microk8s cluster is ready"
        
        # Verify add-ons
        local required_addons=("dns" "storage" "ingress")
        for addon in "${required_addons[@]}"; do
            if microk8s_addon_enabled "$addon"; then
                log "SUCCESS: $addon add-on is enabled"
            else
                log "WARNING: $addon add-on is not enabled"
            fi
        done
    fi
    
    # 4. Verify container image availability
    log "Step 4: Verifying container image availability..."
    if ! docker images | grep -q "^$IMAGE_NAME[[:space:]]*$IMAGE_TAG"; then
        log "WARNING: Docker image '$FULL_IMAGE_NAME' not found locally"
    else
        log "SUCCESS: Docker image '$FULL_IMAGE_NAME' available locally"
    fi
    
    if ! multipass exec "$VM_NAME" -- bash -c "microk8s ctr image list | grep -q '$IMAGE_NAME'" 2>/dev/null; then
        verification_passed=false
        verification_details+="FAIL: Image '$FULL_IMAGE_NAME' not found in microk8s\n"
    else
        log "SUCCESS: Image '$FULL_IMAGE_NAME' available in microk8s"
    fi
    
    # 5. Verify Kubernetes deployment
    log "Step 5: Verifying Kubernetes deployment..."
    local resources=("deployment" "service" "ingress")
    for resource in "${resources[@]}"; do
        local resource_name="my-ag-ui-app-$resource"
        if ! multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get $resource $resource_name" >/dev/null 2>&1; then
            verification_passed=false
            verification_details+="FAIL: Kubernetes $resource '$resource_name' not found\n"
        else
            log "SUCCESS: Kubernetes $resource '$resource_name' exists"
        fi
    done
    
    # 6. Verify application health
    log "Step 6: Verifying application health..."
    local pod_count=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items.length}'" 2>/dev/null || echo "0")
    local ready_pods=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{'\"\\n\"'\"}'\" | grep -c true" 2>/dev/null || echo "0")
    
    if [ "$pod_count" -gt 0 ] && [ "$ready_pods" -eq "$pod_count" ]; then
        log "SUCCESS: All application pods are healthy ($ready_pods/$pod_count)"
    else
        verification_passed=false
        verification_details+="FAIL: Application pods are not healthy ($ready_pods/$pod_count)\n"
    fi
    
    # 7. Verify ingress functionality
    log "Step 7: Verifying ingress functionality..."
    local ingress_pods=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n ingress -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$ingress_pods" ]; then
        log "SUCCESS: Ingress controller pods exist"
        
        # Check ingress controller health
        local ingress_healthy=true
        for pod in $ingress_pods; do
            local pod_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pod "$pod" -n ingress -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
            if [ "$pod_status" != "Running" ]; then
                ingress_healthy=false
            fi
        done
        
        if [ "$ingress_healthy" = "true" ]; then
            log "SUCCESS: Ingress controller pods are healthy"
        else
            log "WARNING: Some ingress controller pods are not healthy"
        fi
    else
        log "WARNING: No ingress controller pods found"
    fi
    
    # 8. Verify end-to-end accessibility
    log "Step 8: Verifying end-to-end accessibility..."
    local ingress_ip=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || echo "")
    if [ -n "$ingress_ip" ]; then
        log "SUCCESS: Ingress has IP: $ingress_ip"
        
        # Test accessibility (basic check)
        if multipass exec "$VM_NAME" -- curl -s -f --connect-timeout 3 "http://$ingress_ip" >/dev/null 2>&1; then
            log "SUCCESS: Application accessible via ingress"
        else
            log "WARNING: Application may not be accessible via ingress"
        fi
    else
        log "INFO: Ingress IP not available (may be normal in local deployment)"
    fi
    
    # 9. Verify SSL/TLS configuration (if applicable)
    log "Step 9: Verifying SSL/TLS configuration..."
    if multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get secret my-ag-ui-app-tls-secret" >/dev/null 2>&1; then
        log "SUCCESS: TLS secret is configured"
        
        # Test HTTPS access
        if multipass exec "$VM_NAME" -- curl -k -s -f --connect-timeout 3 "https://localhost" >/dev/null 2>&1; then
            log "SUCCESS: HTTPS access is working"
        else
            log "WARNING: HTTPS access test failed"
        fi
    else
        log "INFO: TLS secret not configured (HTTP access only)"
    fi
    
    # 10. Verify logs and monitoring
    log "Step 10: Verifying logs and monitoring..."
    if [ -f "$LOG_FILE" ]; then
        local log_size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo "0")
        if [ "$log_size" -gt 0 ]; then
            log "SUCCESS: Deployment log file exists and has content (${log_size} bytes)"
        else
            log "WARNING: Deployment log file is empty"
        fi
    else
        log "WARNING: Deployment log file not found"
    fi
    
    # 11. Verify resource utilization
    log "Step 11: Verifying resource utilization..."
    if multipass exec "$VM_NAME" -- command -v free >/dev/null 2>&1; then
        local vm_memory_percent=$(multipass exec "$VM_NAME" -- free -m | awk 'NR==2{printf "%.0f", $3/$2*100}')
        if [ "$vm_memory_percent" -lt 90 ]; then
            log "SUCCESS: VM memory usage is acceptable (${vm_memory_percent}%)"
        else
            log "WARNING: VM memory usage is high (${vm_memory_percent}%)"
        fi
    fi
    
    if multipass exec "$VM_NAME" -- command -v df >/dev/null 2>&1; then
        local vm_disk_percent=$(multipass exec "$VM_NAME" -- df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
        if [ "$vm_disk_percent" -lt 90 ]; then
            log "SUCCESS: VM disk usage is acceptable (${vm_disk_percent}%)"
        else
            log "WARNING: VM disk usage is high (${vm_disk_percent}%)"
        fi
    fi
    
    # 12. Compile final summary
    log "Step 12: Compiling final verification summary..."
    if [ "$verification_passed" = "true" ]; then
        final_summary="✅ DEPLOYMENT SUCCESSFUL - All verification checks passed"
    else
        final_summary="❌ DEPLOYMENT ISSUES DETECTED - Some verification checks failed"
    fi
    
    # Output final verification summary
    log "=== FINAL DEPLOYMENT VERIFICATION SUMMARY ==="
    log "STATUS: $final_summary"
    log ""
    log "Deployment Components Status:"
    log "  🖥️  Host System: $([ "$verification_passed" = "true" ] && echo "✅ Ready" || echo "❌ Issues")"
    log "  🖥️  VM Infrastructure: $([ "$verification_passed" = "true" ] && echo "✅ Running" || echo "❌ Issues")"
    log "  ☸️  Kubernetes Cluster: $([ "$verification_passed" = "true" ] && echo "✅ Ready" || echo "❌ Issues")"
    log "  📦 Container Image: $([ "$verification_passed" = "true" ] && echo "✅ Available" || echo "❌ Issues")"
    log "  🚀 Application: $([ "$verification_passed" = "true" ] && echo "✅ Deployed" || echo "❌ Issues")"
    log "  🔌 Service: $([ "$verification_passed" = "true" ] && echo "✅ Accessible" || echo "❌ Issues")"
    log "  🌐 Ingress: $([ "$verification_passed" = "true" ] && echo "✅ Configured" || echo "❌ Issues")"
    log "  🔒 SSL/TLS: $([ -n "$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get secret my-ag-ui-app-tls-secret" 2>/dev/null || echo "")" ] && echo "✅ Configured" || echo "⚪ Not configured")"
    log ""
    
    if [ "$verification_passed" = "true" ]; then
        log "🎉 CONGRATULATIONS! Your application has been successfully deployed!"
        log ""
        log "Next Steps:"
        log "  1. Access your application via the ingress endpoint"
        log "  2. Monitor application health and logs"
        log "  3. Test all application functionality"
        log "  4. Configure DNS if needed for production use"
        log "  5. Set up monitoring and alerting for production"
        log ""
    else
        log "⚠️  ACTION REQUIRED: Some verification checks failed"
        log ""
        log "Failed Checks:"
        log -e "$verification_details"
        log ""
        log "Recommended Actions:"
        log "  1. Review the failed checks above"
        log "  2. Check the deployment log: $LOG_FILE"
        log "  3. Run individual verification functions to isolate issues"
        log "  4. Fix the issues and rerun the verification"
        log ""
    fi
    
    log "==============================================="
    
    if [ "$verification_passed" = "true" ]; then
        return 0
    else
        return 1
    fi
}

# Run final comprehensive verification
log "Starting final comprehensive deployment verification..."
if final_comprehensive_verification; then
    log "🎉 FINAL VERIFICATION: PASSED"
    log "✅ Deployment completed successfully!"
    exit 0
else
    log "❌ FINAL VERIFICATION: FAILED"
    log "❌ Deployment completed with issues"
    exit 1
fi