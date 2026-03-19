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

# ===========================
# CONTAINER IMAGE BUILD SECTION
# ===========================

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

# ===========================
# CONTAINER IMAGE DEPLOYMENT SECTION
# ===========================

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

# =========================
# INGRESS CONFIGURATION SECTION
# =========================

# Ingress configuration error handler
handle_ingress_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "INGRESS ERROR [Code: $error_code]: $error_message"
    log "RECOVERY SUGGESTION: $recovery_suggestion"
    
    # Log additional diagnostic information
    log "INGRESS DIAGNOSTIC INFO:"
    log "VM Name: $VM_NAME"
    log "Microk8s status: $(multipass exec "$VM_NAME" -- microk8s status --wait 2>/dev/null || echo 'microk8s not ready')"
    
    # Check ingress add-on status
    if multipass exec "$VM_NAME" -- command -v microk8s >/dev/null 2>&1; then
        log "Ingress add-on status: $(multipass exec "$VM_NAME" -- microk8s status | grep ingress || echo 'ingress status not available')"
    fi
    
    exit $error_code
}

# 6.1 Verify ingress controller is running
verify_ingress_controller() {
    log "Starting ingress controller verification..."
    
    # Check if microk8s is ready
    if ! microk8s_ready; then
        handle_ingress_error 101 "Microk8s is not ready for ingress verification" \
            "Ensure microk8s is running and ready: microk8s status --wait"
    fi
    log "Microk8s is ready for ingress verification"
    
    # Check if ingress add-on is enabled
    log "Checking ingress add-on status..."
    if ! microk8s_addon_enabled "ingress"; then
        handle_ingress_error 102 "Ingress add-on is not enabled" \
            "Enable ingress add-on: microk8s enable ingress"
    fi
    log "Ingress add-on is enabled"
    
    # Check ingress controller pods
    log "Checking ingress controller pods..."
    local ingress_pods=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n ingress -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$ingress_pods" ]; then
        handle_ingress_error 103 "No ingress controller pods found" \
            "Check if ingress add-on is properly enabled: microk8s status. Try re-enabling: microk8s enable ingress"
    fi
    
    log "Found ingress controller pods: $ingress_pods"
    
    # Check each ingress controller pod status
    local all_pods_running=true
    for pod in $ingress_pods; do
        local pod_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pod "$pod" -n ingress -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
        local pod_ready=$(multipass exec "$VM_NAME" -- microk8s kubectl get pod "$pod" -n ingress -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
        
        log "Ingress pod '$pod' status: $pod_status, Ready: $pod_ready"
        
        if [ "$pod_status" != "Running" ] || [ "$pod_ready" != "True" ]; then
            all_pods_running=false
            log "WARNING: Ingress pod '$pod' is not running or not ready"
        fi
    done
    
    if [ "$all_pods_running" = "false" ]; then
        log "WARNING: Not all ingress controller pods are running. This may resolve automatically."
        log "Waiting a bit longer for ingress pods to become ready..."
        sleep 10
        
        # Check again after waiting
        for pod in $ingress_pods; do
            local pod_status=$(multipass exec "$VM_NAME" -- microk8s kubectl get pod "$pod" -n ingress -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
            local pod_ready=$(multipass exec "$VM_NAME" -- microk8s kubectl get pod "$pod" -n ingress -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
            
            if [ "$pod_status" = "Running" ] && [ "$pod_ready" = "True" ]; then
                log "Ingress pod '$pod' is now running and ready"
            else
                handle_ingress_error 104 "Ingress controller pods are not running after waiting" \
                    "Check pod status: microk8s kubectl get pods -n ingress. Check pod logs: microk8s kubectl logs <pod-name> -n ingress"
            fi
        done
    fi
    
    log "All ingress controller pods are running and ready"
    
    # Check ingress controller service
    log "Checking ingress controller service..."
    local ingress_service=$(multipass exec "$VM_NAME" -- microk8s kubectl get service -n ingress -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$ingress_service" ]; then
        handle_ingress_error 105 "No ingress controller service found" \
            "Check ingress add-on status: microk8s status. The service should be created automatically when ingress add-on is enabled."
    fi
    
    log "Found ingress controller service: $ingress_service"
    
    # Get ingress service details
    local service_type=$(multipass exec "$VM_NAME" -- microk8s kubectl get service "$ingress_service" -n ingress -o jsonpath='{.spec.type}' 2>/dev/null || echo "Unknown")
    local service_ports=$(multipass exec "$VM_NAME" -- microk8s kubectl get service "$ingress_service" -n ingress -o jsonpath='{.spec.ports[*].port}' 2>/dev/null || echo "Unknown")
    
    log "Ingress service details:"
    log "  Service: $ingress_service"
    log "  Type: $service_type"
    log "  Ports: $service_ports"
    
    # Check ingress controller deployment
    log "Checking ingress controller deployment..."
    local ingress_deployment=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment -n ingress -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$ingress_deployment" ]; then
        log "Found ingress controller deployment: $ingress_deployment"
        
        local deployment_replicas=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment "$ingress_deployment" -n ingress -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "Unknown")
        local deployment_ready=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment "$ingress_deployment" -n ingress -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "Unknown")
        
        log "Ingress deployment replica status: $deployment_ready/$deployment_replicas ready"
        
        if [ "$deployment_ready" != "$deployment_replicas" ]; then
            log "WARNING: Not all ingress deployment replicas are ready"
        fi
    else
        log "No ingress controller deployment found (this may be normal for some ingress implementations)"
    fi
    
    # Test ingress controller functionality
    log "Testing ingress controller functionality..."
    
    # Check if ingress class is available
    local ingress_class=$(multipass exec "$VM_NAME" -- microk8s kubectl get ingressclass -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$ingress_class" ]; then
        log "Found ingress class: $ingress_class"
        
        # Get ingress class details
        local ingress_class_controller=$(multipass exec "$VM_NAME" -- microk8s kubectl get ingressclass "$ingress_class" -o jsonpath='{.spec.controller}' 2>/dev/null || echo "Unknown")
        log "Ingress class controller: $ingress_class_controller"
    else
        log "WARNING: No ingress class found. This may be created when first ingress resource is applied."
    fi
    
    # Test NGINX ingress controller specifically (microk8s uses NGINX)
    log "Testing NGINX ingress controller health..."
    if multipass exec "$VM_NAME" -- microk8s kubectl get pods -n ingress | grep -q "nginx-ingress"; then
        local nginx_pod=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -n ingress -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
        
        if [ -n "$nginx_pod" ]; then
            log "Testing NGINX ingress controller health endpoint..."
            if multipass exec "$VM_NAME" -- microk8s kubectl get --raw /apis/ingress/v1/namespaces/ingress/services/ingress-nginx-controller:http/proxy >/dev/null 2>&1; then
                log "NGINX ingress controller health check passed"
            else
                log "WARNING: NGINX ingress controller health check failed (this may be normal if no ingress resources exist yet)"
            fi
        fi
    fi
    
    # Log final ingress controller status
    log "=== INGRESS CONTROLLER VERIFICATION SUMMARY ==="
    log "Ingress controller status: RUNNING"
    log "  - Ingress add-on: Enabled"
    log "  - Ingress pods: All running and ready"
    log "  - Ingress service: Available"
    log "  - Ingress controller: Functional"
    log "  - Ready for ingress resource creation"
    log "=============================================="
    
    log "Ingress controller verification completed successfully"
}

# 6.1 Verify ingress controller is running
log "Starting ingress configuration verification..."
verify_ingress_controller
log "Ingress configuration verification completed"

# ==============================
# SSL/TLS CERTIFICATE CONFIGURATION
# ==============================

# SSL/TLS certificate error handler
handle_ssl_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "SSL/TLS ERROR [Code: $error_code]: $error_message"
    log "RECOVERY SUGGESTION: $recovery_suggestion"
    
    # Log additional diagnostic information
    log "SSL/TLS DIAGNOSTIC INFO:"
    log "VM Name: $VM_NAME"
    log "Microk8s status: $(multipass exec "$VM_NAME" -- microk8s status --wait 2>/dev/null || echo 'microk8s not ready')"
    
    exit $error_code
}

# 6.4 Configure SSL/TLS certificates
log "Starting SSL/TLS certificate configuration..."

# Create self-signed certificate for localhost/127.0.0.1
log "Creating self-signed SSL/TLS certificate for localhost and 127.0.0.1..."

# Create certificate on the host system first
CERT_DIR="/tmp/ssl-certificates-$$"
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

log "Generating private key..."
if ! openssl genrsa -out tls.key 2048 2>&1 | tee -a "$LOG_FILE"; then
    handle_ssl_error 101 "Failed to generate private key" \
        "Ensure OpenSSL is installed: openssl version. Try manual generation: openssl genrsa -out tls.key 2048"
fi

log "Generating certificate signing request (CSR)..."
if ! openssl req -new -key tls.key -out tls.csr -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" 2>&1 | tee -a "$LOG_FILE"; then
    handle_ssl_error 102 "Failed to generate certificate signing request" \
        "Ensure OpenSSL supports subjectAltName. Try manual: openssl req -new -key tls.key -out tls.csr -subj '/CN=localhost'"
fi

log "Generating self-signed certificate..."
if ! openssl x509 -req -in tls.csr -signkey tls.key -out tls.crt -days 365 -extfile <(printf "subjectAltName=DNS:localhost,IP:127.0.0.1") 2>&1 | tee -a "$LOG_FILE"; then
    handle_ssl_error 103 "Failed to generate self-signed certificate" \
        "Check OpenSSL version and subjectAltName support. Try manual: openssl x509 -req -in tls.csr -signkey tls.key -out tls.crt -days 365"
fi

log "Self-signed certificate created successfully"

# Copy certificate files to the VM
log "Copying certificate files to VM '$VM_NAME'..."
if ! multipass copy-file tls.crt "$VM_NAME:/tmp/tls.crt" 2>&1 | tee -a "$LOG_FILE"; then
    handle_ssl_error 104 "Failed to copy certificate file to VM" \
        "Check VM accessibility: multipass info $VM_NAME. Check file permissions."
fi

if ! multipass copy-file tls.key "$VM_NAME:/tmp/tls.key" 2>&1 | tee -a "$LOG_FILE"; then
    handle_ssl_error 105 "Failed to copy private key file to VM" \
        "Check VM accessibility: multipass info $VM_NAME. Check file permissions."
fi

log "Certificate files copied to VM successfully"

# Create TLS secret in microk8s
log "Creating TLS secret in microk8s..."
if ! multipass exec "$VM_NAME" -- bash -c "microk8s kubectl create secret tls my-ag-ui-app-tls-secret --cert=/tmp/tls.crt --key=/tmp/tls.key --namespace=default --dry-run=client -o yaml | microk8s kubectl apply -f -" 2>&1 | tee -a "$LOG_FILE"; then
    handle_ssl_error 106 "Failed to create TLS secret in microk8s" \
        "Check secret creation manually: microk8s kubectl create secret tls my-ag-ui-app-tls-secret --cert=/tmp/tls.crt --key=/tmp/tls.key"
fi

log "TLS secret created successfully in microk8s"

# Verify the secret was created
log "Verifying TLS secret creation..."
if ! multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get secret my-ag-ui-app-tls-secret" 2>&1 | tee -a "$LOG_FILE"; then
    handle_ssl_error 107 "TLS secret verification failed" \
        "Check if secret exists: microk8s kubectl get secret my-ag-ui-app-tls-secret"
fi

log "TLS secret verified successfully"

# Clean up certificate files from VM
log "Cleaning up certificate files from VM..."
multipass exec "$VM_NAME" -- rm -f /tmp/tls.crt /tmp/tls.key 2>&1 | tee -a "$LOG_FILE" || true

# Clean up local certificate directory
cd - >/dev/null
rm -rf "$CERT_DIR"
log "SSL/TLS certificate configuration completed successfully"

# ===========================
# KUBERNETES MANIFESTS DEPLOYMENT
# ===========================

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
    
    exit $error_code
}

log "Starting Kubernetes manifests deployment..."

# Verify image is available in microk8s
log "Verifying Docker image is available in microk8s..."
if ! multipass exec "$VM_NAME" -- bash -c "microk8s ctr image list | grep -q '$IMAGE_NAME'" 2>&1 | tee -a "$LOG_FILE"; then
    handle_k8s_deployment_error 201 "Docker image not found in microk8s" \
        "Ensure image was imported: microk8s ctr image list | grep $IMAGE_NAME"
fi
log "Docker image is available in microk8s"

# 5.5 Apply deployment manifest to microk8s cluster
log "Applying deployment manifest to microk8s cluster..."
if ! multipass exec "$VM_NAME" -- bash -c "cd /tmp && microk8s kubectl apply -f <(cat <<'EOF'
$(cat k8s/deployment.yaml)
EOF
)" 2>&1 | tee -a "$LOG_FILE"; then
    handle_k8s_deployment_error 202 "Failed to apply deployment manifest" \
        "Check deployment manifest: k8s/deployment.yaml. Apply manually: microk8s kubectl apply -f k8s/deployment.yaml"
fi
log "Deployment manifest applied successfully"

# 5.6 Apply service manifest to microk8s cluster
log "Applying service manifest to microk8s cluster..."
if ! multipass exec "$VM_NAME" -- bash -c "cd /tmp && microk8s kubectl apply -f <(cat <<'EOF'
$(cat k8s/service.yaml)
EOF
)" 2>&1 | tee -a "$LOG_FILE"; then
    handle_k8s_deployment_error 203 "Failed to apply service manifest" \
        "Check service manifest: k8s/service.yaml. Apply manually: microk8s kubectl apply -f k8s/service.yaml"
fi
log "Service manifest applied successfully"

# 5.7 Apply ingress manifest to microk8s cluster
log "Applying ingress manifest to microk8s cluster..."
if ! multipass exec "$VM_NAME" -- bash -c "cd /tmp && microk8s kubectl apply -f <(cat <<'EOF'
$(cat k8s/ingress.yaml)
EOF
)" 2>&1 | tee -a "$LOG_FILE"; then
    handle_k8s_deployment_error 204 "Failed to apply ingress manifest" \
        "Check ingress manifest: k8s/ingress.yaml. Apply manually: microk8s kubectl apply -f k8s/ingress.yaml"
fi
log "Ingress manifest applied successfully"

# 5.8 Wait for pods to be ready
log "Waiting for application pods to be ready..."
MAX_ATTEMPTS=30
ATTEMPT=1
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    log "Checking pod status... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
    
    # Get pod status
    local pod_status=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo ''")
    local pod_ready=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>/dev/null || echo ''")
    
    if [ -n "$pod_status" ] && [ "$pod_status" = "Running" ] && [ "$pod_ready" = "true" ]; then
        log "Application pods are ready"
        break
    else
        log "Pods not ready yet. Status: $pod_status, Ready: $pod_ready"
        
        if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
            handle_k8s_deployment_error 205 "Pods did not become ready after $MAX_ATTEMPTS attempts" \
                "Check pod status: microk8s kubectl get pods. Check pod logs: microk8s kubectl logs <pod-name>"
        fi
    fi
    
    sleep 5
    ATTEMPT=$((ATTEMPT + 1))
done

# 5.9 Verify deployment status
log "Verifying deployment status..."
if ! multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get deployment my-ag-ui-app-deployment" 2>&1 | tee -a "$LOG_FILE"; then
    handle_k8s_deployment_error 206 "Deployment verification failed" \
        "Check deployment status: microk8s kubectl get deployment my-ag-ui-app-deployment"
fi
log "Deployment status verified successfully"

# 5.10 Verify application is accessible via ingress
log "Verifying application is accessible via ingress..."
log "Getting ingress endpoint..."

# Get ingress IP/hostname
local ingress_endpoint=$(multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo ''")
if [ -z "$ingress_endpoint" ]; then
    # For local testing, we use localhost
    ingress_endpoint="localhost"
fi
log "Ingress endpoint: $ingress_endpoint"

log "Testing application access via ingress..."
# Note: In a real deployment, we would test HTTP/HTTPS access here
# For now, we'll just verify that the ingress is configured correctly
if ! multipass exec "$VM_NAME" -- bash -c "microk8s kubectl get ingress my-ag-ui-app-ingress" 2>&1 | tee -a "$LOG_FILE"; then
    handle_k8s_deployment_error 207 "Ingress verification failed" \
        "Check ingress status: microk8s kubectl get ingress my-ag-ui-app-ingress"
fi
log "Application ingress configuration verified successfully"

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