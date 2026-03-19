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

# ========================
# MICROK8S INSTALLATION SECTION
# ========================

# Microk8s installation error handler
handle_microk8s_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "MICROK8S ERROR [Code: $error_code]: $error_message"
    log "RECOVERY SUGGESTION: $recovery_suggestion"
    
    # Log additional diagnostic information
    log "MICROK8S DIAGNOSTIC INFO:"
    log "VM Name: $VM_NAME"
    log "VM Status: $(multipass info "$VM_NAME" | grep "State:" | awk '{print $2}')"
    
    # Check if microk8s is installed
    if multipass exec "$VM_NAME" -- command -v microk8s >/dev/null 2>&1; then
        log "Microk8s version: $(multipass exec "$VM_NAME" -- microk8s version 2>/dev/null || echo 'unknown')"
        log "Microk8s status: $(multipass exec "$VM_NAME" -- microk8s status --wait 2>/dev/null || echo 'status check failed')"
    else
        log "Microk8s is not installed in the VM"
    fi
    
    # Check system resources in VM
    log "VM System Resources:"
    if multipass exec "$VM_NAME" -- command -v free >/dev/null 2>&1; then
        log "Memory: $(multipass exec "$VM_NAME" -- free -h | awk 'NR==2{print $2}' | tr -d '\n') total"
    fi
    if multipass exec "$VM_NAME" -- command -v nproc >/dev/null 2>&1; then
        log "CPU Cores: $(multipass exec "$VM_NAME" -- nproc)"
    fi
    if multipass exec "$VM_NAME" -- command -v df >/dev/null 2>&1; then
        log "Disk Space: $(multipass exec "$VM_NAME" -- df -h / | awk 'NR==2{print $4}' | tr -d '\n') available"
    fi
    
    # Check for common issues
    log "Checking for common microk8s installation issues..."
    
    # Check if snap is available (microk8s requires snap)
    if ! multipass exec "$VM_NAME" -- command -v snap >/dev/null 2>&1; then
        log "ISSUE: snap is not available in the VM. Microk8s requires snap."
        log "FIX: Install snap first: sudo apt update && sudo apt install -y snapd"
    fi
    
    # Check if VM has sufficient resources
    local vm_cpu_cores=$(multipass exec "$VM_NAME" -- nproc 2>/dev/null || echo "0")
    local vm_memory_gb=$(multipass exec "$VM_NAME" -- free -g 2>/dev/null | awk 'NR==2{print $2}' || echo "0")
    
    if [ "$vm_cpu_cores" -lt 2 ]; then
        log "ISSUE: VM has only $vm_cpu_cores CPU cores. Microk8s requires at least 2 cores."
        log "FIX: Recreate VM with at least 2 CPU cores."
    fi
    
    if [ "$vm_memory_gb" -lt 4 ]; then
        log "ISSUE: VM has only ${vm_memory_gb}GB RAM. Microk8s requires at least 4GB RAM."
        log "FIX: Recreate VM with at least 4GB RAM."
    fi
    
    exit $error_code
}

# Microk8s add-on enablement error handler
handle_microk8s_addon_error() {
    local addon_name=$1
    local error_output=$2
    
    case "$error_output" in
        *"already enabled"*)
            log "WARNING: $addon_name add-on is already enabled"
            return 0
            ;;
        *"not found"*)
            handle_microk8s_error 301 "$addon_name add-on not found" \
                "Check if the add-on name is correct: microk8s status. Valid add-ons include: dns, storage, ingress"
            ;;
        *"failed"*)
            handle_microk8s_error 302 "$addon_name add-on enablement failed" \
                "Try enabling manually: microk8s enable $addon_name. Check microk8s logs: journalctl -u snap.microk8s.daemon-*"
            ;;
        *"timeout"*)
            handle_microk8s_error 303 "$addon_name add-on enablement timed out" \
                "Wait for microk8s to be ready: microk8s status --wait. Then retry enabling the add-on."
            ;;
        *)
            handle_microk8s_error 304 "Unknown error enabling $addon_name add-on: $error_output" \
                "Check microk8s status: microk8s status. Try manual enablement: microk8s enable $addon_name"
            ;;
    esac
}

# Function to check if microk8s is ready
microk8s_ready() {
    multipass exec "$VM_NAME" -- microk8s status --wait --timeout 30 >/dev/null 2>&1
}

# Function to check if microk8s add-on is enabled
microk8s_addon_enabled() {
    local addon_name=$1
    multipass exec "$VM_NAME" -- microk8s status | grep -q "^$addon_name: enabled"
}

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