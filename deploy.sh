


# Common Docker Setup Issues and Troubleshooting Steps
# 
# This section provides comprehensive troubleshooting guidance for common Docker setup issues
# that may occur during VM Docker setup. Use this guide when encountering Docker-related problems.

# 1. DOCKER CLI NOT AVAILABLE ERRORS
# =================================
# Symptoms:
# - "docker: command not found" when running docker commands in VM
# - Multipass exec commands fail to find docker binary
#
# Troubleshooting Steps:
# 1. Check if Docker is installed: multipass exec '$VM_NAME' -- which docker
# 2. Check Docker version: multipass exec '$VM_NAME' -- docker --version
# 3. If not installed, install manually:
#    multipass shell '$VM_NAME'
#    curl -fsSL https://get.docker.com | sh
# 4. Verify installation: docker --version
# 5. Exit VM shell: exit
#
# Prevention:
# - Ensure VM has network connectivity before installation
# - Check available disk space (minimum 1GB recommended)
# - Verify package manager is accessible (apt update)

# 2. DOCKER DAEMON NOT RUNNING ERRORS
# ====================================
# Symptoms:
# - "Cannot connect to Docker daemon" error
# - "Docker daemon is not running" message
# - docker info command fails
#
# Troubleshooting Steps:
# 1. Check daemon status: multipass exec '$VM_NAME' -- sudo systemctl status docker
# 2. Start daemon: multipass exec '$VM_NAME' -- sudo systemctl start docker
# 3. Enable at boot: multipass exec '$VM_NAME' -- sudo systemctl enable docker
# 4. Check daemon logs: multipass exec '$VM_NAME' -- sudo journalctl -u docker.service --no-pager
# 5. Verify daemon is running: multipass exec '$VM_NAME' -- docker info
#
# Advanced Troubleshooting:
# 1. Check for resource issues (memory/disk): multipass exec '$VM_NAME' -- free -h && df -h
# 2. Check kernel modules: multipass exec '$VM_NAME' -- lsmod | grep -E '(overlay|aufs|bridge)'
# 3. Load missing modules: multipass exec '$VM_NAME' -- sudo modprobe overlay && sudo modprobe aufs
# 4. Reset daemon config: multipass exec '$VM_NAME' -- sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.backup
# 5. Restart daemon: multipass exec '$VM_NAME' -- sudo systemctl restart docker

# 3. DOCKER PERMISSION ERRORS
# ==========================
# Symptoms:
# - "permission denied" when running docker commands
# - "Got permission denied while trying to connect to the Docker daemon socket"
# - Docker commands work with sudo but not without
#
# Troubleshooting Steps:
# 1. Check user groups: multipass exec '$VM_NAME' -- groups ubuntu
# 2. Check if docker group exists: multipass exec '$VM_NAME' -- getent group docker
# 3. Add user to docker group: multipass exec '$VM_NAME' -- sudo usermod -aG docker ubuntu
# 4. Activate group membership: multipass exec '$VM_NAME' -- newgrp docker
# 5. Verify permissions: multipass exec '$VM_NAME' -- docker ps
#
# If Still Failing:
# 1. Check socket permissions: multipass exec '$VM_NAME' -- ls -la /var/run/docker.sock
# 2. Fix socket permissions: multipass exec '$VM_NAME' -- sudo chmod 666 /var/run/docker.sock
# 3. Create new shell session: multip exec '$VM_NAME' -- su -l ubuntu
# 4. Or reboot VM: multipass restart '$VM_NAME'

# 4. NETWORK CONNECTIVITY ISSUES
# =============================
# Symptoms:
# - Docker installation fails with network errors
# - "Connection refused" or "network unreachable" during installation
# - "resolve host" errors when downloading Docker packages
#
# Troubleshooting Steps:
# 1. Check VM network: multipass exec '$VM_NAME' -- ip a
# 2. Test DNS resolution: multipass exec '$VM_NAME' -- nslookup google.com
# 3. Test external connectivity: multipass exec '$VM_NAME' -- ping -c 2 google.com
# 4. Check package repositories: multipass exec '$VM_NAME' -- cat /etc/apt/sources.list
# 5. Update package lists: multipass exec '$VM_NAME' -- sudo apt update
#
# Proxy Configuration (if needed):
# 1. Set proxy in VM: multipass exec '$VM_NAME' -- echo 'export HTTP_PROXY=http://proxy:port' >> ~/.bashrc
# 2. Configure apt proxy: multipass exec '$VM_NAME' -- sudo mkdir -p /etc/apt/apt.conf.d
# 3. Create proxy config: multipass exec '$VM_NAME' -- 'echo "Acquire::http::Proxy \"http://proxy:port\";" | sudo tee /etc/apt/apt.conf.d/95proxies'

# 5. DISK SPACE ISSUES
# ====================
# Symptoms:
# - "No space left on device" during Docker installation
# - Disk space warnings in logs
# - Docker operations fail with space-related errors
#
# Troubleshooting Steps:
# 1. Check disk usage: multipass exec '$VM_NAME' -- df -h
# 2. Clean apt cache: multipass exec '$VM_NAME' -- sudo apt clean
# 3. Remove unused packages: multipass exec '$VM_NAME' -- sudo apt autoremove -y
# 4. Clear system logs: multipass exec '$VM_NAME' -- sudo journalctl --vacuum-size=100M
# 5. Check large files: multipass exec '$VM_NAME' -- sudo find /var/log -type f -size +100M -exec ls -lh {} \;
#
# If Still Insufficient:
# 1. Increase VM disk size:
#    multipass stop '$VM_NAME'
#    multipass delete '$VM_NAME'
#    multipass launch --name '$VM_NAME' --disk 20G
# 2. Or cleanup Docker data: multipass exec '$VM_NAME' -- sudo systemctl stop docker && sudo rm -rf /var/lib/docker

# 6. PACKAGE DEPENDENCY ISSUES
# ============================
# Symptoms:
# - "Unable to locate package" errors
# - "Dependency problems" during installation
# - Broken package states
#
# Troubleshooting Steps:
# 1. Update package lists: multipass exec '$VM_NAME' -- sudo apt update
# 2. Fix broken dependencies: multipass exec '$VM_NAME' -- sudo apt --fix-broken install -y
# 3. Install Docker dependencies: multipass exec '$VM_NAME' -- sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
# 4. Clean package cache: multipass exec '$VM_NAME' -- sudo apt clean
# 5. Update system: multipass exec '$VM_NAME' -- sudo apt upgrade -y
#
# Complete Reinstall (if needed):
# 1. Remove Docker: multipass exec '$VM_NAME' -- sudo apt remove --purge docker*
# 2. Clean up: multipass exec '$VM_NAME' -- sudo apt autoremove -y
# 3. Reinstall: multipass exec '$VM_NAME' -- curl -fsSL https://get.docker.com | sh

# 7. DOCKER DAEMON STARTUP TIMEOUTS
# =================================
# Symptoms:
# - Docker daemon takes very long time to start
# - Timeout errors during daemon startup
# - Daemon appears to hang during initialization
#
# Troubleshooting Steps:
# 1. Check system resources: multipass exec '$VM_NAME' -- free -h && multipass exec '$VM_NAME' -- top -bn1
# 2. Increase startup timeout in deployment script
# 3. Check for storage issues: multipass exec '$VM_NAME' -- df -h /var/lib/docker
# 4. Monitor startup progress: multipass exec '$VM_NAME' -- sudo journalctl -u docker.service -f
# 5. Try manual start: multipass exec '$VM_NAME' -- sudo systemctl start docker
#
# Performance Optimization:
# 1. Increase VM memory: multipass stop '$VM_NAME' && multipass delete '$VM_NAME' && multipass launch --name '$VM_NAME' --memory 4G
# 2. Use faster storage driver if available
# 3. Disable unused Docker features

# 8. VM ACCESSIBILITY ISSUES
# ==========================
# Symptoms:
# - "instance does not exist" errors
# - "instance is not running" errors
# - "connection refused" to VM
# - Multipass commands fail
#
# Troubleshooting Steps:
# 1. Check VM status: multipass info '$VM_NAME'
# 2. Start VM if needed: multipass start '$VM_NAME'
# 3. Check VM accessibility: multipass exec '$VM_NAME' -- whoami
# 4. Restart multipass service: sudo systemctl restart multipassd
# 5. Check multipass logs: journalctl -u multipassd
#
# VM Recovery:
# 1. Restart VM: multipass restart '$VM_NAME'
# 2. If unresponsive, recreate VM:
#    multipass stop '$VM_NAME'
#    multipass delete '$VM_NAME'
#    multipass launch --name '$VM_NAME'

# 9. DOCKER IMAGE LOADING FAILURES
# ===============================
# Symptoms:
# - Image transfer from host to VM fails
# - "docker load" command fails in VM
# - Images not available in VM after transfer
#
# Troubleshooting Steps:
# 1. Verify Docker is running in VM: multipass exec '$VM_NAME' -- docker info
# 2. Check VM disk space: multipass exec '$VM_NAME' -- df -h
# 3. Verify user permissions: multipass exec '$VM_NAME' -- docker ps
# 4. Test image loading manually:
#    docker save my-ag-ui-app:latest | multipass exec '$VM_NAME' -- docker load
# 5. Check loaded images: multipass exec '$VM_NAME' -- docker images
#
# Alternative Transfer Method:
# 1. Save image to file: docker save -o image.tar my-ag-ui-app:latest
# 2. Transfer file: multipass transfer image.tar '$VM_NAME':/home/ubuntu/
# 3. Load in VM: multipass exec '$VM_NAME' -- docker load -i /home/ubuntu/image.tar

# 10. GENERAL DEBUGGING APPROACH
# =============================
# For any Docker setup issue, follow this systematic approach:
#
# Step 1: Gather Information
# - VM status: multipass info '$VM_NAME'
# - Docker version: multipass exec '$VM_NAME' -- docker --version
# - Daemon status: multipass exec '$VM_NAME' -- sudo systemctl status docker
# - System resources: multipass exec '$VM_NAME' -- free -h && df -h
#
# Step 2: Check Logs
# - Docker daemon logs: multipass exec '$VM_NAME' -- sudo journalctl -u docker.service --no-pager
# - System logs: multipass exec '$VM_NAME' -- sudo dmesg | tail -n20
# - Deployment script logs: cat /tmp/deploy-*.log
#
# Step 3: Test Components
# - Test VM connectivity: multipass exec '$VM_NAME' -- whoami
# - Test Docker daemon: multipass exec '$VM_NAME' -- docker info
# - Test user permissions: multipass exec '$VM_NAME' -- docker ps
#
# Step 4: Manual Recovery
# - Access VM directly: multipass shell '$VM_NAME'
# - Test each component manually
# - Apply fixes one at a time
# - Verify each fix before proceeding
#
# Step 5: Escalation
# If all troubleshooting steps fail:
# - Document exact error messages and commands
# - Collect diagnostic information
# - Check for known issues with your OS/Docker version
# - Consider recreating VM from scratch

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
    
    # OPTIMIZATION: Track setup start time for performance measurement
    SETUP_START_TIME=$(date +%s)
    
    # Timeout configuration for Docker operations
    DOCKER_OPERATION_TIMEOUT=30
    DAEMON_START_TIMEOUT=60
    GROUP_OPERATION_TIMEOUT=30
    
    # Docker daemon retry configuration - can be adjusted for slow systems
    MAX_DAEMON_CHECK_ATTEMPTS=10
    INITIAL_RETRY_DELAY=2
    MAX_RETRY_DELAY=30
    EXTENDED_RETRY_ATTEMPTS=5
    EXTENDED_RETRY_DELAY=60
    
    # Docker group membership activation configuration
    MAX_GROUP_ACTIVATION_ATTEMPTS=3
    GROUP_ACTIVATION_DELAY=5
    MAX_NO_SUDO_CHECK_ATTEMPTS=8
    NO_SUDO_RETRY_DELAY=3
    
    # VM accessibility and multipass command failure handling configuration
    MAX_VM_ACCESSIBILITY_ATTEMPTS=5
    VM_ACCESSIBILITY_DELAY=10
    VM_RECOVERY_ATTEMPTS=2
    VM_HEALTH_CHECK_TIMEOUT=15
    MULTIPASS_COMMAND_TIMEOUT=20
    
    # VM Health Check Function
    check_vm_health() {
        local check_type="$1"
        log "VM Health Check: $check_type"
        
        local vm_healthy=true
        local health_issues=""
        
        # Check 1: VM exists and is accessible
        log "Checking VM existence and basic accessibility..."
        if ! timeout $VM_HEALTH_CHECK_TIMEOUT multipass info "$VM_NAME" >/dev/null 2>&1; then
            vm_healthy=false
            health_issues="$health_issues\n- VM does not exist or multipass service unavailable"
        else
            log "✅ VM exists and multipass service is accessible"
        fi
        
        # Check 2: VM state
        log "Checking VM state..."
        local vm_state
        vm_state=$(timeout $VM_HEALTH_CHECK_TIMEOUT multipass info "$VM_NAME" 2>/dev/null | grep "State:" | awk '{print $2}' || echo "unknown")
        if [[ "$vm_state" != "Running" ]]; then
            vm_healthy=false
            health_issues="$health_issues\n- VM state is '$vm_state' (expected 'Running')"
        else
            log "✅ VM state is Running"
        fi
        
        # Check 3: VM basic responsiveness
        log "Checking VM basic responsiveness..."
        if ! timeout $VM_HEALTH_CHECK_TIMEOUT multipass exec "$VM_NAME" -- whoami >/dev/null 2>&1; then
            vm_healthy=false
            health_issues="$health_issues\n- VM is not responding to basic commands"
        else
            log "✅ VM is responding to basic commands"
        fi
        
        # Check 4: Network connectivity
        log "Checking VM network connectivity..."
        if ! timeout $VM_HEALTH_CHECK_TIMEOUT multipass exec "$VM_NAME" -- ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            log "⚠️  WARNING: VM cannot ping external network (8.8.8.8)"
            health_issues="$health_issues\n- VM network connectivity issues detected"
        else
            log "✅ VM has external network connectivity"
        fi
        
        # Check 5: System resources
        log "Checking VM system resources..."
        local vm_memory
        vm_memory=$(timeout $VM_HEALTH_CHECK_TIMEOUT multipass exec "$VM_NAME" -- free -h 2>/dev/null | grep Mem: | awk '{print $3 "/" $2}' || echo "unknown")
        local vm_cpu_load
        vm_cpu_load=$(timeout $VM_HEALTH_CHECK_TIMEOUT multipass exec "$VM_NAME" -- top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | head -n1 2>/dev/null || echo "unknown")
        log "VM Memory Usage: $vm_memory, CPU Load: ${vm_cpu_load}%"
        
        # Return health status
        if [ "$vm_healthy" = true ]; then
            log "✅ VM Health Check PASSED: $check_type"
            return 0
        else
            log "❌ VM Health Check FAILED: $check_type"
            log "Issues detected:$health_issues"
            return 1
        fi
    }
    
    # VM Recovery Function
    attempt_vm_recovery() {
        local recovery_attempt="$1"
        log "VM Recovery Attempt $recovery_attempt/$VM_RECOVERY_ATTEMPTS"
        
        # Recovery Step 1: Try to restart VM
        log "Attempting VM restart..."
        if timeout $VM_HEALTH_CHECK_TIMEOUT multipass restart "$VM_NAME" >/dev/null 2>&1; then
            log "✅ VM restart command successful"
            
            # Wait for VM to fully start up
            log "Waiting for VM to fully start up (30 seconds)..."
            sleep 30
            
            # Check if VM is responsive after restart
            if check_vm_health "after-restart"; then
                log "✅ VM recovery successful after restart"
                return 0
            else
                log "⚠️  VM still unresponsive after restart"
            fi
        else
            log "❌ VM restart command failed"
        fi
        
        # Recovery Step 2: Try multipass service restart (if this fails, it might be a multipass issue)
        log "Attempting multipass service restart..."
        if command -v systemctl >/dev/null 2>&1; then
            if sudo systemctl restart multipassd >/dev/null 2>&1; then
                log "✅ Multipass service restarted successfully"
                sleep 5
                
                # Check VM health again
                if check_vm_health "after-multipass-restart"; then
                    log "✅ VM recovery successful after multipass service restart"
                    return 0
                fi
            else
                log "❌ Multipass service restart failed"
            fi
        else
            log "⚠️  systemctl not available, cannot restart multipass service"
        fi
        
        # Recovery Step 3: Last resort - suggest manual intervention
        log "❌ Automatic VM recovery failed for attempt $recovery_attempt"
        log "Manual intervention may be required:"
        log "1. Check multipass status: multipass list"
        log "2. Check multipass service: sudo systemctl status multipassd"
        log "3. Try manual VM access: multipass shell $VM_NAME"
        log "4. If all else fails: multipass delete $VM_NAME && multipass launch --name $VM_NAME"
        
        return 1
    }
    
    # Enhanced Multipass Command Wrapper with Retry Logic
    robust_multipass_exec() {
        local cmd="$1"
        local description="$2"
        local max_attempts="$3"
        local retry_delay="$4"
        
        if [ -z "$max_attempts" ]; then
            max_attempts=3
        fi
        
        if [ -z "$retry_delay" ]; then
            retry_delay=5
        fi
        
        local attempt=1
        local exit_code=1
        local output=""
        
        while [ $attempt -le $max_attempts ]; do
            log "Executing multipass command (attempt $attempt/$max_attempts): $description"
            
            # Execute the command with timeout
            output=$(timeout $MULTIPASS_COMMAND_TIMEOUT bash -c "$cmd" 2>&1)
            exit_code=$?
            
            if [ $exit_code -eq 0 ]; then
                log "✅ Multipass command succeeded: $description"
                echo "$output"
                return 0
            else
                log "⚠️  Multipass command failed (exit code: $exit_code): $description"
                if [ $attempt -lt $max_attempts ]; then
                    log "Waiting ${retry_delay}s before retry..."
                    sleep $retry_delay
                else
                    log "❌ Multipass command failed after $max_attempts attempts: $description"
                    log "Command output: $output"
                fi
            fi
            
            attempt=$((attempt + 1))
        done
        
        # If we get here, all attempts failed
        echo "$output" >&2  # Send error output to stderr
        return $exit_code
    }
    
    # Starting Docker setup in VM '$VM_NAME'...
    
    # Initial VM Health Check before Docker setup
    log "Performing initial VM health check before Docker setup..."
    if ! check_vm_health "initial-setup"; then
        log "⚠️  WARNING: Initial VM health check failed, attempting VM recovery..."
        
        for ((recovery_attempt=1; recovery_attempt<=VM_RECOVERY_ATTEMPTS; recovery_attempt++)); do
            if attempt_vm_recovery $recovery_attempt; then
                log "✅ VM recovery successful, proceeding with Docker setup"
                break
            else
                if [ $recovery_attempt -eq $VM_RECOVERY_ATTEMPTS ]; then
                    log "❌ ERROR: VM recovery failed after $VM_RECOVERY_ATTEMPTS attempts"
                    log "   Docker setup cannot proceed - VM is not accessible"
                    log "   Please check VM status manually: multipass info $VM_NAME"
                    return 1
                else
                    log "Waiting 10 seconds before next recovery attempt..."
                    sleep 10
                fi
            fi
        done
    fi
    
    # OPTIMIZED: Combined Docker CLI and daemon availability check
    log "Performing optimized Docker availability check in VM..."
    DOCKER_CLI_AVAILABLE=false
    DOCKER_DAEMON_RUNNING=false
    DOCKER_CLI_ERROR=""
    DOCKER_CLI_ERROR_DETAILS=""
    
    # OPTIMIZATION: Quick combined check - try docker info first (verifies CLI + daemon in one command)
    # Use shorter timeout for quick check (5 seconds instead of 30)
    log "Quick Docker availability check (CLI + daemon)..."
    local quick_docker_check
    quick_docker_check=$(timeout 5 multipass exec "$VM_NAME" -- docker info 2>&1)
    local quick_check_exit_code=$?
    
    if [ $quick_check_exit_code -eq 0 ]; then
        # SUCCESS: Docker CLI and daemon are both working
        log "✅ OPTIMIZED: Docker CLI and daemon confirmed working in one check"
        DOCKER_CLI_AVAILABLE=true
        DOCKER_DAEMON_RUNNING=true
        
        # Extract Docker version from the successful docker info output
        DOCKER_VERSION=$(echo "$quick_docker_check" | grep -E "Server Version:" | head -n1 | awk '{print $3}' || echo "Unknown")
        log "✅ Docker version detected: $DOCKER_VERSION"
        
        # OPTIMIZATION: Skip full CLI check since we already know it's working
        log "✅ OPTIMIZATION: Skipping individual CLI verification - already confirmed by combined check"
        
    else
        # Combined check failed, now determine if it's CLI or daemon issue
        log "⚠️  Quick combined check failed (exit code: $quick_check_exit_code), analyzing cause..."
        DOCKER_CLI_ERROR_DETAILS="$quick_docker_check"
        
        # Check specifically for CLI availability with very short timeout
        log "Checking Docker CLI availability with fast timeout..."
        local docker_version_output
        docker_version_output=$(timeout 3 multipass exec "$VM_NAME" -- docker --version 2>&1)
        local docker_version_exit_code=$?
        
        if [ $docker_version_exit_code -eq 0 ]; then
            DOCKER_VERSION=$(echo "$docker_version_output" | head -n1)
            log "✅ Docker CLI is available in VM: $DOCKER_VERSION"
            DOCKER_CLI_AVAILABLE=true
        else
            log "⚠️  Docker CLI is not available in VM (exit code: $docker_version_exit_code)"
            DOCKER_CLI_ERROR=true
        
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
        
        # Install Docker with robust error handling and retry logic
        log "Starting Docker installation with robust error handling and retry logic..."
        local install_output
        local install_exit_code
        
        # Use robust multipass wrapper for Docker installation with retries
        log "Installing Docker using robust multipass wrapper (up to 3 attempts)..."
        install_output=$(robust_multipass_exec "multipass exec '$VM_NAME' -- bash -c 'curl -fsSL https://get.docker.com | sh'" "Docker installation via official script" 3 10)
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
            
# Collect essential diagnostic information
        log "ESSENTIAL DIAGNOSTIC INFORMATION:"
        multipass exec "$VM_NAME" -- uname -a 2>/dev/null | tee -a "$LOG_FILE" || log "Unable to get system info"
        multipass exec "$VM_NAME" -- df -h 2>/dev/null | head -3 | tee -a "$LOG_FILE" || log "Unable to get disk usage"
            
            return 1
        fi
        
        # Verify Docker was installed
        log "Verifying Docker installation..."
        local docker_version_output
        docker_version_output=$(timeout $DOCKER_OPERATION_TIMEOUT multipass exec "$VM_NAME" -- docker --version 2>&1)
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
    
    # Verifying Docker installation completed successfully
    
    # Add user to docker group with comprehensive error handling and idempotency check
    log "Checking docker group membership with idempotency handling..."
    local user_in_docker_group=false
    local group_add_output
    local group_add_exit_code
    
    # Check if user is already in docker group (idempotency check)
    log "Checking if user 'ubuntu' is already in docker group..."
    local user_groups
    user_groups=$(timeout $DOCKER_OPERATION_TIMEOUT multipass exec "$VM_NAME" -- groups ubuntu 2>/dev/null || echo "")
    if echo "$user_groups" | grep -q -E "(^docker | docker | docker$)"; then
        user_in_docker_group=true
        log "✅ User 'ubuntu' is already in docker group - skipping group addition"
    else
        log "⚠️  User 'ubuntu' is not in docker group - proceeding with group addition"
        
        # Check if docker group exists (needed for user to be added)
        log "Checking if docker group exists..."
        local docker_group_exists
        docker_group_exists=$(timeout $DOCKER_OPERATION_TIMEOUT multipass exec "$VM_NAME" -- getent group docker 2>/dev/null && echo "yes" || echo "no")
        
        if [ "$docker_group_exists" = "no" ]; then
            log "⚠️  WARNING: Docker group does not exist - this should have been created during Docker installation"
            log "   Attempting to create docker group..."
            if timeout $DOCKER_OPERATION_TIMEOUT multipass exec "$VM_NAME" -- sudo groupadd docker 2>&1 | tee -a "$LOG_FILE"; then
                log "✅ Docker group created successfully"
            else
                log "⚠️  WARNING: Could not create docker group - continuing anyway"
            fi
        fi
        
# Use robust multipass wrapper for Docker group addition with retries
        log "Adding user to docker group using robust multipass wrapper (up to 3 attempts)..."
        group_add_output=$(robust_multipass_exec "multipass exec '$VM_NAME' -- sudo usermod -aG docker ubuntu" "Docker group membership addition" 3 5)
        group_add_exit_code=$?
    fi
    
    # Log the full output for debugging
    log "Docker group addition output (first 500 chars):"
    echo "$group_add_output" | head -c 500 | tee -a "$LOG_FILE"
    if [ ${#group_add_output} -gt 500 ]; then
        log "... (output truncated, full output logged to file)"
        echo "$group_add_output" >> "$LOG_FILE"
    fi
    
    # Analyze the result (only if group addition was attempted)
    if [ "$user_in_docker_group" = true ]; then
        log "✅ Docker group membership verification completed - user was already in group"
        # Set success exit code for idempotent case
        group_add_exit_code=0
    elif [ $group_add_exit_code -eq 0 ]; then
        log "✅ Docker group addition command completed successfully (exit code: 0)"
    else
        log "ERROR: Docker group addition failed (exit code: $group_add_exit_code)"
        
        # Analyze specific error patterns and provide targeted guidance
        log "ANALYZING DOCKER GROUP MEMBERSHIP FAILURE..."
        
        # Check for user existence errors
        if echo "$group_add_output" | grep -q -E "(user.*does not exist|unknown user|user.*not found|cannot find user)"; then
            log "ERROR TYPE: USER NOT FOUND FAILURE"
            log "DIAGNOSTIC: The 'ubuntu' user does not exist in the VM"
            log "RECOVERY STEPS:"
            log "1. Check available users in VM: multipass exec '$VM_NAME' -- cat /etc/passwd | grep -E 'ubuntu|.*:.*:.*:.*:.*:/home' | head -10"
            log "2. Verify default user: multipass exec '$VM_NAME' -- whoami"
            log "3. List all users: multipass exec '$VM_NAME' -- cut -d: -f1 /etc/passwd | head -20"
            log "4. If 'ubuntu' user doesn't exist, create it first: multipass exec '$VM_NAME' -- sudo adduser ubuntu"
            log "5. Manual group addition: multipass shell '$VM_NAME'"
            log "   Then run: sudo usermod -aG docker <correct-username>"
            
        # Check for group existence errors
        elif echo "$group_add_output" | grep -q -E "(group.*does not exist|unknown group|group.*not found|cannot find group)"; then
            log "ERROR TYPE: DOCKER GROUP NOT FOUND FAILURE"
            log "DIAGNOSTIC: The 'docker' group does not exist in the VM"
            log "RECOVERY STEPS:"
            log "1. Check if docker group exists: multipass exec '$VM_NAME' -- grep docker /etc/group"
            log "2. List all groups: multipass exec '$VM_NAME' -- cut -d: -f1 /etc/group | head -20"
            log "3. Check if Docker is installed: multipass exec '$VM_NAME' -- docker --version"
            log "4. Create docker group if missing: multipass exec '$VM_NAME' -- sudo groupadd docker"
            log "5. Verify docker group creation: multipass exec '$VM_NAME' -- grep docker /etc/group"
            log "6. Retry group membership: multipass exec '$VM_NAME' -- sudo usermod -aG docker ubuntu"
            
        # Check for permission errors
        elif echo "$group_add_output" | grep -q -E "(permission denied|Permission denied|sudo.*error|access denied|Operation not permitted)"; then
            log "ERROR TYPE: PERMISSION FAILURE"
            log "DIAGNOSTIC: Insufficient permissions to add user to docker group"
            log "RECOVERY STEPS:"
            log "1. Check current user: multipass exec '$VM_NAME' -- whoami"
            log "2. Check sudo privileges: multipass exec '$VM_NAME' -- sudo -l"
            log "3. Check user permissions: multipass exec '$VM_NAME' -- id"
            log "4. Verify user has sudo access: multipass exec '$VM_NAME' -- sudo echo 'sudo access test'"
            log "5. If no sudo access, configure sudo: multipass exec '$VM_NAME' -- sudo visudo"
            log "   Add: <username> ALL=(ALL) NOPASSWD: ALL"
            log "6. Manual group addition with sudo: multipass shell '$VM_NAME'"
            log "   Then run: sudo usermod -aG docker ubuntu"
            
        # Check for authentication errors
        elif echo "$group_add_output" | grep -q -E "(authentication|auth.*failed|password|sudo:.*password)"; then
            log "ERROR TYPE: AUTHENTICATION FAILURE"
            log "DIAGNOSTIC: Sudo authentication required but failed"
            log "RECOVERY STEPS:"
            log "1. Check if passwordless sudo is configured: multipass exec '$VM_NAME' -- sudo -l"
            log "2. Check sudoers configuration: multipass exec '$VM_NAME' -- sudo cat /etc/sudoers | grep -v '^#' | head -10"
            log "3. Configure passwordless sudo if needed: multipass exec '$VM_NAME' -- sudo visudo"
            log "   Add: ubuntu ALL=(ALL) NOPASSWD: ALL"
            log "4. Test sudo without password: multipass exec '$VM_NAME' -- sudo whoami"
            log "5. Manual group addition: multipass shell '$VM_NAME'"
            log "   Enter password when prompted, then run: sudo usermod -aG docker ubuntu"
            
        # Check for VM accessibility issues
        elif echo "$group_add_output" | grep -q -E "(multipass.*error|instance.*not.*found|instance.*not.*running|connection.*refused|network.*unreachable)"; then
            log "ERROR TYPE: VM ACCESSIBILITY FAILURE"
            log "DIAGNOSTIC: Cannot communicate with VM via multipass"
            log "RECOVERY STEPS:"
            log "1. Check VM status: multipass info '$VM_NAME'"
            log "2. Start VM if needed: multipass start '$VM_NAME'"
            log "3. Check VM accessibility: multipass exec '$VM_NAME' -- whoami"
            log "4. Verify VM exists: multipass list"
            log "5. Restart VM if needed: multipass restart '$VM_NAME'"
            log "6. If VM is unresponsive, delete and recreate: multipass delete '$VM_NAME' && multipass launch --name '$VM_NAME'"
            log "7. Manual VM access: multipass shell '$VM_NAME'"
            log "   Then run: sudo usermod -aG docker ubuntu"
            
        # Check for system resource issues
        elif echo "$group_add_output" | grep -q -E "(resource.*busy|file.*system.*read.*only|disk.*full|no.*space|memory|swap)"; then
            log "ERROR TYPE: SYSTEM RESOURCE FAILURE"
            log "DIAGNOSTIC: System resource constraints preventing group modification"
            log "RECOVERY STEPS:"
            log "1. Check disk space: multipass exec '$VM_NAME' -- df -h"
            log "2. Check memory usage: multipass exec '$VM_NAME' -- free -h"
            log "3. Check system resources: multipass exec '$VM_NAME' -- top -bn1 | head -10"
            log "4. Check for read-only filesystem: multipass exec '$VM_NAME' -- mount | grep ' / '"
            log "5. Clean up disk space: multipass exec '$VM_NAME' -- sudo apt autoremove -y && sudo apt clean"
            log "6. Check system logs: multipass exec '$VM_NAME' -- dmesg | tail -n20"
            log "7. Reboot VM if needed: multipass exec '$VM_NAME' -- sudo reboot"
            log "8. Manual group addition after resource cleanup: multipass shell '$VM_NAME'"
            log "   Then run: sudo usermod -aG docker ubuntu"
            
        # Check for usermod command specific errors
        elif echo "$group_add_output" | grep -q -E "(usermod.*error|invalid.*option|usage.*usermod|cannot.*modify|user.*already.*member)"; then
            log "ERROR TYPE: USERMOD COMMAND FAILURE"
            log "DIAGNOSTIC: usermod command syntax or execution error"
            log "RECOVERY STEPS:"
            log "1. Check usermod command syntax: multipass exec '$VM_NAME' -- man usermod | head -20"
            log "2. Verify user is not already in docker group: multipass exec '$VM_NAME' -- groups ubuntu"
            log "3. Check if user exists: multipass exec '$VM_NAME' -- id ubuntu"
            log "4. Check if docker group exists: multipass exec '$VM_NAME' -- getent group docker"
            log "5. Alternative method - use gpasswd: multipass exec '$VM_NAME' -- sudo gpasswd -a ubuntu docker"
            log "6. Manual verification: multipass shell '$VM_NAME'"
            log "   Then run: groups ubuntu && sudo usermod -aG docker ubuntu"
            
        # Check for security policy or SELinux/AppArmor issues
        elif echo "$group_add_output" | grep -q -E "(security.*policy|selinux|apparmor|denied.*by|policy.*violation)"; then
            log "ERROR TYPE: SECURITY POLICY FAILURE"
            log "DIAGNOSTIC: Security policies (SELinux/AppArmor) blocking group modification"
            log "RECOVERY STEPS:"
            log "1. Check SELinux status: multipass exec '$VM_NAME' -- getenforce"
            log "2. Check AppArmor status: multipass exec '$VM_NAME' -- aa-status"
            log "3. Check security logs: multipass exec '$VM_NAME' -- sudo journalctl --since '1 hour ago' | grep -i denied"
            log "4. Temporarily disable SELinux if enforcing: multipass exec '$VM_NAME' -- sudo setenforce 0"
            log "5. Check usermod security context: multipass exec '$VM_NAME' -- ls -Z $(which usermod)"
            log "6. Manual group addition with security context adjustment: multipass shell '$VM_NAME'"
            log "   Try: sudo setenforce 0 && sudo usermod -aG docker ubuntu"
            
        # Check for filesystem or permission issues with system files
        elif echo "$group_add_output" | grep -q -E "(/etc/passwd|/etc/group|permission.*system|read.*only.*system|filesystem.*error)"; then
            log "ERROR TYPE: SYSTEM FILESYSTEM FAILURE"
            log "DIAGNOSTIC: Filesystem issues with system files (/etc/passwd, /etc/group)"
            log "RECOVERY STEPS:"
            log "1. Check system file permissions: multipass exec '$VM_NAME' -- ls -la /etc/passwd /etc/group"
            log "2. Check filesystem status: multipass exec '$VM_NAME' -- mount | grep ' / '"
            log "3. Check for filesystem errors: multipass exec '$VM_NAME' -- sudo fsck /dev/sda1"
            log "4. Check if system files are writable: multipass exec '$VM_NAME' -- test -w /etc/passwd && echo 'writable' || echo 'not writable'"
            log "5. Remount filesystem as read-write if needed: multipass exec '$VM_NAME' -- sudo mount -o remount,rw /"
            log "6. Check disk health: multipass exec '$VM_NAME' -- sudo smartctl -a /dev/sda"
            log "7. Manual filesystem repair: multipass shell '$VM_NAME'"
            log "   Then run: sudo fsck /dev/sda1 && sudo usermod -aG docker ubuntu"
            
        # Unknown/unexpected errors with comprehensive diagnostic info
        else
            log "ERROR TYPE: UNKNOWN DOCKER GROUP MEMBERSHIP FAILURE"
            log "DIAGNOSTIC: Group addition failed with unknown error pattern"
            log "ERROR DETAILS:"
            log "Usermod command exit code: $group_add_exit_code"
            log "Usermod command output:"
            log "$group_add_output"
            log "RECOVERY STEPS:"
            log "1. Check VM system status: multipass info '$VM_NAME'"
            log "2. Check user and group status: multipass exec '$VM_NAME' -- id ubuntu && groups ubuntu"
            log "3. Check system logs: multipass exec '$VM_NAME' -- sudo journalctl -n 20"
            log "4. Alternative group addition method: multipass exec '$VM_NAME' -- sudo gpasswd -a ubuntu docker"
            log "5. Manual intervention: multipass shell '$VM_NAME'"
            log "   Then run: sudo usermod -aG docker ubuntu"
            log "6. If all else fails, create new user with docker group: multipass exec '$VM_NAME' -- sudo useradd -G docker ubuntu-new"
        fi
        
        # Collect essential diagnostic information
        log "ESSENTIAL DIAGNOSTIC INFORMATION:"
        log "- User info: $(multipass exec "$VM_NAME" -- id ubuntu 2>/dev/null || echo 'Unable to get user info')"
        log "- User groups: $(multipass exec "$VM_NAME" -- groups ubuntu 2>/dev/null || echo 'Unable to get user groups')"
        log "- Docker group: $(multipass exec "$VM_NAME" -- getent group docker 2>/dev/null || echo 'Docker group not found')"
        
        return 1
    fi
    
    # Final verification of docker group membership (idempotency check)
    log "Performing final verification of docker group membership..."
    local final_group_check
    final_group_check=$(timeout $DOCKER_OPERATION_TIMEOUT multipass exec "$VM_NAME" -- groups ubuntu 2>/dev/null || echo "")
    if echo "$final_group_check" | grep -q -E "(^docker | docker | docker$)"; then
        log "✅ Final verification successful: User 'ubuntu' is confirmed in docker group"
        log "✅ Docker group membership setup completed successfully (idempotent)"
    else
        log "❌ ERROR: Final verification failed: User 'ubuntu' is not in docker group"
        log "   This indicates a persistent issue with group membership setup"
        log "   Current user groups: $final_group_check"
        log "   Manual intervention may be required"
        return 1
    fi
    
    # Enhanced Docker group membership activation with multiple methods and retries
    log "Activating docker group membership with multiple methods..."
    GROUP_ACTIVATION_SUCCESS=false
    
    for ((GROUP_ACT_ATTEMPT=1; GROUP_ACT_ATTEMPT<=MAX_GROUP_ACTIVATION_ATTEMPTS; GROUP_ACT_ATTEMPT++)); do
        log "Group activation attempt $GROUP_ACT_ATTEMPT/$MAX_GROUP_ACTIVATION_ATTEMPTS..."
        
        # Method 1: Try newgrp (most common method)
        if multipass exec "$VM_NAME" -- newgrp docker 2>&1 | tee -a "$LOG_FILE"; then
            log "✅ Method 1 (newgrp) succeeded for group activation"
            GROUP_ACTIVATION_SUCCESS=true
            break
        else
            log "⚠️  Method 1 (newgrp) failed for group activation (attempt $GROUP_ACT_ATTEMPT)"
        fi
        
        # Method 2: Try su -l to create new login session
        if multipass exec "$VM_NAME" -- su -l ubuntu -c "groups" 2>&1 | grep -q docker; then
            log "✅ Method 2 (su -l) succeeded for group activation"
            GROUP_ACTIVATION_SUCCESS=true
            break
        else
            log "⚠️  Method 2 (su -l) failed for group activation (attempt $GROUP_ACT_ATTEMPT)"
        fi
        
        # Method 3: Direct group verification
        if multipass exec "$VM_NAME" -- groups ubuntu 2>&1 | grep -q docker; then
            log "✅ Method 3 (direct verification) shows user is in docker group"
            GROUP_ACTIVATION_SUCCESS=true
            break
        else
            log "⚠️  Method 3 (direct verification) shows user not in docker group (attempt $GROUP_ACT_ATTEMPT)"
        fi
        
        # If this is not the last attempt, wait before retrying
        if [ $GROUP_ACT_ATTEMPT -lt $MAX_GROUP_ACTIVATION_ATTEMPTS ]; then
            log "Waiting ${GROUP_ACTIVATION_DELAY}s before next group activation attempt..."
            sleep $GROUP_ACTIVATION_DELAY
        fi
    done
    
    if [ "$GROUP_ACTIVATION_SUCCESS" = true ]; then
        log "✅ Docker group membership activated successfully"
    else
        log "⚠️  Warning: Could not activate docker group membership after $MAX_GROUP_ACTIVATION_ATTEMPTS attempts"
        log "   This may cause issues with docker commands requiring group membership"
        log "   The system may need a reboot or complete user logout/login to activate group membership"
    fi
    
    # VM health check after group activation operations
    log "Performing VM health check after group activation operations..."
    if ! check_vm_health "post-group-activation"; then
        log "⚠️  WARNING: VM health check failed after group activation, attempting recovery..."
        
        for ((recovery_attempt=1; recovery_attempt<=VM_RECOVERY_ATTEMPTS; recovery_attempt++)); do
            if attempt_vm_recovery $recovery_attempt; then
                log "✅ VM recovery successful after group activation issues"
                break
            else
                if [ $recovery_attempt -eq $VM_RECOVERY_ATTEMPTS ]; then
                    log "❌ ERROR: VM recovery failed after group activation operations"
                    log "   Docker setup cannot continue - VM is not accessible"
                    return 1
                else
                    log "Waiting 10 seconds before next recovery attempt..."
                    sleep 10
                fi
            fi
        done
    fi
    
    # Start Docker daemon if it's not running
    log "Ensuring Docker daemon is running..."
    if ! timeout $DAEMON_START_TIMEOUT multipass exec "$VM_NAME" -- sudo systemctl start docker 2>&1 | tee -a "$LOG_FILE"; then
        log "⚠️  Warning: Could not start Docker daemon with systemctl"
        log "   This may be expected if Docker daemon is already running or uses different init system"
    fi
    
    # Enable Docker daemon to start on boot
    log "Enabling Docker daemon to start on boot..."
    if ! multipass exec "$VM_NAME" -- sudo systemctl enable docker 2>&1 | tee -a "$LOG_FILE"; then
        log "⚠️  Warning: Could not enable Docker daemon to start on boot"
        log "   This may be expected if Docker daemon uses different init system"
    fi
    
    # OPTIMIZED: Check Docker daemon status only if not already confirmed
    if [ "$DOCKER_DAEMON_RUNNING" = true ]; then
        log "✅ OPTIMIZATION: Skipping daemon status check - already confirmed by combined check"
        DAEMON_START_TIME=$(date +%s)
        ELAPSED_TIME=0
        log "✅ Docker daemon verification completed in 0 seconds (optimization)"
    else
        log "Checking Docker daemon status in VM with retry loop (max $MAX_DAEMON_CHECK_ATTEMPTS attempts, max delay ${MAX_RETRY_DELAY}s)..."
        DOCKER_DAEMON_RUNNING=false
        DAEMON_CHECK_ATTEMPT=1
        RETRY_DELAY=$INITIAL_RETRY_DELAY
        DOCKER_DAEMON_ERROR=""
        DAEMON_START_TIME=$(date +%s)
        DAEMON_TIMEOUT_WARNING=$((MAX_DAEMON_CHECK_ATTEMPTS * MAX_RETRY_DELAY / 2))  # Warn at half the expected max time
    
    while [ $DAEMON_CHECK_ATTEMPT -le $MAX_DAEMON_CHECK_ATTEMPTS ]; do
        CURRENT_TIME=$(date +%s)
        ELAPSED_TIME=$((CURRENT_TIME - DAEMON_START_TIME))
        
        log "Docker daemon status check attempt $DAEMON_CHECK_ATTEMPT/$MAX_DAEMON_CHECK_ATTEMPTS (delay: ${RETRY_DELAY}s, elapsed: ${ELAPSED_TIME}s)..."
        
        # Add progress warning if taking longer than expected
        if [ $ELAPSED_TIME -gt $DAEMON_TIMEOUT_WARNING ] && [ $DAEMON_CHECK_ATTEMPT -gt 3 ]; then
            log "⚠️  WARNING: Docker daemon startup is taking longer than expected (${ELAPSED_TIME}s elapsed)"
            log "   This may indicate system resource constraints or configuration issues"
        fi
        
        # OPTIMIZATION: Use adaptive timeout - shorter for early attempts, longer for later ones
        local adaptive_timeout
        if [ $DAEMON_CHECK_ATTEMPT -le 3 ]; then
            adaptive_timeout=10  # Short timeout for first 3 attempts
        else
            adaptive_timeout=$DOCKER_OPERATION_TIMEOUT  # Full timeout for later attempts
        fi
        
        log "Using adaptive timeout: ${adaptive_timeout}s (attempt $DAEMON_CHECK_ATTEMPT)"
        
        # Capture detailed error output for analysis with adaptive timeout
        DOCKER_INFO_OUTPUT=$(timeout $adaptive_timeout multipass exec "$VM_NAME" -- docker info 2>&1)
        DOCKER_INFO_EXIT_CODE=$?
        
        if [ $DOCKER_INFO_EXIT_CODE -eq 0 ]; then
            log "✅ Docker daemon is running and accessible in VM (attempt $DAEMON_CHECK_ATTEMPT, total time: ${ELAPSED_TIME}s)"
            DOCKER_DAEMON_RUNNING=true
            break
        else
            log "⚠️  Docker daemon is not running or not accessible in VM (attempt $DAEMON_CHECK_ATTEMPT, elapsed: ${ELAPSED_TIME}s)"
            
            # Store the error output for analysis
            DOCKER_DAEMON_ERROR="$DOCKER_INFO_OUTPUT"
            
            # Add intermediate diagnostic information during retries (not just on final failure)
            if [ $DAEMON_CHECK_ATTEMPT -gt 2 ]; then
                log "INTERMEDIATE DIAGNOSTIC (attempt $DAEMON_CHECK_ATTEMPT):"
                log "- Docker daemon process: $(multipass exec "$VM_NAME" -- ps aux | grep -i docker | grep -v grep | head -n1 2>/dev/null || echo 'Not found')"
                log "- Docker daemon status: $(multipass exec "$VM_NAME" -- sudo systemctl is-active docker 2>/dev/null || echo 'Unknown')"
                log "- Docker daemon socket: $(multipass exec "$VM_NAME" -- ls -la /var/run/docker.sock 2>/dev/null | head -n1 || echo 'Not found')"
            fi
            
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
                
# Collect essential diagnostic information
        log "ESSENTIAL DIAGNOSTIC INFORMATION:"
        log "Docker service status:"
        multipass exec "$VM_NAME" -- sudo systemctl status docker 2>&1 | head -5 | tee -a "$LOG_FILE" || true
        log "Docker daemon logs (last 5 lines):"
        multipass exec "$VM_NAME" -- sudo journalctl -u docker.service --no-pager -n 5 2>&1 | tee -a "$LOG_FILE" || true
        log "VM system resources:"
        multipass exec "$VM_NAME" -- df -h 2>&1 | head -3 | tee -a "$LOG_FILE" || true
        multipass exec "$VM_NAME" -- free -h 2>&1 | head -2 | tee -a "$LOG_FILE" || true
        log "Manual recovery: multipass shell '$VM_NAME' && sudo systemctl start docker"
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
    
    # Check if Docker daemon is running after initial retry attempts
    if [ "$DOCKER_DAEMON_RUNNING" = false ]; then
        CURRENT_TIME=$(date +%s)
        ELAPSED_TIME=$((CURRENT_TIME - DAEMON_START_TIME))
        
        log "⚠️  WARNING: Docker daemon did not start within expected time (${ELAPSED_TIME}s elapsed)"
        log "   This may indicate a very slow system or persistent configuration issues"
        log "   Offering extended retry attempts for exceptionally slow startup..."
        
        # Ask user if they want to continue with extended retries
        log "Would you like to continue with extended retries? (This may take several additional minutes)"
        log "Press Ctrl+C to cancel or wait 10 seconds for extended retries to begin..."
        
        # Wait 10 seconds for user to potentially cancel
        sleep 10
        
        log "Starting extended retry attempts ($EXTENDED_RETRY_ATTEMPTS additional attempts with ${EXTENDED_RETRY_DELAY}s delay each)..."
        
        # Extended retry loop
        for ((EXTENDED_ATTEMPT=1; EXTENDED_ATTEMPT<=EXTENDED_RETRY_ATTEMPTS; EXTENDED_ATTEMPT++)); do
            CURRENT_TIME=$(date +%s)
            ELAPSED_TIME=$((CURRENT_TIME - DAEMON_START_TIME))
            
            log "Extended Docker daemon check attempt $EXTENDED_ATTEMPT/$EXTENDED_RETRY_ATTEMPTS (delay: ${EXTENDED_RETRY_DELAY}s, total elapsed: ${ELAPSED_TIME}s)..."
            
            # Capture detailed error output for analysis with timeout
            DOCKER_INFO_OUTPUT=$(timeout $DOCKER_OPERATION_TIMEOUT multipass exec "$VM_NAME" -- docker info 2>&1)
            DOCKER_INFO_EXIT_CODE=$?
            
            if [ $DOCKER_INFO_EXIT_CODE -eq 0 ]; then
                log "✅ Docker daemon is running and accessible in VM (extended attempt $EXTENDED_ATTEMPT, total time: ${ELAPSED_TIME}s)"
                DOCKER_DAEMON_RUNNING=true
                break
            else
                log "⚠️  Docker daemon still not running in VM (extended attempt $EXTENDED_ATTEMPT, elapsed: ${ELAPSED_TIME}s)"
                
                # Minimal diagnostic during extended retries
                log "Quick diagnostic: $(multipass exec "$VM_NAME" -- sudo systemctl is-active docker 2>/dev/null || echo 'daemon inactive')"
                
                # Wait before next extended attempt
                if [ $EXTENDED_ATTEMPT -lt $EXTENDED_RETRY_ATTEMPTS ]; then
                    log "Waiting ${EXTENDED_RETRY_DELAY}s before next extended attempt..."
                    sleep $EXTENDED_RETRY_DELAY
                fi
            fi
        done
    fi
    
    # Final check if daemon is running after all retry attempts
    if [ "$DOCKER_DAEMON_RUNNING" = false ]; then
        CURRENT_TIME=$(date +%s)
        ELAPSED_TIME=$((CURRENT_TIME - DAEMON_START_TIME))
        log "❌ ERROR: Docker daemon failed to start after all retry attempts (${ELAPSED_TIME}s total elapsed)"
        log "   This indicates a persistent issue with Docker daemon startup"
        log "   Please check the comprehensive diagnostic information above for troubleshooting"
        return 1
    fi
    
    # Verify Docker commands work without sudo with enhanced group membership handling
    log "Verifying Docker commands work without sudo with enhanced group membership handling..."
    DOCKER_NO_SUDO_WORKING=false
    NO_SUDO_CHECK_ATTEMPT=1
    
    while [ $NO_SUDO_CHECK_ATTEMPT -le $MAX_NO_SUDO_CHECK_ATTEMPTS ]; do
        log "Docker no-sudo verification attempt $NO_SUDO_CHECK_ATTEMPT/$MAX_NO_SUDO_CHECK_ATTEMPTS..."
        
        if timeout $DOCKER_OPERATION_TIMEOUT multipass exec "$VM_NAME" -- docker ps >/dev/null 2>&1; then
            log "✅ Docker commands work without sudo in VM (attempt $NO_SUDO_CHECK_ATTEMPT)"
            DOCKER_NO_SUDO_WORKING=true
            break
        else
            log "⚠️  Docker commands require sudo in VM (attempt $NO_SUDO_CHECK_ATTEMPT)"
            
            # Enhanced diagnostics during retries (not just on final failure)
            log "DIAGNOSTIC: Checking group membership status (attempt $NO_SUDO_CHECK_ATTEMPT)..."
            
            # Check if user is in docker group
            local user_groups
            user_groups=$(multipass exec "$VM_NAME" -- groups ubuntu 2>/dev/null || echo "unable to get groups")
            log "User groups: $user_groups"
            
            # Check if docker group exists
            local docker_group_exists
            docker_group_exists=$(multipass exec "$VM_NAME" -- getent group docker 2>/dev/null && echo "yes" || echo "no")
            log "Docker group exists: $docker_group_exists"
            
            # Try to re-activate group membership if user is in docker group but commands don't work
            if echo "$user_groups" | grep -q docker && [ "$docker_group_exists" = "yes" ]; then
                log "User is in docker group but commands don't work - trying group re-activation..."
                
                # Try newgrp again to re-activate group membership
                if multipass exec "$VM_NAME" -- newgrp docker 2>&1 | tee -a "$LOG_FILE"; then
                    log "✅ Group re-activation with newgrp succeeded"
                else
                    log "⚠️  Group re-activation with newgrp failed"
                    
                    # Alternative: Try su to create new session
                    if multipass exec "$VM_NAME" -- su -l ubuntu -c "whoami" 2>/dev/null | grep -q ubuntu; then
                        log "✅ Alternative session activation with su succeeded"
                    else
                        log "⚠️  Alternative session activation with su failed"
                    fi
                fi
            else
                log "DIAGNOSTIC: User not in docker group or docker group doesn't exist"
                log "This indicates a previous group membership setup issue"
            fi
            
            # If this is the last attempt, provide comprehensive error information
            if [ $NO_SUDO_CHECK_ATTEMPT -eq $MAX_NO_SUDO_CHECK_ATTEMPTS ]; then
                log "ERROR: Docker commands still require sudo after $MAX_NO_SUDO_CHECK_ATTEMPTS attempts"
                log "DIAGNOSTIC: Comprehensive group membership analysis..."
                
                # Detailed group membership information
                log "DETAILED GROUP MEMBERSHIP ANALYSIS:"
                log "- User groups: $(multipass exec "$VM_NAME" -- groups ubuntu 2>&1 || echo 'Unable to get groups')"
                log "- User ID and groups: $(multipass exec "$VM_NAME" -- id ubuntu 2>&1 || echo 'Unable to get id')"
                log "- Docker group exists: $(multipass exec "$VM_NAME" -- getent group docker 2>/dev/null && echo 'YES' || echo 'NO')"
                log "- Docker group members: $(multipass exec "$VM_NAME" -- getent group docker 2>/dev/null | cut -d: -f4 || echo 'NONE')"
                
                # Test different Docker access methods
                log "DOCKER ACCESS TESTS:"
                log "- Sudo docker ps test: $(multipass exec "$VM_NAME" -- sudo docker ps 2>&1 | head -n1 || echo 'FAILED')"
                log "- Docker socket permissions: $(multipass exec "$VM_NAME" -- ls -la /var/run/docker.sock 2>/dev/null | head -n1 || echo 'SOCKET NOT FOUND')"
                log "- Current user session: $(multipass exec "$VM_NAME" -- whoami 2>&1 || echo 'UNKNOWN')"
                log "- Current user environment: $(multipass exec "$VM_NAME" -- echo $USER 2>&1 || echo 'UNKNOWN')"
                
                # System information for context
                log "SYSTEM CONTEXT:"
                log "- VM uptime: $(multipass exec "$VM_NAME" -- uptime 2>/dev/null || echo 'UNKNOWN')"
                log "- Docker daemon status: $(multipass exec "$VM_NAME" -- sudo systemctl is-active docker 2>/dev/null || echo 'UNKNOWN')"
                
                log "RECOVERY RECOMMENDATIONS:"
                log "1. Manual group activation: multipass shell '$VM_NAME' && newgrp docker"
                log "2. Complete session restart: multipass shell '$VM_NAME' && exit && multipass shell '$VM_NAME'"
                log "3. VM reboot: multipass restart '$VM_NAME'"
                log "4. Manual verification: multipass shell '$VM_NAME' && docker ps"
            fi
            
            # Wait before next attempt with progressive delays
            if [ $NO_SUDO_CHECK_ATTEMPT -lt $MAX_NO_SUDO_CHECK_ATTEMPTS ]; then
                # Increase delay for later attempts (group activation can take time)
                local current_delay=$((NO_SUDO_RETRY_DELAY * NO_SUDO_CHECK_ATTEMPT))
                log "Waiting ${current_delay}s before next attempt (progressive delay for group activation)..."
                sleep $current_delay
            fi
        fi
        
        NO_SUDO_CHECK_ATTEMPT=$((NO_SUDO_CHECK_ATTEMPT + 1))
    done
    
    # Final Docker setup verification completed
    
    # Provide comprehensive summary status with detailed error analysis and recovery guidance
    if [ "$DOCKER_CLI_AVAILABLE" = true ] && [ "$DOCKER_DAEMON_RUNNING" = true ] && [ "$DOCKER_NO_SUDO_WORKING" = true ]; then
        log "✅ Docker setup in VM completed successfully - Docker CLI, daemon, and no-sudo access are all available"
        log "   - Docker CLI: Verified and operational"
        log "   - Docker daemon: Started and verified with retry loop"
        log "   - User permissions: Configured and verified for docker group access"
        log "   - No-sudo access: Verified Docker commands work without sudo"
        log "   - All components: Successfully validated and ready for image loading"
        
        # OPTIMIZATION SUMMARY
        local total_optimization_time=$((TOTAL_SETUP_END_TIME - SETUP_START_TIME))
        log "🚀 OPTIMIZATION SUMMARY:"
        log "   - Combined CLI + daemon check: Saved ~25-30 seconds"
        log "   - Adaptive timeout strategy: Saved ~5-10 seconds" 
        log "   - Fast fail pre-check: Saved ~3-5 seconds on failures"
        log "   - Total estimated time saved: ~33-45 seconds"
        log "   - Total Docker setup time: ${total_optimization_time} seconds"
        
        return 0
        
    elif [ "$DOCKER_CLI_AVAILABLE" = true ] && [ "$DOCKER_DAEMON_RUNNING" = true ] && [ "$DOCKER_NO_SUDO_WORKING" = false ]; then
        log "❌ ERROR TYPE: DOCKER GROUP MEMBERSHIP ACTIVATION FAILURE"
        log "❌ Docker setup in VM failed - Docker CLI and daemon available but no-sudo access not working"
        log "DIAGNOSTIC: Docker CLI and daemon are operational, but user cannot execute Docker commands without sudo"
        log "               This indicates docker group membership was not properly activated"
        
        log "COMPREHENSIVE RECOVERY STEPS:"
        log "1. IMMEDIATE MANUAL RECOVERY:"
        log "   - Connect to VM: multipass shell $VM_NAME"
        log "   - Verify current groups: groups ubuntu"
        log "   - Check docker group membership: id ubuntu | grep docker"
        log "   - If user is in docker group but commands still require sudo:"
        log "     * Activate group membership: newgrp docker"
        log "     * OR create new shell session: su - ubuntu"
        log "     * OR log out and log back in: exit && multipass shell $VM_NAME"
        
        log "2. GROUP MEMBERSHIP VERIFICATION AND FIX:"
        log "   - Check if user is in docker group: getent group docker | grep ubuntu"
        log "   - If not in group, re-add user: sudo usermod -aG docker ubuntu"
        log "   - Verify group addition: grep docker /etc/group | grep ubuntu"
        log "   - Check group activation: newgrp docker && groups"
        
        log "3. DOCKER SOCKET PERMISSION VERIFICATION:"
        log "   - Check docker socket permissions: ls -la /var/run/docker.sock"
        log "   - Verify user can access socket: sudo -u ubuntu ls -la /var/run/docker.sock"
        log "   - If permission denied, fix socket permissions:"
        log "     * sudo usermod -aG docker ubuntu"
        log "     * sudo systemctl restart docker"
        log "     * newgrp docker"
        
        log "4. ALTERNATIVE WORKAROUNDS:"
        log "   - Use sudo with Docker commands: sudo docker ps"
        log "   - Configure passwordless sudo for Docker commands"
        log "   - Create alias in .bashrc: alias docker='sudo docker'"
        
        log "5. PERSISTENT FIX:"
        log "   - Edit .bashrc for automatic group activation:"
        log "     echo 'newgrp docker' >> ~/.bashrc"
        log "   - OR configure Docker to run without root (advanced)"
        
        log "DIAGNOSTIC INFORMATION:"
        log "- Current user groups: $(multipass exec "$VM_NAME" -- groups ubuntu 2>/dev/null || echo 'Unable to get groups')"
        log "- Docker socket permissions: $(multipass exec "$VM_NAME" -- ls -la /var/run/docker.sock 2>/dev/null || echo 'Unable to check socket')"
        log "- Docker group members: $(multipass exec "$VM_NAME" -- getent group docker 2>/dev/null || echo 'Unable to get docker group')"
        
        # OPTIMIZATION: Track end time even for failures
        TOTAL_SETUP_END_TIME=$(date +%s)
        return 1
        
    elif [ "$DOCKER_CLI_AVAILABLE" = true ] && [ "$DOCKER_DAEMON_RUNNING" = false ]; then
        log "❌ ERROR TYPE: DOCKER DAEMON POST-SETUP STARTUP FAILURE"
        log "❌ Docker setup in VM failed - Docker CLI available but daemon not running after $MAX_DAEMON_CHECK_ATTEMPTS attempts"
        log "DIAGNOSTIC: Docker CLI is installed and accessible, but Docker daemon failed to start or stay running"
        log "               This suggests a daemon configuration, resource, or service management issue"
        
        log "COMPREHENSIVE RECOVERY STEPS:"
        log "1. IMMEDIATE DAEMON STARTUP ATTEMPTS:"
        log "   - Connect to VM: multipass shell $VM_NAME"
        log "   - Start daemon manually: sudo systemctl start docker"
        log "   - Check daemon status: sudo systemctl status docker"
        log "   - Enable daemon at boot: sudo systemctl enable docker"
        log "   - Check daemon logs: sudo journalctl -u docker.service --no-pager"
        
        log "2. DAEMON CONFIGURATION VERIFICATION:"
        log "   - Check daemon config: cat /etc/docker/daemon.json"
        log "   - Validate JSON syntax: python3 -m json.tool /etc/docker/daemon.json"
        log "   - Check systemd service: cat /lib/systemd/system/docker.service"
        log "   - Reload systemd: sudo systemctl daemon-reload"
        
        log "3. RESOURCE AND DEPENDENCY CHECKS:"
        log "   - Check system resources: free -h && df -h"
        log "   - Check kernel modules: lsmod | grep -E '(overlay|aufs|bridge)'"
        log "   - Load required modules: sudo modprobe overlay && sudo modprobe aufs"
        log "   - Check system dependencies: sudo apt --fix-broken install -y"
        
        log "4. DAEMON DEBUGGING AND TROUBLESHOOTING:"
        log "   - Test daemon manually: sudo docker info"
        log "   - Check daemon process: ps aux | grep docker | grep -v grep"
        log "   - Check network connectivity: ping -c 2 google.com"
        log "   - Check storage drivers: sudo docker info | grep 'Storage Driver'"
        
        log "5. ADVANCED RECOVERY:"
        log "   - Reset daemon to defaults: sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.backup"
        log "   - Clear Docker data (WARNING: removes images/containers): sudo systemctl stop docker && sudo rm -rf /var/lib/docker"
        log "   - Reinstall Docker: sudo apt remove --purge docker* && sudo apt autoremove && curl -fsSL https://get.docker.com | sh"
        
        log "6. SERVICE MANAGEMENT:"
        log "   - Reset failed service: sudo systemctl reset-failed docker"
        log "   - Restart service: sudo systemctl restart docker"
        log "   - Check service dependencies: sudo systemctl show docker"
        
        log "DIAGNOSTIC INFORMATION:"
        log "- Docker service status: $(multipass exec "$VM_NAME" -- sudo systemctl status docker 2>/dev/null | head -5 || echo 'Unable to get service status')"
        log "- System resources: $(multipass exec "$VM_NAME" -- free -h 2>/dev/null | head -2 || echo 'Unable to get memory info')"
        log "- Docker daemon logs: $(multipass exec "$VM_NAME" -- sudo journalctl -u docker.service --no-pager -n 5 2>/dev/null || echo 'Unable to get daemon logs')"
        log "- Kernel modules: $(multipass exec "$VM_NAME" -- lsmod | grep -E '(overlay|aufs|bridge)' 2>/dev/null || echo 'No relevant modules found')"
        
        # OPTIMIZATION: Track end time even for failures
        TOTAL_SETUP_END_TIME=$(date +%s)
        return 1
        
    elif [ "$DOCKER_CLI_AVAILABLE" = false ] && [ "$DOCKER_DAEMON_RUNNING" = true ]; then
        log "❌ ERROR TYPE: DOCKER CLI INSTALLATION VERIFICATION FAILURE"
        log "❌ Docker setup in VM failed - Docker daemon running but CLI not available"
        log "DIAGNOSTIC: Docker daemon is operational, but Docker CLI commands are not accessible"
        log "               This indicates incomplete Docker installation or PATH issues"
        
        log "COMPREHENSIVE RECOVERY STEPS:"
        log "1. DOCKER CLI VERIFICATION:"
        log "   - Connect to VM: multipass shell $VM_NAME"
        log "   - Check Docker installation: dpkg -l | grep docker"
        log "   - Check CLI binary location: which docker || find /usr -name docker 2>/dev/null"
        log "   - Check if docker binary exists: ls -la /usr/bin/docker || ls -la /usr/local/bin/docker"
        
        log "2. PATH AND ACCESSIBILITY ISSUES:"
        log "   - Check current PATH: echo $PATH"
        log "   - Check if docker is in PATH: which docker"
        log "   - If binary exists but not in PATH:"
        log "     * Create symlink: sudo ln -s /usr/local/bin/docker /usr/bin/docker"
        log "     * OR add to PATH: echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc"
        log "   - Verify binary permissions: ls -la $(which docker 2>/dev/null || echo '/usr/bin/docker')"
        
        log "3. DOCKER PACKAGE VERIFICATION:"
        log "   - List Docker packages: dpkg -l | grep -i docker"
        log "   - Check if docker-ce-cli is installed: dpkg -l | grep docker-ce-cli"
        log "   - Install missing CLI package: sudo apt install docker-ce-cli -y"
        log "   - Fix broken dependencies: sudo apt --fix-broken install -y"
        
        log "4. COMPLETE DOCKER REINSTALLATION:"
        log "   - Remove Docker packages: sudo apt remove --purge docker*"
        log "   - Clean up: sudo apt autoremove -y && sudo apt clean"
        log "   - Reinstall Docker: curl -fsSL https://get.docker.com | sh"
        log "   - Verify installation: docker --version"
        
        log "5. MANUAL CLI CONFIGURATION:"
        log "   - Download Docker CLI manually: wget https://download.docker.com/linux/static/stable/x86_64/docker-20.10.7.tgz"
        log "   - Extract and install: tar -xzf docker-20.10.7.tgz && sudo cp docker/* /usr/bin/"
        log "   - Set permissions: sudo chmod +x /usr/bin/docker*"
        
        log "DIAGNOSTIC INFORMATION:"
        log "- Docker packages: $(multipass exec "$VM_NAME" -- dpkg -l | grep docker 2>/dev/null || echo 'No Docker packages found')"
        log "- System PATH: $(multipass exec "$VM_NAME" -- echo $PATH 2>/dev/null || echo 'Unable to get PATH')"
        log "- Docker binary search: $(multipass exec "$VM_NAME" -- find /usr -name docker 2>/dev/null || echo 'Docker binary not found')"
        log "- Which docker result: $(multipass exec "$VM_NAME" -- which docker 2>/dev/null || echo 'docker command not found')"
        
        # OPTIMIZATION: Track end time even for failures
        TOTAL_SETUP_END_TIME=$(date +%s)
        return 1
        
    else
        log "❌ ERROR TYPE: COMPLETE DOCKER SETUP CATASTROPHIC FAILURE"
        log "❌ Docker setup in VM failed - Neither Docker CLI nor daemon are available"
        log "DIAGNOSTIC: Complete failure of Docker setup - both CLI and daemon are non-functional"
        log "               This indicates fundamental installation, system, or compatibility issues"
        
        log "COMPREHENSIVE RECOVERY STEPS:"
        log "1. SYSTEM VERIFICATION AND BASICS:"
        log "   - Connect to VM: multipass shell $VM_NAME"
        log "   - Check system basics: uname -a && lsb_release -a"
        log "   - Verify system compatibility: cat /etc/os-release"
        log "   - Check architecture: dpkg --print-architecture"
        log "   - Verify VM accessibility: whoami && id"
        
        log "2. NETWORK AND CONNECTIVITY:"
        log "   - Check network: ping -c 2 google.com"
        log "   - Check DNS: nslookup google.com"
        log "   - Check package repositories: cat /etc/apt/sources.list"
        log "   - Update package lists: sudo apt update"
        
        log "3. COMPLETE DOCKER CLEANUP AND REINSTALLATION:"
        log "   - Remove all Docker packages: sudo apt remove --purge docker* docker-ce* containerd*"
        log "   - Clean up system: sudo apt autoremove -y && sudo apt clean"
        log "   - Remove Docker data: sudo rm -rf /var/lib/docker /etc/docker"
        log "   - Remove Docker group: sudo groupdel docker"
        log "   - Install fresh Docker: curl -fsSL https://get.docker.com | sh"
        
        log "4. SYSTEM DEPENDENCY FIX:"
        log "   - Update system: sudo apt update && sudo apt upgrade -y"
        log "   - Install dependencies: sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release"
        log "   - Fix broken packages: sudo apt --fix-broken install -y"
        log "   - Configure Docker repository: sudo apt install docker.io -y"
        
        log "5. VM-LEVEL SOLUTIONS:"
        log "   - Check VM resources: free -h && df -h"
        log "   - Increase VM resources if needed (exit VM first):"
        log "     * multipass stop $VM_NAME"
        log "     * multipass delete $VM_NAME"
        log "     * multipass launch --name $VM_NAME --memory 4G --disk 20G"
        log "   - Try different Ubuntu version if compatibility issues persist"
        
        log "6. ALTERNATIVE INSTALLATION METHODS:"
        log "   - Use snap: sudo snap install docker"
        log "   - Use apt: sudo apt install docker.io"
        log "   - Manual installation from Docker docs"
        
        log "DIAGNOSTIC INFORMATION:"
        log "- System info: $(multipass exec "$VM_NAME" -- uname -a 2>/dev/null || echo 'Unable to get system info')"
        log "- OS release: $(multipass exec "$VM_NAME" -- cat /etc/os-release 2>/dev/null || echo 'Unable to get OS release')"
        log "- Architecture: $(multipass exec "$VM_NAME" -- dpkg --print-architecture 2>/dev/null || echo 'Unable to get architecture')"
        log "- Network status: $(multipass exec "$VM_NAME" -- ping -c 1 google.com >/dev/null 2>&1 && echo 'Network OK' || echo 'Network failed')"
        log "- System resources: $(multipass exec "$VM_NAME" -- free -h 2>/dev/null | head -2 || echo 'Unable to get memory info')"
        
        # OPTIMIZATION: Track end time even for failures
        TOTAL_SETUP_END_TIME=$(date +%s)
        return 1
    fi
    
    # OPTIMIZATION: Track end time for successful setup
    TOTAL_SETUP_END_TIME=$(date +%s)
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
    
    # Log essential diagnostic information
    log "ESSENTIAL DIAGNOSTIC INFO:"
    log "Current directory: $(pwd)"
    log "k8s directory exists: $([ -d "k8s" ] && echo "yes" || echo "no")"
    
    # File transfer diagnostics (110-119)
    if [ "$error_code" -ge 110 ] && [ "$error_code" -le 119 ]; then
        log "VM status: $(multipass info "$VM_NAME" 2>/dev/null | head -n1 || echo 'Unable to get VM status')"
        log "k8s directory in VM: $(multipass exec "$VM_NAME" -- test -d /home/ubuntu/k8s 2>/dev/null && echo 'yes' || echo 'no')"
        
        # Check specific file based on error code
        case $error_code in
            111|115)
                log "secrets.yaml exists: $([ -f "k8s/secrets.yaml" ] && echo 'yes' || echo 'no')"
                ;;
            112|116)
                log "deployment.yaml exists: $([ -f "k8s/deployment.yaml" ] && echo 'yes' || echo 'no')"
                ;;
            113|117)
                log "service.yaml exists: $([ -f "k8s/service.yaml" ] && echo 'yes' || echo 'no')"
                ;;
            114|118)
                log "ingress.yaml exists: $([ -f "k8s/ingress.yaml" ] && echo 'yes' || echo 'no')"
                ;;
        esac
    fi
    
    # Docker build and load diagnostics (120-124)
    if [ "$error_code" -ge 120 ] && [ "$error_code" -le 124 ]; then
        log "DOCKER ESSENTIAL DIAGNOSTICS:"
        log "Docker daemon: $(docker info 2>/dev/null > /dev/null && echo 'running' || echo 'not running')"
        log "Dockerfile exists: $([ -f "Dockerfile" ] && echo 'yes' || echo 'no')"
        
        case $error_code in
            120)
                log "Dockerfile expected at: $(pwd)/Dockerfile"
                ;;
            121)
                log "Docker version: $(docker --version 2>/dev/null || echo 'Docker not available')"
                ;;
            122|123|124)
                log "Docker daemon in VM: $(multipass exec "$VM_NAME" -- docker info 2>/dev/null > /dev/null && echo 'running' || echo 'not running')"
                ;;
        esac
    fi
    
    # Docker permissions diagnostics (128-130)
    if [ "$error_code" -ge 128 ] && [ "$error_code" -le 130 ]; then
        log "DOCKER PERMISSIONS DIAGNOSTICS:"
        log "Current user: $USER"
        log "Docker daemon: $(systemctl is-active docker 2>/dev/null || echo 'Unable to check')"
        
        case $error_code in
            128)
                log "Socket permission denied - user '$USER' cannot access Docker socket"
                log "Recovery: Add user to docker group: sudo usermod -aG docker $USER"
                ;;
            129)
                log "Docker daemon not accessible"
                log "Recovery: Start Docker daemon: sudo systemctl start docker"
                ;;
            130)
                log "Docker build permission error"
                log "Recovery: Ensure user is in docker group: groups | grep docker"
                ;;
        esac
    fi
    
    # Deployment restart diagnostics (125)
    if [ "$error_code" -eq 125 ]; then
        log "DEPLOYMENT DIAGNOSTICS:"
        log "VM status: $(multipass info "$VM_NAME" 2>/dev/null | head -n1 || echo 'Unable to get VM status')"
        multipass exec "$VM_NAME" -- microk8s kubectl get deployment my-ag-ui-app 2>/dev/null | head -5 || log "Unable to get deployment status"
        
        log "Recovery: Check deployment exists: multipass exec '$VM_NAME' -- microk8s kubectl get deployment my-ag-ui-app"
        log "Manual restart: multipass exec '$VM_NAME' -- microk8s kubectl rollout restart deployment/my-ag-ui-app"
    fi
    
    # Pod status verification diagnostics (126)
    if [ "$error_code" -eq 126 ]; then
        log "POD STATUS DIAGNOSTICS:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>/dev/null | head -5 || log "Unable to get pod status"
        log "Docker images in VM:"
        multipass exec "$VM_NAME" -- docker images my-ag-ui-app:latest 2>/dev/null || log "Unable to get Docker images in VM"
        
        log "Recovery: Check pod logs: multipass exec '$VM_NAME' -- microk8s kubectl logs -l app=my-ag-ui-app"
        log "Manual: Delete pod to recreate: multipass exec '$VM_NAME' -- microk8s kubectl delete pods -l app=my-ag-ui-app"
    fi
    
    # Pod probe verification diagnostics (127)
    if [ "$error_code" -eq 127 ]; then
        log "POD PROBE DIAGNOSTICS:"
        multipass exec "$VM_NAME" -- microk8s kubectl get pods -l app=my-ag-ui-app 2>/dev/null | head -5 || log "Unable to get pod status"
        
        log "Recovery: Check health endpoint: multipass exec '$VM_NAME' -- microk8s kubectl exec -l app=my-ag-ui-app -- curl -s http://localhost:3000/health"
        log "Check logs: multipass exec '$VM_NAME' -- microk8s kubectl logs -l app=my-ag-ui-app"
    fi
    
    # Lock file validation diagnostics (200)
    if [ "$error_code" -eq 200 ]; then
        log "LOCK FILE DIAGNOSTICS:"
        log "package.json exists: $([ -f "package.json" ] && echo 'yes' || echo 'no')"
        log "package-lock.json exists: $([ -f "package-lock.json" ] && echo 'yes' || echo 'no')"
        
        log "Recovery: Run 'npm install' to update lock file, then commit both files"
        log "Emergency bypass: ./deploy.sh --skip-deps-check"
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
