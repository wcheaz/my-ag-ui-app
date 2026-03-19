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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if VM exists
vm_exists() {
    multipass list | grep -q "^$VM_NAME "
}

# Function to check if VM is running
vm_running() {
    multipass info "$VM_NAME" | grep -q "State: Running"
}

# =====================
# VM PROVISIONING SECTION
# =====================

log "Starting VM provisioning..."

# 3.2 Add multipass installation check to deployment script
log "Checking multipass installation..."
if ! command_exists multipass; then
    handle_error "multipass is not installed. Please install multipass before running this script. Installation instructions: https://multipass.run/install"
fi
log "multipass is installed: $(multipass version)"

# 3.3 Configure VM creation with 4 CPUs, 7.7GiB RAM, 19.3GiB disk
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
    local vm_creation_output
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

log "VM networking verification completed successfully"

# 3.6 Add VM status monitoring during deployment
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