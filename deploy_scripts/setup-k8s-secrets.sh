#!/bin/bash

# DEBUG LEVEL: FULL (problematic phase)

# Set error handling
set -e

# Log file location
LOG_FILE="/tmp/deploy-$(date +%Y%m%d-%H%M%S).log"

# VM configuration
VM_NAME="my-ag-ui-app-k8s"

# Logging function - prints to both stdout and log file
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message"
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# Kubernetes secrets setup error handler with enhanced error messages
handle_secrets_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    # Enhanced error message formatting for better visibility
    log "═══════════════════════════════════════════════════════════════════════════════"
    log "                          DEPLOYMENT ERROR DETECTED"
    log "═══════════════════════════════════════════════════════════════════════════════"
    log "ERROR CODE: $error_code"
    log "ERROR SUMMARY: $error_message"
    log "═══════════════════════════════════════════════════════════════════════════════"
    log "QUICK FIX: $recovery_suggestion"
    log "═══════════════════════════════════════════════════════════════════════════════"
    
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
    
    # Enhanced recovery suggestions for Docker image load errors (124)
    if [ "$error_code" -eq 124 ]; then
        log "ENHANCED RECOVERY SUGGESTIONS FOR IMAGE LOAD FAILURES:"
        log "1. Verify Docker daemon is running in VM: multipass exec '$VM_NAME' -- docker info"
        log "2. Start Docker daemon if needed: multipass exec '$VM_NAME' -- sudo systemctl start docker"
        log "3. Check Docker disk space: multipass exec '$VM_NAME' -- docker system df"
        log "4. Prune unused Docker images: multipass exec '$VM_NAME' -- docker image prune -f"
        log "5. Verify image was built correctly: docker images my-ag-ui-app:latest"
        log "6. Manual image load test: multipass transfer my-ag-ui-app.tar '$VM_NAME':/tmp/ && multipass exec '$VM_NAME' -- docker load -i /tmp/my-ag-ui-app.tar"
        log "7. If transfer fails, rebuild image: docker build -t my-ag-ui-app:latest . && docker save -o my-ag-ui-app.tar my-ag-ui-app:latest"
        log "8. Check VM disk space: multipass exec '$VM_NAME' -- df -h"
        log "9. Verify multipass transfer works: multipass transfer /etc/hosts '$VM_NAME':/tmp/test && echo 'Transfer OK' || echo 'Transfer failed'"
    fi
    
    # Enhanced recovery suggestions for Docker registry push errors (131)
    if [ "$error_code" -eq 131 ]; then
        log "ENHANCED RECOVERY SUGGESTIONS FOR REGISTRY PUSH FAILURES:"
        log "1. Verify Docker daemon is running: docker info"
        log "2. Start Docker daemon if needed: sudo systemctl start docker"
        log "3. Verify tagged image exists: docker images localhost:32000/my-ag-ui-app:latest"
        log "4. Verify microk8s registry is accessible: curl -s http://localhost:32000/v2/_catalog"
        log "5. Enable microk8s registry if needed: microk8s enable registry"
        log "6. Check registry pod status: microk8s kubectl get pods -n container-registry"
        log "7. Check registry logs: microk8s kubectl logs -n container-registry -l app=registry"
        log "8. Check network connectivity: ping -c 2 localhost"
        log "9. Check disk space: df -h"
        log "10. Manual push attempt: docker push localhost:32000/my-ag-ui-app:latest"
        log "11. If all else fails, restart registry: microk8s stop && microk8s start"
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
            122|123)
                log "Docker daemon in VM: $(multipass exec "$VM_NAME" -- docker info 2>/dev/null > /dev/null && echo 'running' || echo 'not running')"
                ;;
            124)
                log "Docker daemon in VM: $(multipass exec "$VM_NAME" -- docker info 2>/dev/null > /dev/null && echo 'running' || echo 'not running')"
                log "Docker images in VM: $(multipass exec "$VM_NAME" -- docker images 2>/dev/null | head -5 || echo 'Unable to list images')"
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

# Enable debug output if DEBUG=all is set
if [ "$DEBUG" = "all" ]; then
    log "DEBUG: Verbose debug output enabled for Kubernetes secrets setup"
    set -x
fi

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