
# ===========================
# LOGGING FUNCTIONS
# ===========================

# Log file location
LOG_FILE="/tmp/deploy-$(date +%Y%m%d-%H%M%S).log"

# VM configuration
VM_NAME="my-ag-ui-app-k8s"

# ===========================
# COMMAND LINE ARGUMENT PARSING
# ===========================

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-deps-check)
            SKIP_DEPS_CHECK=true
            log "⚠️  WARNING: Skipping dependency validation check"
            log "   This may result in build failures if lock files are out of sync"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-deps-check    Skip dependency validation (emergency use only)"
            echo "  --help, -h           Show this help message"
            echo ""
            echo "This script deploys the my-ag-ui-app to Kubernetes using Docker and multipass."
            echo "It validates that package.json and package-lock.json are synchronized"
            echo "before building Docker images to ensure reproducible builds."
            exit 0
            ;;
        *)
            log "ERROR: Unknown option: $1"
            log "Use --help to see available options"
            exit 1
            ;;
    esac
done

# Logging function - prints to both stdout and log file
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message"
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# ===========================
# VM DOCKER SETUP FUNCTION
# ===========================

# Setup Docker in the multipass VM
setup_vm_docker() {
    log "Starting Docker setup in VM '$VM_NAME'..."
    
    # Check Docker CLI availability in VM with comprehensive error handling
    log "Checking Docker CLI availability in VM..."
    DOCKER_CLI_AVAILABLE=false
    DOCKER_CLI_ERROR=""
    DOCKER_CLI_ERROR_DETAILS=""
    
    # Try to get Docker version with detailed error capture
    local docker_version_output
    docker_version_output=$(multipass exec "$VM_NAME" -- docker --version 2>&1)
    local docker_version_exit_code=$?
    
    if [ $docker_version_exit_code -eq 0 ]; then
        DOCKER_VERSION=$(echo "$docker_version_output" | head -n1)
        log "✅ Docker CLI is available in VM: $DOCKER_VERSION"
        DOCKER_CLI_AVAILABLE=true
    else
        log "⚠️  Docker CLI is not available in VM (exit code: $docker_version_exit_code)"
        DOCKER_CLI_ERROR=true
        DOCKER_CLI_ERROR_DETAILS="$docker_version_output"
        
        # Analyze the specific error to provide targeted guidance
        log "DIAGNOSTIC: Analyzing Docker CLI check failure..."
        log "Error details: $DOCKER_CLI_ERROR_DETAILS"
        
        # Check for common error patterns and provide specific guidance
        if echo "$DOCKER_CLI_ERROR_DETAILS" | grep -q "multipass: command not found"; then
            log "ERROR: multipass command is not available on the host system"
            log "RECOVERY: Install multipass first: https://multipass.run/"
            log "         Ubuntu: sudo snap install multipass"
            log "         macOS: brew install multipass"
            log "         Windows: Download from https://multipass.run/"
        elif echo "$DOCKER_CLI_ERROR_DETAILS" | grep -q "instance does not exist"; then
            log "ERROR: VM '$VM_NAME' does not exist"
            log "RECOVERY: Create the VM first: multipass launch --name $VM_NAME"
            log "         Or check VM name spelling: multipass list"
        elif echo "$DOCKER_CLI_ERROR_DETAILS" | grep -q "instance is not running"; then
            log "ERROR: VM '$VM_NAME' is not running"
            log "RECOVERY: Start the VM first: multipass start $VM_NAME"
            log "         Or check VM status: multipass info $VM_NAME"
        elif echo "$DOCKER_CLI_ERROR_DETAILS" | grep -q "permission denied"; then
            log "ERROR: Permission denied accessing VM '$VM_NAME'"
            log "RECOVERY: Check multipass permissions: ls -la ~/.multipass"
            log "         Try running with proper user permissions"
            log "         Or check VM instance permissions: multipass info $VM_NAME"
        elif echo "$DOCKER_CLI_ERROR_DETAILS" | grep -q "network is unreachable"; then
            log "ERROR: Network connectivity issue with VM '$VM_NAME'"
            log "RECOVERY: Check VM network configuration: multipass exec $VM_NAME -- ip a"
            log "         Check host network connectivity"
            log "         Restart VM if needed: multipass restart $VM_NAME"
        elif echo "$DOCKER_CLI_ERROR_DETAILS" | grep -q "connection refused"; then
            log "ERROR: Connection refused to VM '$VM_NAME'"
            log "RECOVERY: VM may be starting up or shutting down"
            log "         Wait a few moments and try again"
            log "         Check VM status: multipass info $VM_NAME"
            log "         Restart VM if needed: multipass restart $VM_NAME"
        elif echo "$DOCKER_CLI_ERROR_DETAILS" | grep -q "docker: command not found"; then
            log "DIAGNOSTIC: Docker CLI is not installed in VM (expected for fresh VMs)"
            log "INFO: This is normal for freshly provisioned VMs - will proceed with Docker installation"
            DOCKER_CLI_ERROR=false  # This is expected, not an error
        elif echo "$DOCKER_CLI_ERROR_DETAILS" | grep -q "No such file or directory"; then
            log "ERROR: File or directory not found in VM or on host"
            log "RECOVERY: Check multipass installation: multipass version"
            log "         Verify VM filesystem: multipass exec $VM_NAME -- ls -la /"
        elif echo "$DOCKER_CLI_ERROR_DETAILS" | grep -q "timeout"; then
            log "ERROR: Timeout communicating with VM '$VM_NAME'"
            log "RECOVERY: VM may be overloaded or unresponsive"
            log "         Wait and try again, or restart VM: multipass restart $VM_NAME"
            log "         Check VM resources: multipass exec $VM_NAME -- top"
        elif [ $docker_version_exit_code -eq 126 ]; then
            log "ERROR: Command cannot be executed (permission or shell issue)"
            log "RECOVERY: Check multipass shell configuration"
            log "         Try direct VM access: multipass shell $VM_NAME"
        elif [ $docker_version_exit_code -eq 127 ]; then
            log "ERROR: Command not found (docker or multipass command missing)"
            if echo "$DOCKER_CLI_ERROR_DETAILS" | grep -q "docker"; then
                log "RECOVERY: Docker CLI not installed in VM (will proceed with installation)"
                DOCKER_CLI_ERROR=false  # This is expected, not an error
            else
                log "RECOVERY: Install multipass: https://multipass.run/"
            fi
        elif [ $docker_version_exit_code -eq 130 ]; then
            log "ERROR: Command interrupted (Ctrl+C or similar)"
            log "RECOVERY: Check if process was interrupted manually"
            log "         Try running the command again"
        else
            log "ERROR: Unknown error checking Docker CLI availability (exit code: $docker_version_exit_code)"
            log "DIAGNOSTIC: Full error output:"
            log "$DOCKER_CLI_ERROR_DETAILS"
            log "RECOVERY: Try manual VM access: multipass shell $VM_NAME"
            log "         Then check: docker --version"
            log "         If issue persists, check multipass logs and system resources"
        fi
        
        # Additional diagnostic information for debugging
        log "ENHANCED DIAGNOSTICS:"
        log "- VM status: $(multipass info "$VM_NAME" 2>/dev/null || echo 'Unable to get VM status')"
        log "- Multipass version: $(multipass version 2>/dev/null || echo 'Unable to get multipass version')"
        log "- Host Docker availability: $(docker --version 2>/dev/null || echo 'Docker not available on host')"
        log "- Current user: $USER"
        log "- User groups: $(groups 2>/dev/null || echo 'Unable to get groups')"
        
        # Check VM accessibility with a simpler command
        log "Testing basic VM accessibility..."
        if multipass exec "$VM_NAME" -- whoami >/dev/null 2>&1; then
            VM_USER=$(multipass exec "$VM_NAME" -- whoami 2>/dev/null)
            log "✅ VM is accessible - user: $VM_USER"
        else
            log "❌ VM is not accessible - this indicates a multipass/VM communication issue"
            log "RECOVERY: Check multipass daemon status and VM instance"
        fi
        
        # Only set error flag if this is an unexpected error (not just missing docker)
        if [ "$DOCKER_CLI_ERROR" = true ]; then
            log "ERROR: Critical failure during Docker CLI availability check"
            log "RECOVERY: Manual intervention may be required. Connect to VM: multipass shell $VM_NAME"
            return 1
        else
            log "INFO: Docker CLI not found in VM (expected for fresh VMs) - proceeding with installation"
        fi
    fi
    
    # Install Docker if not available
    if [ "$DOCKER_CLI_AVAILABLE" = false ]; then
        log "Installing Docker using official script..."
        
        # Pre-installation checks for common failure scenarios
        log "Performing pre-installation system checks..."
        
        # Check disk space in VM
        log "Checking available disk space in VM..."
        local vm_disk_info
        vm_disk_info=$(multipass exec "$VM_NAME" -- df -h / 2>/dev/null | tail -n1 || echo "")
        if [ -n "$vm_disk_info" ]; then
            local available_space
            available_space=$(echo "$vm_disk_info" | awk '{print $4}' | sed 's/G//' | sed 's/M//' | head -n1)
            local unit
            unit=$(echo "$vm_disk_info" | awk '{print $4}' | sed 's/[0-9.]//' | head -n1)
            log "Available disk space: ${available_space}${unit}"
            
            # Convert to MB for comparison
            local space_mb
            if [ "$unit" = "G" ] || [ -z "$unit" ]; then
                space_mb=$(echo "$available_space * 1024" | bc -l 2>/dev/null || echo "${available_space}000")
            else
                space_mb=$available_space
            fi
            
            if [ "${space_mb%.*}" -lt 1024 ]; then
                log "⚠️  WARNING: Low disk space detected (${space_mb%.*}MB available)"
                log "   Docker installation typically requires at least 1GB free space"
            fi
        else
            log "WARNING: Could not check disk space in VM"
        fi
        
        # Check network connectivity to Docker's installation script
        log "Checking network connectivity to Docker's installation script..."
        local network_test_result
        network_test_result=$(multipass exec "$VM_NAME" -- curl -I --connect-timeout 10 https://get.docker.com 2>&1 | head -n1 || echo "")
        if echo "$network_test_result" | grep -q "200 OK"; then
            log "✅ Network connectivity to Docker installation script verified"
        else
            log "⚠️  WARNING: Network connectivity issue detected"
            log "   Network test result: $network_test_result"
            log "   This may cause installation to fail"
        fi
        
        # Check if package manager is working
        log "Checking package manager accessibility..."
        local apt_test_result
        apt_test_result=$(multipass exec "$VM_NAME" -- sudo apt-get update --dry-run 2>&1 | head -n5 || echo "")
        if echo "$apt_test_result" | grep -q -E "(Get|Hit|Ign)"; then
            log "✅ Package manager (apt) is accessible"
        else
            log "⚠️  WARNING: Package manager accessibility issue detected"
            log "   Package manager test result: $apt_test_result"
            log "   This may cause Docker installation to fail"
        fi
        
        # Install Docker with comprehensive error capture
        log "Starting Docker installation with comprehensive error capture..."
        local install_output
        local install_exit_code
        
        # Capture both stdout and stderr for detailed analysis
        install_output=$(multipass exec "$VM_NAME" -- bash -c "curl -fsSL https://get.docker.com | sh" 2>&1)
        install_exit_code=$?
        
        # Log the full installation output for debugging
        log "Docker installation output (first 1000 chars):"
        echo "$install_output" | head -c 1000 | tee -a "$LOG_FILE"
        if [ ${#install_output} -gt 1000 ]; then
            log "... (output truncated, full output logged to file)"
            echo "$install_output" >> "$LOG_FILE"
        fi
        
        # Analyze the installation result
        if [ $install_exit_code -eq 0 ]; then
            log "✅ Docker installation command completed successfully (exit code: 0)"
        else
            log "ERROR: Docker installation failed (exit code: $install_exit_code)"
            
            # Analyze specific error patterns and provide targeted guidance
            log "ANALYZING INSTALLATION FAILURE..."
            
            # Check for network connectivity errors
            if echo "$install_output" | grep -q -E "(curl.*failed|Connection refused|Network unreachable|Timeout|resolve host|Could not resolve host)"; then
                log "ERROR TYPE: NETWORK CONNECTIVITY FAILURE"
                log "DIAGNOSTIC: Installation script cannot reach Docker servers"
                log "RECOVERY STEPS:"
                log "1. Check VM network connectivity: multipass exec $VM_NAME -- ping -c 2 google.com"
                log "2. Check DNS resolution: multipass exec $VM_NAME -- nslookup get.docker.com"
                log "3. Check network interface: multipass exec $VM_NAME -- ip a"
                log "4. If proxy required, set proxy environment variables in VM:"
                log "   multipass exec $VM_NAME -- bash -c 'echo \"export HTTP_PROXY=http://proxy:port\" >> ~/.bashrc'"
                log "5. Manual recovery: multipass shell $VM_NAME"
                log "   Then run: curl -fsSL https://get.docker.com | sh"
                
            # Check for disk space errors
            elif echo "$install_output" | grep -q -E "(No space left|disk full|out of space|insufficient space|not enough free space)"; then
                log "ERROR TYPE: INSUFFICIENT DISK SPACE"
                log "DIAGNOSTIC: VM does not have enough disk space for Docker installation"
                log "RECOVERY STEPS:"
                log "1. Check disk usage: multipass exec $VM_NAME -- df -h"
                log "2. Clean up unused packages: multipass exec $VM_NAME -- sudo apt autoremove -y"
                log "3. Clear apt cache: multipass exec $VM_NAME -- sudo apt clean"
                log "4. Remove old logs: multipass exec $VM_NAME -- sudo journalctl --vacuum-size=100M"
                log "5. If still insufficient, increase VM disk size:"
                log "   multipass stop $VM_NAME && multipass delete $VM_NAME && multipass launch --name $VM_NAME --disk 20G"
                log "6. Manual recovery after freeing space: multipass shell $VM_NAME"
                log "   Then run: curl -fsSL https://get.docker.com | sh"
                
            # Check for package manager errors
            elif echo "$install_output" | grep -q -E "(Unable to locate package|package.*not found|E:.*Failed to fetch|dpkg.*error|apt.*error)"; then
                log "ERROR TYPE: PACKAGE MANAGER FAILURE"
                log "DIAGNOSTIC: APT package manager encountered errors"
                log "RECOVERY STEPS:"
                log "1. Update package lists: multipass exec $VM_NAME -- sudo apt update"
                log "2. Fix broken dependencies: multipass exec $VM_NAME -- sudo apt --fix-broken install -y"
                log "3. Clean package cache: multipass exec $VM_NAME -- sudo apt clean"
                log "4. Check package sources: multipass exec $VM_NAME -- cat /etc/apt/sources.list"
                log "5. Manual recovery: multipass shell $VM_NAME"
                log "   Then run: sudo apt update && curl -fsSL https://get.docker.com | sh"
                
            # Check for permission errors
            elif echo "$install_output" | grep -q -E "(Permission denied|sudo.*error|access denied|Operation not permitted)"; then
                log "ERROR TYPE: PERMISSION FAILURE"
                log "DIAGNOSTIC: Installation encountered permission errors"
                log "RECOVERY STEPS:"
                log "1. Check user permissions: multipass exec $VM_NAME -- id"
                log "2. Check sudo access: multipass exec $VM_NAME -- sudo -l"
                log "3. Ensure user has sudo privileges in VM"
                log "4. Manual recovery: multipass shell $VM_NAME"
                log "   Then run: sudo curl -fsSL https://get.docker.com | sudo sh"
                
            # Check for timeout errors
            elif echo "$install_output" | grep -q -E "(timeout|timed out|TIME_WAIT|connection timed out)"; then
                log "ERROR TYPE: TIMEOUT FAILURE"
                log "DIAGNOSTIC: Installation operation timed out"
                log "RECOVERY STEPS:"
                log "1. Check network connectivity: multipass exec $VM_NAME -- ping -c 4 google.com"
                log "2. Check network speed: multipass exec $VM_NAME -- curl -o /dev/null -s -w '%{time_total}' https://get.docker.com"
                log "3. Retry installation (network may be temporarily slow)"
                log "4. Manual recovery: multipass shell $VM_NAME"
                log "   Then run: curl -fsSL https://get.docker.com | sh"
                
            # Check for SSL/TLS certificate errors
            elif echo "$install_output" | grep -q -E "(SSL|certificate|TLS|verify|CAbundle|unable to get local issuer certificate)"; then
                log "ERROR TYPE: SSL/TLS CERTIFICATE FAILURE"
                log "DIAGNOSTIC: SSL certificate verification failed"
                log "RECOVERY STEPS:"
                log "1. Update CA certificates: multipass exec $VM_NAME -- sudo update-ca-certificates"
                log "2. Check system time: multipass exec $VM_NAME -- date"
                log "3. Install ca-certificates: multipass exec $VM_NAME -- sudo apt install ca-certificates -y"
                log "4. Temporary bypass (not recommended for production):"
                log "   multipass shell $VM_NAME"
                log "   Then run: curl -k -fsSL https://get.docker.com | sh"
                
            # Check for system architecture compatibility issues
            elif echo "$install_output" | grep -q -E "(architecture|Architecture.*not supported|not.*supported.*architecture|dpkg.*wrong architecture)"; then
                log "ERROR TYPE: SYSTEM ARCHITECTURE COMPATIBILITY"
                log "DIAGNOSTIC: Docker installation not supported for this system architecture"
                log "RECOVERY STEPS:"
                log "1. Check system architecture: multipass exec $VM_NAME -- uname -m"
                log "2. Check Ubuntu version: multipass exec $VM_NAME -- lsb_release -a"
                log "3. Verify multipass VM architecture is supported by Docker"
                log "4. Consider using Docker's official installation method for your architecture"
                log "   Manual recovery: multipass shell $VM_NAME"
                log "   Visit: https://docs.docker.com/engine/install/ubuntu/"
                
            # Check for system dependency issues
            elif echo "$install_output" | grep -q -E "(dependency|dependencies|depends on|unmet dependencies)"; then
                log "ERROR TYPE: SYSTEM DEPENDENCY FAILURE"
                log "DIAGNOSTIC: Required system dependencies are missing or conflicting"
                log "RECOVERY STEPS:"
                log "1. Update system: multipass exec $VM_NAME -- sudo apt update && sudo apt upgrade -y"
                log "2. Fix broken dependencies: multipass exec $VM_NAME -- sudo apt --fix-broken install -y"
                log "3. Install common dependencies: multipass exec $VM_NAME -- sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release"
                log "4. Manual recovery: multipass shell $VM_NAME"
                log "   Then run: sudo apt update && curl -fsSL https://get.docker.com | sh"
                
            # Check for resource constraint issues (beyond disk space)
            elif echo "$install_output" | grep -q -E "(memory|swap|OOM|out of memory|insufficient memory|resource temporarily unavailable|cannot allocate memory)"; then
                log "ERROR TYPE: RESOURCE CONSTRAINT FAILURE"
                log "DIAGNOSTIC: VM lacks sufficient memory or system resources for Docker installation"
                log "RECOVERY STEPS:"
                log "1. Check memory usage: multipass exec $VM_NAME -- free -h"
                log "2. Check available swap: multipass exec $VM_NAME -- swapon --show"
                log "3. Free up memory: multipass exec $VM_NAME -- sudo systemctl stop non-essential-services"
                log "4. Create swap file if needed: multipass exec $VM_NAME -- sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile"
                log "5. Increase VM memory: multipass stop $VM_NAME && multipass delete $VM_NAME && multipass launch --name $VM_NAME --memory 4G"
                log "6. Manual recovery: multipass shell $VM_NAME"
                log "   Then run: sudo swapoff -a && sudo systemctl daemon-reload && curl -fsSL https://get.docker.com | sh"
                
            # Check for firewall/security restriction issues
            elif echo "$install_output" | grep -q -E "(firewall|blocked|security|restrict|policy|ufw|iptables|apparmor|selinux)"; then
                log "ERROR TYPE: FIREWALL/SECURITY RESTRICTION FAILURE"
                log "DIAGNOSTIC: Security policies or firewall rules are blocking Docker installation"
                log "RECOVERY STEPS:"
                log "1. Check firewall status: multipass exec $VM_NAME -- sudo ufw status"
                log "2. Check AppArmor status: multipass exec $VM_NAME -- aa-status"
                log "3. Check SELinux status: multipass exec $VM_NAME -- getenforce"
                log "4. Temporarily disable firewall for installation: multipass exec $VM_NAME -- sudo ufw disable"
                log "5. Allow Docker through firewall: multipass exec $VM_NAME -- sudo ufw allow 2375/tcp && sudo ufw allow 2376/tcp"
                log "6. Manual recovery: multipass shell $VM_NAME"
                log "   Then run: sudo ufw disable && curl -fsSL https://get.docker.com | sh"
                
            # Check for proxy-related issues beyond basic network connectivity
            elif echo "$install_output" | grep -q -E "(proxy|Proxy|PROXY|http_proxy|https_proxy)"; then
                log "ERROR TYPE: PROXY CONFIGURATION FAILURE"
                log "DIAGNOSTIC: Proxy configuration issues are preventing Docker installation"
                log "RECOVERY STEPS:"
                log "1. Check current proxy settings: multipass exec $VM_NAME -- env | grep -i proxy"
                log "2. Check system-wide proxy: multipass exec $VM_NAME -- cat /etc/environment"
                log "3. Check apt proxy: multipass exec $VM_NAME -- cat /etc/apt/apt.conf.d/*proxy*"
                log "4. Configure proxy for Docker: multipass exec $VM_NAME -- sudo mkdir -p /etc/systemd/system/docker.service.d"
                log "5. Create proxy configuration: multipass exec $VM_NAME -- 'echo [Service] | sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf'"
                log "6. Manual recovery: multipass shell $VM_NAME"
                log "   Then run: export HTTP_PROXY=http://proxy:port && export HTTPS_PROXY=http://proxy:port && curl -fsSL https://get.docker.com | sh"
                
            # Check for container runtime conflicts
            elif echo "$install_output" | grep -q -E "(containerd|runtime|podman|lxc|docker.*already|conflict)"; then
                log "ERROR TYPE: CONTAINER RUNTIME CONFLICT FAILURE"
                log "DIAGNOSTIC: Existing container runtime is conflicting with Docker installation"
                log "RECOVERY STEPS:"
                log "1. Check installed container runtimes: multipass exec $VM_NAME -- dpkg -l | grep -E '(docker|containerd|podman|lxc)'"
                log "2. Check running container processes: multipass exec $VM_NAME -- ps aux | grep -E '(docker|containerd|podman|lxc)'"
                log "3. Stop existing container service: multipass exec $VM_NAME -- sudo systemctl stop containerd || sudo systemctl stop docker"
                log "4. Remove conflicting packages: multipass exec $VM_NAME -- sudo apt remove -y docker.io containerd runc"
                log "5. Clean up: multipass exec $VM_NAME -- sudo apt autoremove -y && sudo apt clean"
                log "6. Manual recovery: multipass shell $VM_NAME"
                log "   Then run: sudo apt remove --purge docker* containerd* && sudo apt autoremove && curl -fsSL https://get.docker.com | sh"
                
            # Check for kernel compatibility issues
            elif echo "$install_output" | grep -q -E "(kernel|modules| aufs| overlay| devicemapper| incompatible)"; then
                log "ERROR TYPE: KERNEL COMPATIBILITY FAILURE"
                log "DIAGNOSTIC: System kernel is not compatible with Docker requirements"
                log "RECOVERY STEPS:"
                log "1. Check kernel version: multipass exec $VM_NAME -- uname -r"
                log "2. Check loaded kernel modules: multipass exec $VM_NAME -- lsmod | grep -E '(aufs|overlay|devicemapper)'"
                log "3. Check kernel requirements: multipass exec $VM_NAME -- curl -s https://docs.docker.com/engine/install/ubuntu/"
                log "4. Update kernel: multipass exec $VM_NAME -- sudo apt update && sudo apt install -y linux-generic"
                log "5. Reboot VM if kernel was updated: multipass exec $VM_NAME -- sudo reboot"
                log "6. Manual recovery: multipass shell $VM_NAME"
                log "   Then run: sudo modprobe overlay && sudo modprobe aufs && curl -fsSL https://get.docker.com | sh"
                
            # Check for storage driver compatibility issues
            elif echo "$install_output" | grep -q -E "(storage|filesystem|filesystem type|ext4| xfs| btrfs| driver)"; then
                log "ERROR TYPE: STORAGE DRIVER COMPATIBILITY FAILURE"
                log "DIAGNOSTIC: Filesystem or storage driver compatibility issues"
                log "RECOVERY STEPS:"
                log "1. Check filesystem type: multipass exec $VM_NAME -- df -T /"
                log "2. Check available storage drivers: multipass exec $VM_NAME -- ls -la /lib/modules/$(uname -r)/kernel/drivers/misc/ | grep storage"
                log "3. Format filesystem if needed (WARNING: destructive operation):"
                log "   multipass exec $VM_NAME -- sudo mkfs.ext4 /dev/sda2 (adjust device as needed)"
                log "4. Configure Docker storage driver: multipass exec $VM_NAME -- sudo mkdir -p /etc/docker"
                log "5. Manual recovery: multipass shell $VM_NAME"
                log "   Then run: sudo apt install -y lxcfs && curl -fsSL https://get.docker.com | sh"
                
            # Unknown/unexpected errors
            else
                log "ERROR TYPE: UNKNOWN INSTALLATION FAILURE"
                log "DIAGNOSTIC: Installation failed with unexpected error pattern"
                log "ERROR DETAILS:"
                log "Exit code: $install_exit_code"
                log "Last 10 lines of output:"
                echo "$install_output" | tail -n10 | tee -a "$LOG_FILE"
                
                log "RECOVERY STEPS:"
                log "1. Check VM system status: multipass info $VM_NAME"
                log "2. Check system logs: multipass exec $VM_NAME -- dmesg | tail -n20"
                log "3. Manual recovery: multipass shell $VM_NAME"
                log "4. Try alternative Docker installation method:"
                log "   multipass exec $VM_NAME -- bash -c 'sudo apt update && sudo apt install -y docker.io'"
                log "5. If all else fails, consider recreating the VM:"
                log "   multipass delete $VM_NAME && multipass launch --name $VM_NAME"
            fi
            
            # Collect additional diagnostic information
            log "COLLECTING ADDITIONAL DIAGNOSTIC INFORMATION..."
            log "VM system information:"
            multipass exec "$VM_NAME" -- uname -a 2>/dev/null | tee -a "$LOG_FILE" || log "Unable to get system info"
            
            log "VM disk usage:"
            multipass exec "$VM_NAME" -- df -h 2>/dev/null | tee -a "$LOG_FILE" || log "Unable to get disk usage"
            
            log "VM memory usage:"
            multipass exec "$VM_NAME" -- free -h 2>/dev/null | tee -a "$LOG_FILE" || log "Unable to get memory usage"
            
            log "VM network interfaces:"
            multipass exec "$VM_NAME" -- ip a 2>/dev/null | tee -a "$LOG_FILE" || log "Unable to get network info"
            
            log "VM package manager status:"
            multipass exec "$VM_NAME" -- sudo apt list --upgradable 2>/dev/null | head -n5 | tee -a "$LOG_FILE" || log "Unable to get package status"
            
            return 1
        fi
        
        # Verify Docker was installed
        log "Verifying Docker installation..."
        local docker_version_output
        docker_version_output=$(multipass exec "$VM_NAME" -- docker --version 2>&1)
        local docker_version_exit_code=$?
        
        if [ $docker_version_exit_code -eq 0 ]; then
            DOCKER_VERSION=$(echo "$docker_version_output" | head -n1)
            log "✅ Docker installed successfully: $DOCKER_VERSION"
            DOCKER_CLI_AVAILABLE=true
            
            # Additional verification checks
            log "Performing additional Docker installation verification..."
            
            # Check Docker daemon status
            log "Checking Docker daemon status..."
            local docker_daemon_status
            docker_daemon_status=$(multipass exec "$VM_NAME" -- sudo systemctl is-active docker 2>/dev/null || echo "unknown")
            log "Docker daemon status: $docker_daemon_status"
            
            # Check if docker group exists
            log "Checking docker group existence..."
            local docker_group
            docker_group=$(multipass exec "$VM_NAME" -- grep -c '^docker:' /etc/group 2>/dev/null || echo "0")
            if [ "$docker_group" -gt 0 ]; then
                log "✅ Docker group exists in /etc/group"
            else
                log "⚠️  WARNING: Docker group not found in /etc/group"
                log "   This may indicate incomplete installation"
            fi
            
            # Check Docker service files
            log "Checking Docker service installation..."
            if multipass exec "$VM_NAME" -- systemctl list-unit-files | grep -q docker; then
                log "✅ Docker systemd service is installed"
            else
                log "⚠️  WARNING: Docker systemd service not found"
                log "   This may indicate incomplete installation"
            fi
            
        else
            log "ERROR: Docker installation verification failed (exit code: $docker_version_exit_code)"
            log "DIAGNOSTIC: docker --version command failed after installation"
            log "Command output: $docker_version_output"
            log "RECOVERY: Manual intervention may be required. Connect to VM with: multipass shell $VM_NAME"
            log "         Then check: docker --version"
            log "         If missing, complete installation manually: sudo systemctl start docker && sudo systemctl enable docker"
            return 1
        fi
    else
        log "Docker already installed, skipping installation"
    fi
    
    # Add user to docker group
    log "Adding user to docker group..."
    if ! multipass exec "$VM_NAME" -- sudo usermod -aG docker ubuntu 2>&1 | tee -a "$LOG_FILE"; then
        log "ERROR: Failed to add user to docker group"
        log "RECOVERY: Manual group addition may be required. Connect to VM with: multipass shell $VM_NAME"
        log "         Then run: sudo usermod -aG docker ubuntu"
        return 1
    fi
    log "✅ User added to docker group successfully"
    
    # Create new shell session to activate docker group membership
    log "Activating docker group membership..."
    if ! multipass exec "$VM_NAME" -- newgrp docker 2>&1 | tee -a "$LOG_FILE"; then
        log "⚠️  Warning: Could not activate docker group membership with newgrp, continuing..."
        log "   This may cause issues with docker commands requiring group membership"
    fi
    log "✅ Docker group membership activated"
    
    # Start Docker daemon if it's not running
    log "Ensuring Docker daemon is running..."
    if ! multipass exec "$VM_NAME" -- sudo systemctl start docker 2>&1 | tee -a "$LOG_FILE"; then
        log "⚠️  Warning: Could not start Docker daemon with systemctl"
        log "   This may be expected if Docker daemon is already running or uses different init system"
    fi
    
    # Enable Docker daemon to start on boot
    log "Enabling Docker daemon to start on boot..."
    if ! multipass exec "$VM_NAME" -- sudo systemctl enable docker 2>&1 | tee -a "$LOG_FILE"; then
        log "⚠️  Warning: Could not enable Docker daemon to start on boot"
        log "   This may be expected if Docker daemon uses different init system"
    fi
    
    # Check Docker daemon status with retry loop and exponential backoff
    log "Checking Docker daemon status in VM with retry loop..."
    DOCKER_DAEMON_RUNNING=false
    MAX_DAEMON_CHECK_ATTEMPTS=10
    DAEMON_CHECK_ATTEMPT=1
    INITIAL_RETRY_DELAY=2
    MAX_RETRY_DELAY=30
    RETRY_DELAY=$INITIAL_RETRY_DELAY
    DOCKER_DAEMON_ERROR=""
    
    while [ $DAEMON_CHECK_ATTEMPT -le $MAX_DAEMON_CHECK_ATTEMPTS ]; do
        log "Docker daemon status check attempt $DAEMON_CHECK_ATTEMPT/$MAX_DAEMON_CHECK_ATTEMPTS (delay: ${RETRY_DELAY}s)..."
        
        # Capture detailed error output for analysis
        DOCKER_INFO_OUTPUT=$(multipass exec "$VM_NAME" -- docker info 2>&1)
        DOCKER_INFO_EXIT_CODE=$?
        
        if [ $DOCKER_INFO_EXIT_CODE -eq 0 ]; then
            log "✅ Docker daemon is running and accessible in VM (attempt $DAEMON_CHECK_ATTEMPT)"
            DOCKER_DAEMON_RUNNING=true
            break
        else
            log "⚠️  Docker daemon is not running or not accessible in VM (attempt $DAEMON_CHECK_ATTEMPT)"
            
            # Store the error output for analysis
            DOCKER_DAEMON_ERROR="$DOCKER_INFO_OUTPUT"
            
            # If this is the last attempt, provide comprehensive error analysis
            if [ $DAEMON_CHECK_ATTEMPT -eq $MAX_DAEMON_CHECK_ATTEMPTS ]; then
                log "ERROR: Docker daemon did not start after $MAX_DAEMON_CHECK_ATTEMPTS attempts"
                log "ERROR TYPE ANALYSIS: Docker daemon startup failure"
                
                # Analyze specific error patterns and provide targeted guidance
                log "ANALYZING DOCKER DAEMON STARTUP FAILURE..."
                
                # Check for permission errors
                if echo "$DOCKER_DAEMON_ERROR" | grep -q -E "(permission denied|Permission denied|Cannot connect to Docker daemon|access denied)"; then
                    log "ERROR TYPE: DOCKER DAEMON PERMISSION FAILURE"
                    log "DIAGNOSTIC: Docker daemon socket permission or access issue detected"
                    log "RECOVERY STEPS:"
                    log "1. Check Docker daemon socket permissions: multipass exec '$VM_NAME' -- ls -la /var/run/docker.sock"
                    log "2. Verify user is in docker group: multipass exec '$VM_NAME' -- groups ubuntu"
                    log "3. Check user permissions: multipass exec '$VM_NAME' -- id ubuntu"
                    log "4. Fix docker group membership: multipass exec '$VM_NAME' -- sudo usermod -aG docker ubuntu"
                    log "5. Activate group membership: multipass exec '$VM_NAME' -- newgrp docker"
                    log "6. Manual daemon restart: multipass exec '$VM_NAME' -- sudo systemctl restart docker"
                    
                # Check for daemon not running errors
                elif echo "$DOCKER_DAEMON_ERROR" | grep -q -E "(daemon is not running|Docker daemon is not running|Is the docker daemon running)"; then
                    log "ERROR TYPE: DOCKER DAEMON NOT RUNNING"
                    log "DIAGNOSTIC: Docker daemon process is not started or failed to start"
                    log "RECOVERY STEPS:"
                    log "1. Start Docker daemon: multipass exec '$VM_NAME' -- sudo systemctl start docker"
                    log "2. Enable Docker daemon at boot: multipass exec '$VM_NAME' -- sudo systemctl enable docker"
                    log "3. Check daemon status: multipass exec '$VM_NAME' -- sudo systemctl status docker"
                    log "4. Check daemon logs: multipass exec '$VM_NAME' -- sudo journalctl -u docker.service --no-pager"
                    
                # Check for connection/refused errors
                elif echo "$DOCKER_DAEMON_ERROR" | grep -q -E "(connection refused|Connection refused|connect: connection refused)"; then
                    log "ERROR TYPE: DOCKER DAEMON CONNECTION REFUSED"
                    log "DIAGNOSTIC: Docker daemon is not listening or rejecting connections"
                    log "RECOVERY STEPS:"
                    log "1. Check if daemon process exists: multipass exec '$VM_NAME' -- ps aux | grep docker | grep -v grep"
                    log "2. Check Docker daemon socket: multipass exec '$VM_NAME' -- ls -la /var/run/docker.sock"
                    log "3. Check Docker daemon configuration: multipass exec '$VM_NAME' -- cat /etc/docker/daemon.json"
                    log "4. Restart Docker daemon: multipass exec '$VM_NAME' -- sudo systemctl restart docker"
                    log "5. Check network connectivity: multipass exec '$VM_NAME' -- netstat -tlnp | grep docker"
                    
                # Check for timeout errors
                elif echo "$DOCKER_DAEMON_ERROR" | grep -q -E "(timeout|timed out|context deadline exceeded)"; then
                    log "ERROR TYPE: DOCKER DAEMON TIMEOUT FAILURE"
                    log "DIAGNOSTIC: Docker daemon is not responding within expected time"
                    log "RECOVERY STEPS:"
                    log "1. Check system resources: multipass exec '$VM_NAME' -- free -h && multipass exec '$VM_NAME' -- df -h"
                    log "2. Check Docker daemon logs for hangs: multipass exec '$VM_NAME' -- sudo journalctl -u docker.service --no-pager"
                    log "3. Check running processes: multipass exec '$VM_NAME' -- ps aux | head -20"
                    log "4. Restart Docker daemon: multipass exec '$VM_NAME' -- sudo systemctl restart docker"
                    log "5. If persistent, increase system resources or check for resource contention"
                    
                # Check for resource constraint errors
                elif echo "$DOCKER_DAEMON_ERROR" | grep -q -E "(no space left|insufficient space|out of memory|memory|resource|disk full)"; then
                    log "ERROR TYPE: DOCKER DAEMON RESOURCE CONSTRAINT FAILURE"
                    log "DIAGNOSTIC: System lacks sufficient resources for Docker daemon operation"
                    log "RECOVERY STEPS:"
                    log "1. Check disk space: multipass exec '$VM_NAME' -- df -h"
                    log "2. Check memory usage: multipass exec '$VM_NAME' -- free -h"
                    log "3. Clean up Docker resources: multipass exec '$VM_NAME' -- sudo docker system prune -f"
                    log "4. Remove unused packages: multipass exec '$VM_NAME' -- sudo apt autoremove -y"
                    log "5. Clear system logs: multipass exec '$VM_NAME' -- sudo journalctl --vacuum-size=100M"
                    log "6. Increase VM resources if needed: multipass stop '$VM_NAME' && multipass delete '$VM_NAME' && multipass launch --name '$VM_NAME' --memory 4G --disk 20G"
                    
                # Check for configuration errors
                elif echo "$DOCKER_DAEMON_ERROR" | grep -q -E "(configuration|config|failed to start|failed to initialize|daemon.json)"; then
                    log "ERROR TYPE: DOCKER DAEMON CONFIGURATION FAILURE"
                    log "DIAGNOSTIC: Docker daemon configuration issues preventing startup"
                    log "RECOVERY STEPS:"
                    log "1. Check Docker daemon config: multipass exec '$VM_NAME' -- cat /etc/docker/daemon.json"
                    log "2. Check systemd service config: multipass exec '$VM_NAME' -- cat /lib/systemd/system/docker.service"
                    log "3. Check Docker storage config: multipass exec '$VM_NAME' -- cat /etc/docker/daemon.json"
                    log "4. Validate JSON syntax: multipass exec '$VM_NAME' -- python3 -m json.tool /etc/docker/daemon.json"
                    log "5. Reset to default config: multipass exec '$VM_NAME' -- sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.backup && sudo systemctl restart docker"
                    
                # Check for driver/storage issues
                elif echo "$DOCKER_DAEMON_ERROR" | grep -q -E "(driver|storage|filesystem|aufs|overlay|devicemapper|graphdriver)"; then
                    log "ERROR TYPE: DOCKER DAEMON STORAGE DRIVER FAILURE"
                    log "DIAGNOSTIC: Docker storage driver or filesystem compatibility issues"
                    log "RECOVERY STEPS:"
                    log "1. Check filesystem type: multipass exec '$VM_NAME' -- df -T /"
                    log "2. Check loaded kernel modules: multipass exec '$VM_NAME' -- lsmod | grep -E '(aufs|overlay|devicemapper)'"
                    log "3. Check Docker storage driver: multipass exec '$VM_NAME' -- docker info 2>/dev/null | grep -A 10 'Storage Driver:' || echo 'Cannot get storage driver info'"
                    log "4. Load required modules: multipass exec '$VM_NAME' -- sudo modprobe overlay && sudo modprobe aufs"
                    log "5. Reboot VM if modules were loaded: multipass exec '$VM_NAME' -- sudo reboot"
                    log "6. Consider using different storage driver if issues persist"
                    
                # Check for firewall/security issues
                elif echo "$DOCKER_DAEMON_ERROR" | grep -q -E "(firewall|security|selinux|apparmor|policy|iptables)"; then
                    log "ERROR TYPE: DOCKER DAEMON SECURITY/NETWORK RESTRICTION"
                    log "DIAGNOSTIC: Security policies or firewall rules blocking Docker daemon"
                    log "RECOVERY STEPS:"
                    log "1. Check firewall status: multipass exec '$VM_NAME' -- sudo ufw status"
                    log "2. Check AppArmor status: multipass exec '$VM_NAME' -- aa-status"
                    log "3. Check SELinux status: multipass exec '$VM_NAME' -- getenforce"
                    log "4. Disable firewall temporarily: multipass exec '$VM_NAME' -- sudo ufw disable"
                    log "5. Allow Docker through firewall: multipass exec '$VM_NAME' -- sudo ufw allow 2375/tcp && sudo ufw allow 2376/tcp"
                    log "6. Manual daemon restart: multipass exec '$VM_NAME' -- sudo systemctl restart docker"
                    
                # Check for Docker service issues
                elif echo "$DOCKER_DAEMON_ERROR" | grep -q -E "(service|systemd|unit|job|failed to start service)"; then
                    log "ERROR TYPE: DOCKER DAEMON SERVICE MANAGEMENT FAILURE"
                    log "DIAGNOSTIC: Systemd service management issues with Docker daemon"
                    log "RECOVERY STEPS:"
                    log "1. Check systemd service status: multipass exec '$VM_NAME' -- sudo systemctl status docker"
                    log "2. Check systemd service file: multipass exec '$VM_NAME' -- cat /lib/systemd/system/docker.service"
                    log "3. Reload systemd daemon: multipass exec '$VM_NAME' -- sudo systemctl daemon-reload"
                    log "4. Reset Docker service: multipass exec '$VM_NAME' -- sudo systemctl reset-failed docker"
                    log "5. Restart Docker service: multipass exec '$VM_NAME' -- sudo systemctl restart docker"
                    log "6. Check service logs: multipass exec '$VM_NAME' -- sudo journalctl -u docker.service -f"
                    
                # Check for network connectivity issues
                elif echo "$DOCKER_DAEMON_ERROR" | grep -q -E "(network|connect|resolve host|connection|unreachable)"; then
                    log "ERROR TYPE: DOCKER DAEMON NETWORK CONNECTIVITY FAILURE"
                    log "DIAGNOSTIC: Network connectivity issues affecting Docker daemon"
                    log "RECOVERY STEPS:"
                    log "1. Check network interfaces: multipass exec '$VM_NAME' -- ip a"
                    log "2. Check DNS resolution: multipass exec '$VM_NAME' -- nslookup google.com"
                    log "3. Check network connectivity: multipass exec '$VM_NAME' -- ping -c 2 google.com"
                    log "4. Check Docker network config: multipass exec '$VM_NAME' -- cat /etc/docker/daemon.json | grep -A 10 -B 10 network || echo 'No network config found'"
                    log "5. Check Docker daemon network logs: multipass exec '$VM_NAME' -- sudo journalctl -u docker.service | grep -i network"
                    log "6. Restart VM network: multipass exec '$VM_NAME' -- sudo systemctl restart networking"
                    
                # Check for installation/dependency issues
                elif echo "$DOCKER_DAEMON_ERROR" | grep -q -E "(dependency|package|library|lib|so.*not found|cannot open shared object)"; then
                    log "ERROR TYPE: DOCKER DAEMON DEPENDENCY FAILURE"
                    log "DIAGNOSTIC: Missing or incompatible system dependencies for Docker daemon"
                    log "RECOVERY STEPS:"
                    log "1. Check installed Docker packages: multipass exec '$VM_NAME' -- dpkg -l | grep docker"
                    log "2. Check for missing libraries: multipass exec '$VM_NAME' -- ldd $(which docker)"
                    log "3. Fix broken dependencies: multipass exec '$VM_NAME' -- sudo apt --fix-broken install -y"
                    log "4. Update system: multipass exec '$VM_NAME' -- sudo apt update && sudo apt upgrade -y"
                    log "5. Reinstall Docker: multipass exec '$VM_NAME' -- sudo apt remove --purge docker* && sudo apt autoremove && curl -fsSL https://get.docker.com | sh"
                    
                # Generic/unknown errors with comprehensive diagnostic info
                else
                    log "ERROR TYPE: UNKNOWN DOCKER DAEMON STARTUP FAILURE"
                    log "DIAGNOSTIC: Docker daemon failed to start with unknown error pattern"
                    log "ERROR DETAILS:"
                    log "Docker info command exit code: $DOCKER_INFO_EXIT_CODE"
                    log "Docker info command output:"
                    log "$DOCKER_DAEMON_ERROR"
                    log "RECOVERY STEPS:"
                    log "1. Manual daemon start attempt: multipass exec '$VM_NAME' -- sudo systemctl start docker"
                    log "2. Check daemon status: multipass exec '$VM_NAME' -- sudo systemctl status docker"
                    log "3. Check system logs: multipass exec '$VM_NAME' -- sudo dmesg | tail -n20"
                    log "4. Check application logs: multipass exec '$VM_NAME' -- sudo journalctl -u docker.service --no-pager"
                    log "5. Complete Docker reinstallation: multipash exec '$VM_NAME' -- sudo apt remove --purge docker* && sudo apt autoremove && sudo apt clean && curl -fsSL https://get.docker.com | sh"
                fi
                
                # Collect comprehensive diagnostic information
                log "COMPREHENSIVE DIAGNOSTIC INFORMATION:"
                log "--------------------------------------------------"
                
                # System information
                log "SYSTEM INFORMATION:"
                log "- Hostname: $(multipass exec "$VM_NAME" -- hostname 2>/dev/null || echo 'Unable to get hostname')"
                log "- OS info: $(multipass exec "$VM_NAME" -- uname -a 2>/dev/null || echo 'Unable to get OS info')"
                log "- System uptime: $(multipass exec "$VM_NAME" -- uptime 2>/dev/null || echo 'Unable to get uptime')"
                
                # Docker service status
                log "DOCKER SERVICE STATUS:"
                multipass exec "$VM_NAME" -- sudo systemctl status docker 2>&1 | tee -a "$LOG_FILE" || true
                
                # Docker daemon logs
                log "DOCKER DAEMON LOGS (last 20 lines):"
                multipass exec "$VM_NAME" -- sudo journalctl -u docker.service --no-pager -n 20 2>&1 | tee -a "$LOG_FILE" || true
                
                # Docker daemon process
                log "DOCKER DAEMON PROCESS:"
                multipass exec "$VM_NAME" -- ps aux | grep -i docker | grep -v grep 2>&1 | tee -a "$LOG_FILE" || true
                
                # System resources
                log "SYSTEM RESOURCES:"
                multipass exec "$VM_NAME" -- df -h 2>&1 | tee -a "$LOG_FILE" || true
                multipass exec "$VM_NAME" -- free -h 2>&1 | tee -a "$LOG_FILE" || true
                multipass exec "$VM_NAME" -- top -bn1 | head -n10 2>&1 | tee -a "$LOG_FILE" || true
                
                # Docker configuration
                log "DOCKER CONFIGURATION:"
                multipass exec "$VM_NAME" -- ls -la /etc/docker/ 2>&1 | tee -a "$LOG_FILE" || true
                multipass exec "$VM_NAME" -- cat /etc/docker/daemon.json 2>&1 | tee -a "$LOG_FILE" || true
                
                # Docker socket
                log "DOCKER SOCKET STATUS:"
                multipass exec "$VM_NAME" -- ls -la /var/run/docker.sock 2>&1 | tee -a "$LOG_FILE" || true
                multipass exec "$VM_NAME" -- netstat -tlnp | grep docker 2>&1 | tee -a "$LOG_FILE" || true
                
                # Systemd service
                log "SYSTEMD SERVICE INFO:"
                multipass exec "$VM_NAME" -- cat /lib/systemd/system/docker.service 2>&1 | tee -a "$LOG_FILE" || true
                
                # Network information
                log "NETWORK INFORMATION:"
                multipass exec "$VM_NAME" -- ip a 2>&1 | tee -a "$LOG_FILE" || true
                multipass exec "$VM_NAME" -- netstat -tlnp 2>&1 | head -n20 | tee -a "$LOG_FILE" || true
                
                # Kernel modules
                log "KERNEL MODULES:"
                multipass exec "$VM_NAME" -- lsmod | grep -E '(overlay|aufs|devicemapper|bridge|iptable)' 2>&1 | tee -a "$LOG_FILE" || true
                
                log "--------------------------------------------------"
                log "MANUAL RECOVERY INSTRUCTIONS:"
                log "1. Connect to VM: multipass shell '$VM_NAME'"
                log "2. Try manual daemon start: sudo systemctl start docker"
                log "3. Check status: sudo systemctl status docker"
                log "4. View logs: sudo journalctl -u docker.service -f"
                log "5. If all else fails, reinstall Docker:"
                log "   sudo apt remove --purge docker* && sudo apt autoremove && curl -fsSL https://get.docker.com | sh"
            fi
            
            # Wait with exponential backoff before next attempt
            if [ $DAEMON_CHECK_ATTEMPT -lt $MAX_DAEMON_CHECK_ATTEMPTS ]; then
                log "Waiting ${RETRY_DELAY}s before next attempt..."
                sleep $RETRY_DELAY
                
                # Implement exponential backoff: double the delay, but cap at MAX_RETRY_DELAY
                RETRY_DELAY=$((RETRY_DELAY * 2))
                if [ $RETRY_DELAY -gt $MAX_RETRY_DELAY ]; then
                    RETRY_DELAY=$MAX_RETRY_DELAY
                fi
            fi
        fi
        
        DAEMON_CHECK_ATTEMPT=$((DAEMON_CHECK_ATTEMPT + 1))
    done
    
    # Verify Docker commands work without sudo
    log "Verifying Docker commands work without sudo..."
    DOCKER_NO_SUDO_WORKING=false
    MAX_NO_SUDO_CHECK_ATTEMPTS=5
    NO_SUDO_CHECK_ATTEMPT=1
    NO_SUDO_RETRY_DELAY=2
    
    while [ $NO_SUDO_CHECK_ATTEMPT -le $MAX_NO_SUDO_CHECK_ATTEMPTS ]; do
        log "Docker no-sudo verification attempt $NO_SUDO_CHECK_ATTEMPT/$MAX_NO_SUDO_CHECK_ATTEMPTS..."
        
        if multipass exec "$VM_NAME" -- docker ps >/dev/null 2>&1; then
            log "✅ Docker commands work without sudo in VM (attempt $NO_SUDO_CHECK_ATTEMPT)"
            DOCKER_NO_SUDO_WORKING=true
            break
        else
            log "⚠️  Docker commands require sudo in VM (attempt $NO_SUDO_CHECK_ATTEMPT)"
            
            # If this is the last attempt, provide detailed error information
            if [ $NO_SUDO_CHECK_ATTEMPT -eq $MAX_NO_SUDO_CHECK_ATTEMPTS ]; then
                log "ERROR: Docker commands still require sudo after $MAX_NO_SUDO_CHECK_ATTEMPTS attempts"
                log "DIAGNOSTIC: Checking docker group membership..."
                multipass exec "$VM_NAME" -- groups ubuntu 2>&1 | tee -a "$LOG_FILE" || true
                
                log "DIAGNOSTIC: Checking if user is in docker group..."
                multipass exec "$VM_NAME" -- id ubuntu | grep docker 2>&1 | tee -a "$LOG_FILE" || true
                
                log "DIAGNOSTIC: Testing sudo docker ps for comparison..."
                multipass exec "$VM_NAME" -- sudo docker ps 2>&1 | tee -a "$LOG_FILE" || true
                
                log "DIAGNOSTIC: Checking current user session..."
                multipass exec "$VM_NAME" -- whoami 2>&1 | tee -a "$LOG_FILE" || true
                multipass exec "$VM_NAME" -- echo $USER 2>&1 | tee -a "$LOG_FILE" || true
            fi
            
            # Wait before next attempt
            if [ $NO_SUDO_CHECK_ATTEMPT -lt $MAX_NO_SUDO_CHECK_ATTEMPTS ]; then
                log "Waiting ${NO_SUDO_RETRY_DELAY}s before next attempt..."
                sleep $NO_SUDO_RETRY_DELAY
            fi
        fi
        
        NO_SUDO_CHECK_ATTEMPT=$((NO_SUDO_CHECK_ATTEMPT + 1))
    done
    
    # Provide summary status
    if [ "$DOCKER_CLI_AVAILABLE" = true ] && [ "$DOCKER_DAEMON_RUNNING" = true ] && [ "$DOCKER_NO_SUDO_WORKING" = true ]; then
        log "✅ Docker setup in VM completed successfully - Docker CLI, daemon, and no-sudo access are all available"
        log "   - Docker CLI: Verified and operational"
        log "   - Docker daemon: Started and verified with retry loop"
        log "   - User permissions: Configured and verified for docker group access"
        log "   - No-sudo access: Verified Docker commands work without sudo"
        return 0
    elif [ "$DOCKER_CLI_AVAILABLE" = true ] && [ "$DOCKER_DAEMON_RUNNING" = true ] && [ "$DOCKER_NO_SUDO_WORKING" = false ]; then
        log "❌ Docker setup in VM failed - Docker CLI and daemon available but no-sudo access not working"
        log "RECOVERY: Try manually activating docker group membership: multipass shell $VM_NAME"
        log "         Then run: newgrp docker or log out and log back in"
        log "         Alternatively, run: sudo usermod -aG docker ubuntu && newgrp docker"
        return 1
    elif [ "$DOCKER_CLI_AVAILABLE" = true ] && [ "$DOCKER_DAEMON_RUNNING" = false ]; then
        log "❌ Docker setup in VM failed - Docker CLI available but daemon not running after $MAX_DAEMON_CHECK_ATTEMPTS attempts"
        log "RECOVERY: Try manually starting Docker daemon in VM: multipass shell $VM_NAME"
        log "         Then run: sudo systemctl start docker && sudo systemctl enable docker"
        return 1
    elif [ "$DOCKER_CLI_AVAILABLE" = false ] && [ "$DOCKER_DAEMON_RUNNING" = true ]; then
        log "⚠️  Docker setup in VM completed with warnings - Docker daemon running but CLI not available"
        return 1
    else
        log "❌ Docker setup in VM failed - Neither Docker CLI nor daemon are available"
        return 1
    fi
}

# ===========================
# LOCK FILE VALIDATION SECTION
# ===========================

# Skip dependency check flag (can be overridden with --skip-deps-check)
SKIP_DEPS_CHECK=false

# Lock file validation function with user-friendly error messages
validate_lock_files() {
    log "Starting lock file validation..."
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        log "ERROR: package.json not found in current directory"
        log "SOLUTION: Ensure you're running this script from the project root directory"
        log "         where package.json is located."
        return 1
    fi
    
    # Check if package-lock.json exists
    if [ ! -f "package-lock.json" ]; then
        log "ERROR: package-lock.json not found in current directory"
        log "SOLUTION: Run 'npm install' to generate the missing package-lock.json"
        log "         This file is required for reproducible builds."
        return 1
    fi
    
    log "Checking if package.json and package-lock.json are in sync..."
    
    # Run npm ci --dry-run to validate lock file consistency
    local ci_output
    ci_output=$(npm ci --dry-run 2>&1)
    local ci_status=$?
    
    if [ $ci_status -ne 0 ]; then
        # Make ci_output available to handle_secrets_error by exporting it
        export ci_output
        handle_secrets_error 200 "Lock files are out of sync" \
            "Run 'npm install' to update package-lock.json, then commit both files together. Use './deploy.sh --skip-deps-check' for emergency bypass."
        return 1
    fi
    
    log "✅ SUCCESS: package.json and package-lock.json are synchronized"
    log "   Dependencies are ready for reproducible Docker builds."
    return 0
}

# ===========================
# KUBERNETES SECRETS SETUP SECTION
# ===========================

# Kubernetes secrets setup error handler
handle_secrets_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "DEPLOYMENT ERROR [Code: $error_code]: $error_message"
    log "RECOVERY SUGGESTION: $recovery_suggestion"
    
    # Enhanced recovery suggestions for file transfer errors (110-119)
    if [ "$error_code" -ge 110 ] && [ "$error_code" -le 119 ]; then
        log "ENHANCED RECOVERY SUGGESTIONS:"
        case $error_code in
            110)
                log "1. Verify VM is running: multipass info '$VM_NAME'"
                log "2. Start VM if needed: multipass start '$VM_NAME'"
                log "3. Check VM permissions: multipass exec '$VM_NAME' -- whoami"
                log "4. Manual directory creation: multipass exec '$VM_NAME' -- mkdir -p /home/ubuntu/k8s"
                log "5. If permission denied, try: multipass exec '$VM_NAME' -- sudo mkdir -p /home/ubuntu/k8s && sudo chown ubuntu:ubuntu /home/ubuntu/k8s"
                ;;
            111)
                log "1. Verify secrets.yaml exists locally: ls -la k8s/secrets.yaml"
                log "2. Check file permissions: ls -l k8s/secrets.yaml"
                log "3. Verify VM is accessible: multipass info '$VM_NAME'"
                log "4. Manual transfer test: multipass transfer k8s/secrets.yaml '$VM_NAME':/tmp/test-secrets.yaml"
                log "5. If file doesn't exist, run setup-secrets.sh first: bash k8s/setup-secrets.sh"
                ;;
            112)
                log "1. Verify deployment.yaml exists locally: ls -la k8s/deployment.yaml"
                log "2. Check file is not empty: wc -l k8s/deployment.yaml"
                log "3. Verify VM is accessible: multipass info '$VM_NAME'"
                log "4. Manual transfer test: multipass transfer k8s/deployment.yaml '$VM_NAME':/tmp/test-deployment.yaml"
                log "5. Check file syntax: kubectl apply --dry-run=client -f k8s/deployment.yaml"
                ;;
            113)
                log "1. Verify service.yaml exists locally: ls -la k8s/service.yaml"
                log "2. Check file is not empty: wc -l k8s/service.yaml"
                log "3. Verify VM is accessible: multipass info '$VM_NAME'"
                log "4. Manual transfer test: multipass transfer k8s/service.yaml '$VM_NAME':/tmp/test-service.yaml"
                log "5. Check file syntax: kubectl apply --dry-run=client -f k8s/service.yaml"
                ;;
            114)
                log "1. Verify ingress.yaml exists locally: ls -la k8s/ingress.yaml"
                log "2. Check file is not empty: wc -l k8s/ingress.yaml"
                log "3. Verify VM is accessible: multipass info '$VM_NAME'"
                log "4. Manual transfer test: multipass transfer k8s/ingress.yaml '$VM_NAME':/tmp/test-ingress.yaml"
                log "5. Check file syntax: kubectl apply --dry-run=client -f k8s/ingress.yaml"
                ;;
            115)
                log "1. Check if transfer actually succeeded: multipass exec '$VM_NAME' -- ls -la /home/ubuntu/k8s/"
                log "2. Verify secrets.yaml exists in VM: multipass exec '$VM_NAME' -- test -f /home/ubuntu/k8s/secrets.yaml && echo 'EXISTS' || echo 'MISSING'"
                log "3. Check file size in VM: multipass exec '$VM_NAME' -- wc -c /home/ubuntu/k8s/secrets.yaml"
                log "4. Manual re-transfer: multipass transfer k8s/secrets.yaml '$VM_NAME':/home/ubuntu/k8s/secrets.yaml"
                log "5. If file exists but validation fails, check VM filesystem: multipass exec '$VM_NAME' -- df -h /home/ubuntu/"
                ;;
            116)
                log "1. Check if transfer actually succeeded: multipass exec '$VM_NAME' -- ls -la /home/ubuntu/k8s/"
                log "2. Verify deployment.yaml exists in VM: multipass exec '$VM_NAME' -- test -f /home/ubuntu/k8s/deployment.yaml && echo 'EXISTS' || echo 'MISSING'"
                log "3. Check file size in VM: multipass exec '$VM_NAME' -- wc -c /home/ubuntu/k8s/deployment.yaml"
                log "4. Manual re-transfer: multipass transfer k8s/deployment.yaml '$VM_NAME':/home/ubuntu/k8s/deployment.yaml"
                log "5. If file exists but validation fails, check VM filesystem: multipass exec '$VM_NAME' -- df -h /home/ubuntu/"
                ;;
            117)
                log "1. Check if transfer actually succeeded: multipass exec '$VM_NAME' -- ls -la /home/ubuntu/k8s/"
                log "2. Verify service.yaml exists in VM: multipass exec '$VM_NAME' -- test -f /home/ubuntu/k8s/service.yaml && echo 'EXISTS' || echo 'MISSING'"
                log "3. Check file size in VM: multipass exec '$VM_NAME' -- wc -c /home/ubuntu/k8s/service.yaml"
                log "4. Manual re-transfer: multipass transfer k8s/service.yaml '$VM_NAME':/home/ubuntu/k8s/service.yaml"
                log "5. If file exists but validation fails, check VM filesystem: multipass exec '$VM_NAME' -- df -h /home/ubuntu/"
                ;;
            118)
                log "1. Check if transfer actually succeeded: multipass exec '$VM_NAME' -- ls -la /home/ubuntu/k8s/"
                log "2. Verify ingress.yaml exists in VM: multipass exec '$VM_NAME' -- test -f /home/ubuntu/k8s/ingress.yaml && echo 'EXISTS' || echo 'MISSING'"
                log "3. Check file size in VM: multipass exec '$VM_NAME' -- wc -c /home/ubuntu/k8s/ingress.yaml"
                log "4. Manual re-transfer: multipass transfer k8s/ingress.yaml '$VM_NAME':/home/ubuntu/k8s/ingress.yaml"
                log "5. If file exists but validation fails, check VM filesystem: multipass exec '$VM_NAME' -- df -h /home/ubuntu/"
                ;;
        esac
    fi
    
    # Log additional diagnostic information based on error code ranges
    log "DEPLOYMENT DIAGNOSTIC INFO:"
    log "Current directory: $(pwd)"
    log "Environment file exists: $([ -f ".env" ] && echo "yes" || echo "no")"
    log "k8s directory exists: $([ -d "k8s" ] && echo "yes" || echo "no")"
    
    # Enhanced diagnostics for file transfer errors (110-119)
    if [ "$error_code" -ge 110 ] && [ "$error_code" -le 119 ]; then
        log "FILE TRANSFER DIAGNOSTIC INFO:"
        log "VM_NAME: $VM_NAME"
        log "VM status: $(multipass info "$VM_NAME" 2>/dev/null || echo 'Unable to get VM status')"
        log "VM IP: $(multipass info "$VM_NAME" | grep -E "IPv4:" | awk '{print $2}' | cut -d',' -f1 | head -n1 2>/dev/null || echo 'Unable to get VM IP')"
        
        # Check if k8s directory exists in VM
        log "k8s directory in VM: $(multipass exec "$VM_NAME" -- test -d /home/ubuntu/k8s 2>/dev/null && echo 'yes' || echo 'no')"
        
        # List files in VM k8s directory if it exists
        if multipass exec "$VM_NAME" -- test -d /home/ubuntu/k8s 2>/dev/null; then
            log "Files in VM k8s directory:"
            multipass exec "$VM_NAME" -- ls -la /home/ubuntu/k8s/ 2>/dev/null || log "Unable to list files in VM k8s directory"
        fi
        
        # Check specific file based on error code
        case $error_code in
            111|115)
                log "secrets.yaml in host k8s/: $([ -f "k8s/secrets.yaml" ] && echo 'yes' || echo 'no')"
                ;;
            112|116)
                log "deployment.yaml in host k8s/: $([ -f "k8s/deployment.yaml" ] && echo 'yes' || echo 'no')"
                ;;
            113|117)
                log "service.yaml in host k8s/: $([ -f "k8s/service.yaml" ] && echo 'yes' || echo 'no')"
                ;;
            114|118)
                log "ingress.yaml in host k8s/: $([ -f "k8s/ingress.yaml" ] && echo 'yes' || echo 'no')"
                ;;
        esac
    fi
    
    # Enhanced diagnostics for Docker build and load errors (120-124)
    if [ "$error_code" -ge 120 ] && [ "$error_code" -le 124 ]; then
        log "DOCKER BUILD DIAGNOSTIC INFO:"
        log "Docker daemon status: $(docker info 2>/dev/null > /dev/null && echo 'running' || echo 'not running')"
        log "Dockerfile exists: $([ -f "Dockerfile" ] && echo 'yes' || echo 'no')"
        log "Dockerfile size: $([ -f "Dockerfile" ] && wc -c < Dockerfile || echo 'N/A') bytes"
        
        # Check specific Docker issues based on error code
        case $error_code in
            120)
                log "Dockerfile not found. Expected location: $(pwd)/Dockerfile"
                log "Files in current directory:"
                ls -la | head -10
                ;;
            121)
                log "Docker build failed. Check build output above for specific errors."
                log "Docker version: $(docker --version 2>/dev/null || echo 'Docker not available')"
                ;;
            122)
                log "Docker image verification failed. Image 'my-ag-ui-app:latest' not found."
                log "Available Docker images:"
                docker images --format "{{.Repository}}:{{.Tag}}" | head -5
                ;;
            123)
                log "Docker image load into VM failed. Image 'my-ag-ui-app:latest' could not be loaded into VM."
                log "Docker daemon in VM: $(multipass exec "$VM_NAME" -- docker info 2>/dev/null > /dev/null && echo 'running' || echo 'not running')"
                log "Docker images in VM:"
                multipass exec "$VM_NAME" -- docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | head -5 || echo "Unable to get Docker images from VM"
                log "VM disk space:"
                multipass exec "$VM_NAME" -- df -h 2>/dev/null | head -5 || echo "Unable to get VM disk space"
                ;;
            124)
                log "Docker image verification in VM failed. Image 'my-ag-ui-app:latest' not found in VM's Docker images."
                log "Docker images in VM:"
                multipass exec "$VM_NAME" -- docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | head -10 || echo "Unable to get Docker images from VM"
                log "Docker daemon in VM: $(multipass exec "$VM_NAME" -- docker info 2>/dev/null > /dev/null && echo 'running' || echo 'not running')"
                log "This suggests the image load command appeared to succeed but the image is not actually available."
                ;;
        esac
    fi
    
    # Enhanced diagnostics for Docker permissions errors (128-130)
    if [ "$error_code" -ge 128 ] && [ "$error_code" -le 130 ]; then
        log "DOCKER PERMISSIONS DIAGNOSTIC INFO:"
        log "Current user: $USER"
        log "User groups: $(groups 2>/dev/null || echo 'Unable to get groups')"
        log "Docker daemon status: $(systemctl is-active docker 2>/dev/null || echo 'Unable to check')"
        log "Docker socket permissions: $(ls -la /var/run/docker.sock 2>/dev/null || echo 'Unable to check socket permissions')"
        
        case $error_code in
            128)
                log "Docker socket permission denied - user '$USER' cannot access /var/run/docker.sock"
                log "RECOVERY SUGGESTIONS:"
                log "1. Add user to docker group: sudo usermod -aG docker $USER"
                log "2. Log out and log back in, OR run: newgrp docker"
                log "3. If you don't have sudo access, ask your system administrator"
                log "4. Check if Docker daemon is running: sudo systemctl status docker"
                log "5. Verify Docker socket exists and has correct permissions: ls -la /var/run/docker.sock"
                ;;
            129)
                log "Docker daemon not accessible - daemon may not be running"
                log "RECOVERY SUGGESTIONS:"
                log "1. Start Docker daemon: sudo systemctl start docker"
                log "2. Enable Docker at startup: sudo systemctl enable docker"
                log "3. Check Docker service status: sudo systemctl status docker"
                log "4. Check Docker service logs: journalctl -u docker.service --no-pager"
                log "5. Restart Docker service: sudo systemctl restart docker"
                ;;
            130)
                log "Docker build permission error - build failed due to permission issues"
                log "RECOVERY SUGGESTIONS:"
                log "1. Check if Docker daemon is running: sudo systemctl status docker"
                log "2. Check Docker socket permissions: ls -la /var/run/docker.sock"
                log "3. Ensure user is in docker group: groups | grep docker"
                log "4. Add user to docker group if needed: sudo usermod -aG docker $USER"
                log "5. Log out and log back in OR run: newgrp docker"
                log "6. Check if there are file permission issues in build context: ls -la"
                log "7. Verify Dockerfile has correct permissions: ls -la Dockerfile"
                ;;
        esac
    fi
    
    # Enhanced diagnostics for deployment restart error (125)
    if [ "$error_code" -eq 125 ]; then
        log "DEPLOYMENT RESTART DIAGNOSTIC INFO:"
        log "VM_NAME: $VM_NAME"
        log "VM status: $(multipass info "$VM_NAME" 2>/dev/null || echo 'Unable to get VM status')"
        
        log "Kubernetes deployment status:"
        multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app 2>/dev/null || log "Unable to get deployment status"
        
        log "Kubernetes deployment details:"
        multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o yaml 2>/dev/null | head -20 || log "Unable to get deployment details"
        
        log "Pod status:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>/dev/null || log "Unable to get pod status"
        
        log "ReplicaSet status:"
        multipass exec "$VM_NAME" -- microk8s kubectl get replicaset -l app=my-ag-ui-app 2>/dev/null || log "Unable to get replicaset status"
        
        log "Microk8s status:"
        multipass exec "$VM_NAME" -- microk8s status 2>/dev/null | head -10 || log "Unable to get microk8s status"
        
        log "RECOVERY SUGGESTIONS:"
        log "1. Check if deployment exists: multipass exec '$VM_NAME' -- microk8s kubectl get deployment my-ag-ui-app"
        log "2. Check if deployment is in progress: multipass exec '$VM_NAME' -- microk8s kubectl rollout status deployment/my-ag-ui-app"
        log "3. Try manual restart: multipass exec '$VM_NAME' -- microk8s kubectl rollout restart deployment/my-ag-ui-app"
        log "4. Check microk8s is running: multipass exec '$VM_NAME' -- microk8s status"
        log "5. If deployment is stuck, try deleting and recreating: multipass exec '$VM_NAME' -- microk8s kubectl delete deployment my-ag-ui-app && microk8s kubectl apply -f k8s/deployment.yaml"
    fi
    
    # Enhanced diagnostics for pod status verification error (126)
    if [ "$error_code" -eq 126 ]; then
        log "POD STATUS VERIFICATION DIAGNOSTIC INFO:"
        log "VM_NAME: $VM_NAME"
        log "VM status: $(multipass info "$VM_NAME" 2>/dev/null || echo 'Unable to get VM status')"
        
        log "Pod status details:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o wide 2>/dev/null || log "Unable to get pod status"
        
        log "Pod events:"
        multipass exec "$VM_NAME" -- microk8s kubectl describe pods -l app=my-ag-ui-app 2>/dev/null | grep -A 10 -B 10 "Events:" || log "Unable to get pod events"
        
        log "Pod container status:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[*].status.containerStatuses}' 2>/dev/null || log "Unable to get container status"
        
        log "Docker images in VM:"
        multipass exec "$VM_NAME" -- docker images my-ag-ui-app:latest 2>/dev/null || log "Unable to get Docker images in VM"
        
        log "RECOVERY SUGGESTIONS:"
        log "1. Check if the correct image is loaded in VM: multipass exec '$VM_NAME' -- docker images my-ag-ui-app:latest"
        log "2. Check pod logs for image pull errors: multipass exec '$VM_NAME' -- microk8s kubectl logs -l app=my-ag-ui-app"
        log "3. Verify image exists locally: docker images my-ag-ui-app:latest"
        log "4. Try rebuilding and reloading the image: docker build -t my-ag-ui-app:latest . && docker save my-ag-ui-app:latest | multipass exec '$VM_NAME' -- docker load"
        log "5. Check if pod is stuck in ImagePullBackOff: multipass exec '$VM_NAME' -- microk8s kubectl get pods -l app=my-ag-ui-app"
        log "6. If image issue persists, check deployment image reference: multipass exec '$VM_NAME' -- microk8s kubectl get deployment my-ag-ui-app -o yaml | grep image:"
        log "7. Consider deleting the pod to trigger recreation: multipass exec '$VM_NAME' -- microk8s kubectl delete pods -l app=my-ag-ui-app"
    fi
    
    # Enhanced diagnostics for pod probe verification error (127)
    if [ "$error_code" -eq 127 ]; then
        log "POD PROBE VERIFICATION DIAGNOSTIC INFO:"
        log "VM_NAME: $VM_NAME"
        log "VM status: $(multipass info "$VM_NAME" 2>/dev/null || echo 'Unable to get VM status')"
        
        log "Pod probe status details:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o wide 2>/dev/null || log "Unable to get pod status"
        
        log "Pod probe events:"
        multipass exec "$VM_NAME" -- microk8s kubectl describe pods -l app=my-ag-ui-app 2>/dev/null | grep -E "(Readiness|Liveness)" || log "Unable to get probe events"
        
        log "Pod container probe status:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.containerStatuses[0].state}' 2>/dev/null || log "Unable to get container probe status"
        
        log "Pod last probe state:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.containerStatuses[0].lastState}' 2>/dev/null || log "Unable to get last probe state"
        
        log "Application health endpoint test:"
        multipass exec "$VM_NAME" -- microk8s kubectl exec -l app=my-ag-ui-app -- curl -s http://localhost:3000/health 2>/dev/null || log "Health endpoint test failed"
        
        log "Application logs:"
        multipass exec "$VM_NAME" -- microk8s kubectl logs -l app=my-ag-ui-app --tail=20 2>/dev/null || log "Unable to get application logs"
        
        log "RECOVERY SUGGESTIONS:"
        log "1. Check if the /health endpoint is working: multipass exec '$VM_NAME' -- microk8s kubectl exec -l app=my-ag-ui-app -- curl -s http://localhost:3000/health"
        log "2. Verify the health endpoint returns proper HTTP status (should be 200): multipass exec '$VM_NAME' -- microk8s kubectl exec -l app=my-ag-ui-app -- curl -w '%{http_code}' -s http://localhost:3000/health -o /dev/null"
        log "3. Check application logs for errors: multipass exec '$VM_NAME' -- microk8s kubectl logs -l app=my-ag-ui-app"
        log "4. Verify application is running on port 3000: multipass exec '$VM_NAME' -- microk8s kubectl exec -l app=my-ag-ui-app -- netstat -tlnp | grep :3000"
        log "5. Check if there are any application startup errors: multipass exec '$VM_NAME' -- microk8s kubectl logs -l app=my-ag-ui-app | grep -i error"
        log "6. If health endpoint is not implemented, check if it needs to be added to the application"
        log "7. Consider increasing probe timeouts or adjusting probe configuration in deployment.yaml if needed"
    fi
    
    # Enhanced diagnostics for lock file validation error (200)
    if [ "$error_code" -eq 200 ]; then
        log "LOCK FILE VALIDATION DIAGNOSTIC INFO:"
        log "Current directory: $(pwd)"
        log "package.json exists: $([ -f "package.json" ] && echo 'yes' || echo 'no')"
        log "package-lock.json exists: $([ -f "package-lock.json" ] && echo 'yes' || echo 'no')"
        log "npm ci --dry-run output:"
        log "$ci_output"
        
        log "DETAILED RECOVERY SUGGESTIONS:"
        log "1. Run this command to update the lock file:"
        log "   npm install"
        log ""
        log "2. Check that the lock file was updated:"
        log "   git status"
        log ""
        log "3. Commit the updated lock file to your repository:"
        log "   git add package-lock.json"
        log "   git commit -m 'Update package-lock.json to match package.json'"
        log ""
        log "4. Then run the deployment again:"
        log "   ./deploy.sh"
        log ""
        log "Why is this important?"
        log "Synchronized lock files ensure that every deployment uses"
        log "exactly the same dependency versions, preventing surprises"
        log "and making builds reproducible."
        log ""
        log "Emergency bypass (not recommended):"
        log "   ./deploy.sh --skip-deps-check"
    fi
    
    exit $error_code
}

# 5.4 Create Kubernetes secrets for sensitive environment variables
log "Starting Kubernetes secrets setup..."

# Check if k8s directory exists
if [ ! -d "k8s" ]; then
    handle_secrets_error 101 "k8s directory not found" \
        "Ensure k8s directory exists with Kubernetes manifests: $(pwd)/k8s/"
fi
log "k8s directory found: $(pwd)/k8s/"

# Check if setup-secrets.sh script exists
if [ ! -f "k8s/setup-secrets.sh" ]; then
    handle_secrets_error 102 "setup-secrets.sh script not found" \
        "Ensure setup-secrets.sh exists in k8s directory: $(pwd)/k8s/setup-secrets.sh"
fi
log "setup-secrets.sh script found: $(pwd)/k8s/setup-secrets.sh"

# Check if .env file exists
if [ ! -f ".env" ]; then
    log "WARNING: .env file not found in current directory"
    log "Using environment variables from shell environment"
fi

# Set up environment variables for secrets creation
log "Setting up environment variables for secrets creation..."

# Read environment variables from .env file if it exists
if [ -f ".env" ]; then
    log "Loading environment variables from .env file..."
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ ! "$line" =~ ^#.*$ ]] && [[ -n "$line" ]]; then
            # Export the variable
            export "$line"
            log "Set environment variable: ${line%%=*}"
        fi
    done < .env
fi

# Verify required environment variables are set
REQUIRED_VARS=("OPENAI_API_KEY" "OPENAI_BASE_URL" "OPENAI_MODEL" "EMBEDDING_MODEL")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    log "ERROR: Missing required environment variables:"
    for missing_var in "${MISSING_VARS[@]}"; do
        log "  - $missing_var"
    done
    handle_secrets_error 103 "Missing required environment variables" \
        "Set the missing environment variables in your shell or .env file before running the script"
fi
log "All required environment variables are set"

# Run the secrets setup script
log "Running secrets setup script..."
if ! bash k8s/setup-secrets.sh 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 104 "Failed to set up Kubernetes secrets" \
        "Check the secrets setup script output above for errors. Ensure environment variables are correctly set."
fi
log "Kubernetes secrets setup completed successfully"

# 5.5 Apply deployment manifest to microk8s cluster
# 5.6 Apply service manifest to microk8s cluster  
# 5.7 Apply ingress manifest to microk8s cluster
# 5.8 Wait for pods to be ready
# 5.9 Verify deployment status
# 5.10 Verify application is accessible via ingress

log "Starting Kubernetes deployment phase..."

# Apply secrets first (if not already applied by setup-secrets.sh)
# Validate VM_NAME is set before proceeding
if [ -z "$VM_NAME" ]; then
    log "ERROR: VM_NAME is not set. Cannot proceed with Kubernetes deployment."
    log "This should not happen. Please check the script configuration."
    exit 1
fi
log "Using VM_NAME: $VM_NAME for Kubernetes deployment"

# ===========================
# DEPENDENCY VALIDATION SECTION
# ===========================

# Validate lock files before Docker build (unless skipped)
if [ "$SKIP_DEPS_CHECK" = false ]; then
    log ""
    log "=================================================="
    log "  DEPENDENCY VALIDATION BEFORE DOCKER BUILD"
    log "=================================================="
    log ""
    
    if ! validate_lock_files; then
        log ""
        log "🛑 DEPLOYMENT HALTED: Dependency validation failed"
        log "   Fix the lock file sync issue and try again"
        log ""
        # Use error code 200 for lock file validation failures
        exit 200
    fi
    
    log ""
    log "✅ Dependency validation passed - proceeding with Docker build"
    log "=================================================="
    log ""
else
    log ""
    log "⚠️  SKIPPED: Dependency validation bypassed by --skip-deps-check"
    log "   Building with potentially out-of-sync lock files"
    log ""
fi

# 6.1 Build Docker image using Dockerfile in project root
log "Starting Docker image build process..."
log "Building Docker image 'my-ag-ui-app:latest' using project Dockerfile..."

# Check Docker daemon socket permissions before attempting build
log "Checking Docker daemon socket permissions..."
if ! docker info >/dev/null 2>&1; then
    # Check specifically for permission denied error
    if docker info 2>&1 | grep -q "permission denied"; then
        log "ERROR: Docker daemon socket permission denied"
        log "ERROR: Current user '$USER' does not have permission to access Docker daemon socket"
        log "RECOVERY INSTRUCTIONS:"
        log "1. Add your user to the docker group: sudo usermod -aG docker $USER"
        log "2. Log out and log back in, OR run: newgrp docker"
        log "3. If you don't have sudo access, ask your system administrator"
        log "4. Alternatively, run this script with sudo (not recommended for security)"
        log "5. Check if Docker daemon is running: sudo systemctl status docker"
        handle_secrets_error 128 "Docker daemon socket permission denied" \
            "Current user '$USER' lacks permission to access Docker daemon socket at /var/run/docker.sock. Add user to docker group: sudo usermod -aG docker $USER"
    else
        # Other Docker error (daemon not running, etc.)
        log "ERROR: Docker daemon is not accessible or not running"
        log "RECOVERY INSTRUCTIONS:"
        log "1. Check if Docker daemon is running: sudo systemctl status docker"
        log "2. Start Docker daemon if needed: sudo systemctl start docker"
        log "3. Enable Docker at startup: sudo systemctl enable docker"
        log "4. Check Docker service logs: journalctl -u docker.service"
        handle_secrets_error 129 "Docker daemon not accessible" \
            "Docker daemon is not running or not accessible. Start Docker daemon: sudo systemctl start docker"
    fi
fi
log "Docker daemon socket permissions verified - user has access"

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    handle_secrets_error 120 "Dockerfile not found in project root" \
        "Ensure Dockerfile exists in project root directory: $(pwd)/Dockerfile"
fi
log "Dockerfile found: $(pwd)/Dockerfile"

# Build Docker image with enhanced error handling for permission issues
log "Building Docker image 'my-ag-ui-app:latest'..."
if ! docker build -t my-ag-ui-app:latest . 2>&1 | tee -a "$LOG_FILE"; then
    # Check if the build failed due to permission issues
    BUILD_LOG=$(docker build -t my-ag-ui-app:latest . 2>&1 || true)
    if echo "$BUILD_LOG" | grep -q "permission denied"; then
        log "ERROR: Docker build failed due to permission issues"
        log "RECOVERY INSTRUCTIONS:"
        log "1. Verify Docker daemon is running: sudo systemctl status docker"
        log "2. Check Docker socket permissions: ls -la /var/run/docker.sock"
        log "3. Ensure user is in docker group: groups | grep docker"
        log "4. Add user to docker group if needed: sudo usermod -aG docker $USER"
        log "5. Log out and log back in OR run: newgrp docker"
        handle_secrets_error 130 "Docker build permission error" \
            "Docker build failed due to permission issues. Ensure user is in docker group and Docker daemon is running."
    else
        # Other build error (not permission-related)
        log "ERROR: Docker build failed - check build output above for specific errors"
        handle_secrets_error 121 "Failed to build Docker image" \
            "Check Docker build output above for errors. Ensure Docker is running and accessible. Check Dockerfile for syntax errors."
    fi
fi
log "Docker image 'my-ag-ui-app:latest' built successfully"

# 6.2 Verify Docker image was built successfully
log "Verifying Docker image was built successfully..."
if ! docker images my-ag-ui-app:latest --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "my-ag-ui-app:latest"; then
    handle_secrets_error 122 "Docker image verification failed" \
        "Docker image 'my-ag-ui-app:latest' was not found in local Docker images. Build may have failed silently."
fi
log "Docker image 'my-ag-ui-app:latest' verified successfully"

# Setup Docker in VM before attempting image load
log "Starting VM Docker setup..."
if ! setup_vm_docker; then
    log "ERROR: VM Docker setup failed"
    exit 1
fi
log "VM Docker setup completed successfully"

# 6.3 Load Docker image into multipass VM using docker save | multipass exec -- docker load
log "Starting Docker image load into VM..."
log "Loading Docker image 'my-ag-ui-app:latest' into multipass VM..."

# Load Docker image into VM using docker save | multipass exec -- docker load
if ! docker save my-ag-ui-app:latest | multipass exec "$VM_NAME" -- docker load 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 123 "Failed to load Docker image into VM" \
        "Check if Docker is running in the VM: multipass exec '$VM_NAME' -- docker info. Ensure VM has sufficient disk space for the image."
fi
log "Docker image 'my-ag-ui-app:latest' loaded successfully into VM"

# 6.4 Verify image is available in VM's Docker daemon
log "Verifying Docker image is available in VM's Docker daemon..."
if ! multipass exec "$VM_NAME" -- docker images my-ag-ui-app:latest --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "my-ag-ui-app:latest"; then
    handle_secrets_error 124 "Docker image verification in VM failed" \
        "Docker image 'my-ag-ui-app:latest' was not found in VM's Docker images. Image load may have failed silently."
fi
log "Docker image 'my-ag-ui-app:latest' verified successfully in VM"

# Create k8s directory in VM before file transfer
log "Preparing to create k8s directory in VM..."
log "Creating k8s directory in VM..."
if ! multipass exec "$VM_NAME" -- mkdir -p /home/ubuntu/k8s 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 110 "Failed to create k8s directory in VM" \
        "Check if VM is running and accessible: multipass info '$VM_NAME'. Ensure user has sufficient permissions to create directories in VM."
fi
log "k8s directory created successfully in VM"

# Transfer secrets.yaml to VM
log "Transferring secrets.yaml to VM..."
if ! multipass transfer k8s/secrets.yaml "$VM_NAME":/home/ubuntu/k8s/secrets.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 111 "Failed to transfer secrets.yaml to VM" \
        "Check if secrets.yaml exists in k8s directory: $(pwd)/k8s/secrets.yaml. Ensure VM is running and accessible: multipass info '$VM_NAME'."
fi
log "secrets.yaml transferred successfully to VM"

# Transfer deployment.yaml to VM
log "Transferring deployment.yaml to VM..."
if ! multipass transfer k8s/deployment.yaml "$VM_NAME":/home/ubuntu/k8s/deployment.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 112 "Failed to transfer deployment.yaml to VM" \
        "Check if deployment.yaml exists in k8s directory: $(pwd)/k8s/deployment.yaml. Ensure VM is running and accessible: multipass info '$VM_NAME'."
fi
log "deployment.yaml transferred successfully to VM"

# Transfer service.yaml to VM
log "Transferring service.yaml to VM..."
if ! multipass transfer k8s/service.yaml "$VM_NAME":/home/ubuntu/k8s/service.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 113 "Failed to transfer service.yaml to VM" \
        "Check if service.yaml exists in k8s directory: $(pwd)/k8s/service.yaml. Ensure VM is running and accessible: multipass info '$VM_NAME'."
fi
log "service.yaml transferred successfully to VM"

# Transfer ingress.yaml to VM
log "Transferring ingress.yaml to VM..."
if ! multipass transfer k8s/ingress.yaml "$VM_NAME":/home/ubuntu/k8s/ingress.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 114 "Failed to transfer ingress.yaml to VM" \
        "Check if ingress.yaml exists in k8s directory: $(pwd)/k8s/ingress.yaml. Ensure VM is running and accessible: multipass info '$VM_NAME'."
fi
log "ingress.yaml transferred successfully to VM"

# Validate all transferred files exist in VM before proceeding with Kubernetes deployment
log "Starting file validation process in VM..."

# Validate that secrets.yaml exists in VM after transfer
log "Validating that secrets.yaml exists in VM..."
if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/secrets.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 115 "secrets.yaml does not exist in VM after transfer" \
        "Check if file transfer was successful. Verify VM is accessible: multipass info '$VM_NAME'. Check logs for transfer errors."
fi
log "secrets.yaml validation successful - file exists in VM"

# Validate that deployment.yaml exists in VM after transfer
log "Validating that deployment.yaml exists in VM..."
if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/deployment.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 116 "deployment.yaml does not exist in VM after transfer" \
        "Check if file transfer was successful. Verify VM is accessible: multipass info '$VM_NAME'. Check logs for transfer errors."
fi
log "deployment.yaml validation successful - file exists in VM"

# Validate that service.yaml exists in VM after transfer
log "Validating that service.yaml exists in VM..."
if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/service.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 117 "service.yaml does not exist in VM after transfer" \
        "Check if file transfer was successful. Verify VM is accessible: multipass info '$VM_NAME'. Check logs for transfer errors."
fi
log "service.yaml validation successful - file exists in VM"

# Validate that ingress.yaml exists in VM after transfer
log "Validating that ingress.yaml exists in VM..."
if ! multipass exec "$VM_NAME" -- test -f /home/ubuntu/k8s/ingress.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 118 "ingress.yaml does not exist in VM after transfer" \
        "Check if file transfer was successful. Verify VM is accessible: multipass info '$VM_NAME'. Check logs for transfer errors."
fi
log "ingress.yaml validation successful - file exists in VM"
log "All Kubernetes files validated successfully in VM"

log "Applying Kubernetes secrets..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f k8s/secrets.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 105 "Failed to apply Kubernetes secrets" \
        "Check the secrets file: k8s/secrets.yaml. Ensure it's properly formatted and all variables are set."
fi
log "Kubernetes secrets applied successfully"

# Apply deployment manifest
log "Applying deployment manifest..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f k8s/deployment.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 106 "Failed to apply deployment manifest" \
        "Check the deployment file: k8s/deployment.yaml. Ensure it references secrets and config maps correctly."
fi
log "Deployment manifest applied successfully"

# 6.5 Restart deployment to trigger pod recreation with new image
log "Restarting deployment to trigger pod recreation with new image..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl rollout restart deployment/my-ag-ui-app 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 125 "Failed to restart deployment" \
        "Check if deployment exists: microk8s kubectl get deployment my-ag-ui-app. Ensure deployment is in a state that can be restarted."
fi
log "Deployment restarted successfully - pods will be recreated with new image"

# 6.6 Verify pod status changes from ImagePullBackOff to Running
log "Verifying pod status changes from ImagePullBackOff to Running..."
MAX_POD_WAIT_ATTEMPTS=30
POD_WAIT_ATTEMPT=1
INITIAL_STATUS_CHECK=true
SAW_IMAGE_PULL_BACK_OFF=false

while [ $POD_WAIT_ATTEMPT -le $MAX_POD_WAIT_ATTEMPTS ]; do
    log "Checking pod status after deployment restart... (attempt $POD_WAIT_ATTEMPT/$MAX_POD_WAIT_ATTEMPTS)"
    
    # Get current pod status
    POD_STATUS_JSON=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o json 2>/dev/null || echo "")
    
    if [ -n "$POD_STATUS_JSON" ]; then
        # Check for ImagePullBackOff status
        IMAGE_PULL_BACK_OFF=$(echo "$POD_STATUS_JSON" | grep -o '"ImagePullBackOff"' || echo "")
        if [ -n "$IMAGE_PULL_BACK_OFF" ] && [ "$SAW_IMAGE_PULL_BACK_OFF" = false ]; then
            log "Pod status: ImagePullBackOff detected (expected before pod starts running)"
            SAW_IMAGE_PULL_BACK_OFF=true
        fi
        
        # Check for Running status
        POD_PHASE=$(echo "$POD_STATUS_JSON" | grep -o '"phase":"Running"' || echo "")
        POD_READY=$(echo "$POD_STATUS_JSON" | grep -o '"ready":true' || echo "")
        
        if [ -n "$POD_PHASE" ] && [ -n "$POD_READY" ]; then
            log "✓ Pod status changed to Running - verification successful"
            log "Pod phase: Running"
            log "Pod container status: Ready"
            break
        else
            log "Pod not yet running. Current status:"
            multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
            
            # If we haven't seen ImagePullBackOff and this is the first check, wait a bit more
            if [ "$SAW_IMAGE_PULL_BACK_OFF" = false ] && [ "$INITIAL_STATUS_CHECK" = true ]; then
                log "Waiting for pod status change from ImagePullBackOff to Running..."
                INITIAL_STATUS_CHECK=false
            fi
        fi
    else
        log "Unable to get pod status JSON, trying basic status check..."
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    if [ $POD_WAIT_ATTEMPT -eq $MAX_POD_WAIT_ATTEMPTS ]; then
        if [ "$SAW_IMAGE_PULL_BACK_OFF" = false ]; then
            log "ERROR: Never observed ImagePullBackOff status - pod may not be using the correct image"
        else
            log "ERROR: Pod did not reach Running status after deployment restart"
        fi
        
        log "Final pod status:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
        
        log "Pod details for debugging:"
        multipass exec "$VM_NAME" -- microk8s kubectl describe pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
        
        handle_secrets_error 126 "Pod did not reach Running status after deployment restart" \
            "Check pod logs: multipass exec '$VM_NAME' -- microk8s kubectl logs -l app=my-ag-ui-app. Verify image was loaded correctly in VM."
    fi
    
    sleep 5
    POD_WAIT_ATTEMPT=$((POD_WAIT_ATTEMPT + 1))
done

if [ "$SAW_IMAGE_PULL_BACK_OFF" = true ]; then
    log "✓ Confirmed: Pod status transitioned from ImagePullBackOff to Running"
else
    log "INFO: Pod started without ImagePullBackOff status (image may have been pre-loaded)"
fi

# 6.7 Verify pod passes readiness and liveness probes
log "Verifying pod passes readiness and liveness probes..."
MAX_PROBE_WAIT_ATTEMPTS=30
PROBE_WAIT_ATTEMPT=1

while [ $PROBE_WAIT_ATTEMPT -le $MAX_PROBE_WAIT_ATTEMPTS ]; do
    log "Checking probe status... (attempt $PROBE_WAIT_ATTEMPT/$MAX_PROBE_WAIT_ATTEMPTS)"
    
    # Get pod details including probe status
    POD_DETAILS=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o json 2>/dev/null || echo "")
    
    if [ -n "$POD_DETAILS" ]; then
        # Check readiness probe status
        READY=$(echo "$POD_DETAILS" | grep -o '"ready":true' || echo "")
        
        # Check liveness probe status by checking if pod is running and ready
        # (liveness probe failures would typically cause pod restarts or failures)
        POD_PHASE=$(echo "$POD_DETAILS" | grep -o '"phase":"Running"' || echo "")
        RESTART_COUNT=$(echo "$POD_DETAILS" | grep -o '"restartCount":[0-9]*' | head -1 | cut -d':' -f2 || echo "0")
        
        if [ -n "$READY" ] && [ -n "$POD_PHASE" ]; then
            log "✓ Readiness probe: PASSED"
            log "✓ Liveness probe: PASSED (pod is Running and Ready)"
            log "✓ Pod restart count: $RESTART_COUNT"
            
            # Get detailed probe information if available
            PROBE_DETAILS=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.containerStatuses[0].state}' 2>/dev/null || echo "")
            if [ -n "$PROBE_DETAILS" ]; then
                log "Detailed probe status: $PROBE_DETAILS"
            fi
            
            break
        else
            log "Probes not yet ready. Current status:"
            multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
            
            # Check for probe-specific errors
            if multipass exec "$VM_NAME" -- microk8s kubectl describe pods -l app=my-ag-ui-app 2>/dev/null | grep -q "Readiness probe failed"; then
                log "WARNING: Readiness probe failing - application may not be ready to serve traffic"
            fi
            
            if multipass exec "$VM_NAME" -- microk8s kubectl describe pods -l app=my-ag-ui-app 2>/dev/null | grep -q "Liveness probe failed"; then
                log "WARNING: Liveness probe failing - pod may be restarting"
            fi
        fi
    else
        log "Unable to get pod probe status, trying basic status check..."
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    if [ $PROBE_WAIT_ATTEMPT -eq $MAX_PROBE_WAIT_ATTEMPTS ]; then
        log "ERROR: Probes did not pass within $MAX_PROBE_WAIT_ATTEMPTS attempts"
        
        log "Final pod status:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
        
        log "Pod events for probe debugging:"
        multipass exec "$VM_NAME" -- microk8s kubectl describe pods -l app=my-ag-ui-app 2>/dev/null | grep -A 20 -B 5 "Events:" | tee -a "$LOG_FILE" || true
        
        log "Probe status details:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.containerStatuses[0].lastState}' 2>/dev/null | tee -a "$LOG_FILE" || true
        
        handle_secrets_error 127 "Pod probes did not pass within timeout" \
            "Check application logs: multipass exec '$VM_NAME' -- microk8s kubectl logs -l app=my-ag-ui-app. Verify /health endpoint is working correctly."
    fi
    
    sleep 5
    PROBE_WAIT_ATTEMPT=$((PROBE_WAIT_ATTEMPT + 1))
done

log "✓ Pod readiness and liveness probes verification completed successfully"

# Apply service manifest
log "Applying service manifest..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f k8s/service.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 107 "Failed to apply service manifest" \
        "Check the service file: k8s/service.yaml. Ensure it references the correct deployment."
fi
log "Service manifest applied successfully"

# Apply ingress manifest
log "Applying ingress manifest..."
if ! multipass exec "$VM_NAME" -- microk8s kubectl apply -f k8s/ingress.yaml 2>&1 | tee -a "$LOG_FILE"; then
    handle_secrets_error 108 "Failed to apply ingress manifest" \
        "Check the ingress file: k8s/ingress.yaml. Ensure ingress controller is enabled in microk8s."
fi
log "Ingress manifest applied successfully"

# Wait for deployment to be ready
log "Waiting for deployment to be ready..."
MAX_ATTEMPTS=20
ATTEMPT=1
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    log "Checking deployment status... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
    
    # Check if deployment is ready
    DEPLOYMENT_READY=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    
    if [ "$DEPLOYMENT_READY" = "1" ]; then
        log "Deployment is ready"
        break
    else
        log "Deployment not ready yet... (ready replicas: $DEPLOYMENT_READY)"
        
        # Get pod status for debugging
        log "Pod status:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        handle_secrets_error 109 "Deployment did not become ready within $MAX_ATTEMPTS attempts" \
            "Check pod logs: microk8s kubectl logs -l app=my-ag-ui-app. Check pod status: microk8s kubectl get pods -l app=my-ag-ui-app"
    fi
    
    sleep 10
    ATTEMPT=$((ATTEMPT + 1))
done

# 5.8 Wait for pods to be ready
log "Verifying all pods are ready..."
POD_STATUS=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo "Unknown")
log "Pod status: $POD_STATUS"

if ! multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[*].status.containerStatuses[*].ready}' 2>&1 | grep -q "true"; then
    log "WARNING: Some pods may not be ready"
    log "Detailed pod status:"
    multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>&1 | tee -a "$LOG_FILE"
else
    log "All pods are ready"
fi

# 5.9 Verify deployment status
log "Verifying deployment status..."
DEPLOYMENT_STATUS=$(multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app -o jsonpath='{.status.conditions[?(@.type=="Available")}.status}' 2>/dev/null || echo "Unknown")
log "Deployment status: $DEPLOYMENT_STATUS"

# Get deployment details
log "Deployment details:"
multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app 2>&1 | tee -a "$LOG_FILE"

# 5.10 Verify application is accessible via ingress
# 6.2 Get ingress endpoint URL/IP
log "Verifying application accessibility via ingress..."

# Get VM IP address (primary ingress endpoint)
VM_IP=$(multipass info "$VM_NAME" | grep -E "IPv4:" | awk '{print $2}' | cut -d',' -f1 | head -n1 || echo "")
if [ -z "$VM_IP" ]; then
    log "ERROR: Failed to get VM IP address"
    VM_IP="127.0.0.1"  # fallback for testing
    log "Using fallback VM IP: $VM_IP"
fi
log "VM IP address: $VM_IP"

# Get ingress details
INGRESS_DETAILS=$(multipass exec "$VM_NAME" -- microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "Unknown")
log "Ingress host: $INGRESS_DETAILS"

# Get ingress controller service details
INGRESS_CONTROLLER_SVC=$(multipass exec "$VM_NAME" -- microk8s kubectl get svc -n ingress nginx-ingress-controller -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}' 2>/dev/null || echo "")
if [ -z "$INGRESS_CONTROLLER_SVC" ]; then
    # Try alternative service name for newer microk8s versions
    INGRESS_CONTROLLER_SVC=$(multipass exec "$VM_NAME" -- microk8s kubectl get svc -n ingress nginx-ingress-microk8s-controller -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}' 2>/dev/null || echo "")
fi

if [ -z "$INGRESS_CONTROLLER_SVC" ]; then
    log "WARNING: Could not get ingress controller node port, using default port 80"
    INGRESS_PORT="80"
else
    INGRESS_PORT="$INGRESS_CONTROLLER_SVC"
    log "Ingress controller node port: $INGRESS_PORT"
fi

# Check if ingress has an address assigned (for cloud environments)
INGRESS_IP=$(multipass exec "$VM_NAME" -- microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
INGRESS_HOSTNAME=$(multipass exec "$VM_NAME" -- microk8s kubectl get ingress my-ag-ui-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

# Determine the accessible URL
if [ -n "$INGRESS_IP" ]; then
    ACCESS_URL="http://$INGRESS_IP"
    log "Cloud LoadBalancer IP detected: $INGRESS_IP"
    log "Application accessible at: $ACCESS_URL"
elif [ -n "$INGRESS_HOSTNAME" ]; then
    ACCESS_URL="http://$INGRESS_HOSTNAME"
    log "Cloud LoadBalancer hostname detected: $INGRESS_HOSTNAME"
    log "Application accessible at: $ACCESS_URL"
else
    # Local microk8s deployment - use VM IP and ingress port
    if [ "$INGRESS_PORT" = "80" ]; then
        ACCESS_URL="http://$VM_IP"
    else
        ACCESS_URL="http://$VM_IP:$INGRESS_PORT"
    fi
    log "Local microk8s deployment detected"
    log "Application accessible at: $ACCESS_URL"
fi

# Store access URL for later use
echo "$ACCESS_URL" > /tmp/my-ag-ui-app-access-url.txt
log "Access URL saved to /tmp/my-ag-ui-app-access-url.txt"

# Test basic connectivity to the VM
log "Testing basic connectivity to VM..."
if ping -c 1 -W "$NETWORK_CONNECTIVITY_TIMEOUT" "$VM_IP" >/dev/null 2>&1; then
    log "VM is reachable at $VM_IP"
else
    log "WARNING: VM is not reachable at $VM_IP"
fi

# Test application accessibility (basic check)
log "Testing application accessibility..."

# First test from within the cluster (pod to pod)
if multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.podIP}' 2>/dev/null | grep -q "."; then
    POD_IP=$(multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app -o jsonpath='{.items[0].status.podIP}' 2>/dev/null)
    log "Application pod IP: $POD_IP"
    
    # Try to access the application from within the cluster
    if multipass exec "$VM_NAME" -- microk8s kubectl run temp-curl --image=curlimages/curl --rm -it --restart=Never -- curl -s --connect-timeout "$NETWORK_CONNECTIVITY_TIMEOUT" "http://$POD_IP:3000/health" >/dev/null 2>&1; then
        log "✓ Application internal health check passed"
    else
        log "WARNING: Application internal health check failed"
    fi
else
    log "Unable to determine pod IP for internal accessibility test"
fi

# Test ingress endpoint accessibility (external access)
log "Testing ingress endpoint accessibility..."
if command_exists curl; then
    log "Testing external access to: $ACCESS_URL"
    
    # Wait a few seconds for ingress to be ready
    log "Waiting 10 seconds for ingress to be fully ready..."
    sleep 10
    
    # Test the ingress endpoint
    if curl -s --connect-timeout "$NETWORK_CONNECTIVITY_TIMEOUT" --max-time 30 "$ACCESS_URL" >/dev/null 2>&1; then
        log "✓ Ingress endpoint is accessible: $ACCESS_URL"
        
        # Test with the configured hostname if different from IP
        if [[ "$ACCESS_URL" != *"my-ag-ui-app.local"* ]] && [ -n "$INGRESS_DETAILS" ] && [ "$INGRESS_DETAILS" != "Unknown" ]; then
            # Try with hostname (may require /etc/hosts modification)
            log "NOTE: For hostname-based access ($INGRESS_DETAILS), you may need to add this to your /etc/hosts file:"
            log "  $VM_IP    $INGRESS_DETAILS"
        fi
    else
        log "WARNING: Ingress endpoint not immediately accessible: $ACCESS_URL"
        log "This is normal - ingress may take a few minutes to be fully ready"
        log "To test manually: curl $ACCESS_URL"
    fi
else
    log "curl command not found, skipping external accessibility test"
    log "To test manually: curl $ACCESS_URL"
fi

log "Kubernetes deployment phase completed successfully"
log "Application should be accessible via ingress (may take a few minutes for ingress to be fully ready)"

# Provide access instructions
log "=== APPLICATION ACCESS INFORMATION ==="
log "Primary Access URL: $ACCESS_URL"
log ""
log "To access the application:"
log "1. Direct URL: $ACCESS_URL"
log "2. Check ingress status: microk8s kubectl get ingress my-ag-ui-app-ingress"
log "3. If using hostname-based routing, add this to your /etc/hosts file:"
if [ -n "$INGRESS_DETAILS" ] && [ "$INGRESS_DETAILS" != "Unknown" ]; then
    log "   $VM_IP    $INGRESS_DETAILS"
    log "4. Then access: http://$INGRESS_DETAILS"
fi
log ""
log "Troubleshooting:"
log "- If URL is not accessible, wait 2-3 minutes for ingress to be fully ready"
log "- Check ingress controller: microk8s kubectl get pods -n ingress"
log "- Check application logs: microk8s kubectl logs -l app=my-ag-ui-app"
log "=== END ACCESS INFORMATION ==="

# 6.3 Test application access via ingress (this was completed above)
log "Ingress endpoint URL/IP retrieval and testing completed"

log "Kubernetes secrets setup and deployment completed successfully"
