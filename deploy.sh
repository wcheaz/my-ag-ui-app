
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
    
    # Check Docker CLI availability in VM
    log "Checking Docker CLI availability in VM..."
    if multipass exec "$VM_NAME" -- docker --version >/dev/null 2>&1; then
        DOCKER_VERSION=$(multipass exec "$VM_NAME" -- docker --version 2>/dev/null | head -n1)
        log "✅ Docker CLI is available in VM: $DOCKER_VERSION"
        DOCKER_CLI_AVAILABLE=true
    else
        log "⚠️  Docker CLI is not available in VM"
        DOCKER_CLI_AVAILABLE=false
    fi
    
    # Install Docker if not available
    if [ "$DOCKER_CLI_AVAILABLE" = false ]; then
        log "Installing Docker using official script..."
        if ! multipass exec "$VM_NAME" -- bash -c "curl -fsSL https://get.docker.com | sh" 2>&1 | tee -a "$LOG_FILE"; then
            log "ERROR: Docker installation failed"
            log "RECOVERY: Manual installation may be required. Connect to VM with: multipass shell $VM_NAME"
            log "         Then run: curl -fsSL https://get.docker.com | sh"
            return 1
        fi
        
        # Verify Docker was installed
        log "Verifying Docker installation..."
        if multipass exec "$VM_NAME" -- docker --version >/dev/null 2>&1; then
            DOCKER_VERSION=$(multipass exec "$VM_NAME" -- docker --version 2>/dev/null | head -n1)
            log "✅ Docker installed successfully: $DOCKER_VERSION"
            DOCKER_CLI_AVAILABLE=true
        else
            log "ERROR: Docker installation verification failed"
            log "RECOVERY: Check installation logs above. Manual intervention may be required."
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
    
    while [ $DAEMON_CHECK_ATTEMPT -le $MAX_DAEMON_CHECK_ATTEMPTS ]; do
        log "Docker daemon status check attempt $DAEMON_CHECK_ATTEMPT/$MAX_DAEMON_CHECK_ATTEMPTS (delay: ${RETRY_DELAY}s)..."
        
        if multipass exec "$VM_NAME" -- docker info >/dev/null 2>&1; then
            log "✅ Docker daemon is running and accessible in VM (attempt $DAEMON_CHECK_ATTEMPT)"
            DOCKER_DAEMON_RUNNING=true
            break
        else
            log "⚠️  Docker daemon is not running or not accessible in VM (attempt $DAEMON_CHECK_ATTEMPT)"
            
            # If this is the last attempt, provide detailed error information
            if [ $DAEMON_CHECK_ATTEMPT -eq $MAX_DAEMON_CHECK_ATTEMPTS ]; then
                log "ERROR: Docker daemon did not start after $MAX_DAEMON_CHECK_ATTEMPTS attempts"
                log "DIAGNOSTIC: Checking Docker service status..."
                multipass exec "$VM_NAME" -- sudo systemctl status docker 2>&1 | tee -a "$LOG_FILE" || true
                
                log "DIAGNOSTIC: Checking Docker daemon logs..."
                multipass exec "$VM_NAME" -- sudo journalctl -u docker.service --no-pager -n 20 2>&1 | tee -a "$LOG_FILE" || true
                
                log "DIAGNOSTIC: Checking if Docker daemon process is running..."
                multipass exec "$VM_NAME" -- ps aux | grep -i docker | grep -v grep 2>&1 | tee -a "$LOG_FILE" || true
                
                log "DIAGNOSTIC: Checking system resources..."
                multipass exec "$VM_NAME" -- df -h 2>&1 | tee -a "$LOG_FILE" || true
                multipass exec "$VM_NAME" -- free -h 2>&1 | tee -a "$LOG_FILE" || true
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
