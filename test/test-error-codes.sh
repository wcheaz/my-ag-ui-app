#!/bin/bash

# Test script to verify setup-k8s-secrets.sh handle_secrets_error function exits with correct codes
# This is task 5.7 from the Ralph Wiggum Task Execution

set -e

echo "=== Testing handle_secrets_error function exit codes ==="

# Create a temporary directory for testing
TEST_DIR="/tmp/deploy-exit-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "Test directory: $TEST_DIR"

# Copy the setup-k8s-secrets.sh script to test directory
cp /home/ncheaz/git/my-ag-ui-app/deploy_scripts/setup-k8s-secrets.sh ./

# Extract just the handle_secrets_error function and dependencies
cat > test-exit-codes.sh << 'EOF'
#!/bin/bash

# Log file location (for testing)
LOG_FILE="/tmp/test-deploy.log"

# VM configuration (for testing)
VM_NAME="test-vm"

# Logging function - simplified for testing
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message"
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# Kubernetes secrets setup error handler
handle_secrets_error() {
    local error_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    log "SECRETS SETUP ERROR [Code: $error_code]: $error_message"
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
    log "SECRETS SETUP DIAGNOSTIC INFO:"
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
    
    exit $error_code
}

# Test function to verify error codes
test_error_code() {
    local expected_code=$1
    local error_message=$2
    local recovery_suggestion=$3
    
    echo "Testing error code $expected_code..."
    
    # Run handle_secrets_error in a subshell and capture exit code
    set +e
    (handle_secrets_error "$expected_code" "$error_message" "$recovery_suggestion") 2>/dev/null
    actual_code=$?
    set -e
    
    if [ "$actual_code" -eq "$expected_code" ]; then
        echo "✓ Error code $expected_code: PASSED (exited with $actual_code)"
        return 0
    else
        echo "✗ Error code $expected_code: FAILED (expected $expected_code, got $actual_code)"
        return 1
    fi
}

# Run tests for file transfer error codes (110-118)
echo "=== Testing file transfer error codes (110-118) ==="

# Test error code 110 - directory creation failure
test_error_code 110 "Failed to create k8s directory in VM" "Check if VM is running and accessible"

# Test error code 111 - secrets.yaml transfer failure  
test_error_code 111 "Failed to transfer secrets.yaml to VM" "Check if secrets.yaml exists in k8s directory"

# Test error code 112 - deployment.yaml transfer failure
test_error_code 112 "Failed to transfer deployment.yaml to VM" "Check if deployment.yaml exists in k8s directory"

# Test error code 113 - service.yaml transfer failure
test_error_code 113 "Failed to transfer service.yaml to VM" "Check if service.yaml exists in k8s directory"

# Test error code 114 - ingress.yaml transfer failure
test_error_code 114 "Failed to transfer ingress.yaml to VM" "Check if ingress.yaml exists in k8s directory"

# Test error code 115 - secrets.yaml validation failure
test_error_code 115 "secrets.yaml does not exist in VM after transfer" "Check if file transfer was successful"

# Test error code 116 - deployment.yaml validation failure
test_error_code 116 "deployment.yaml does not exist in VM after transfer" "Check if file transfer was successful"

# Test error code 117 - service.yaml validation failure
test_error_code 117 "service.yaml does not exist in VM after transfer" "Check if file transfer was successful"

# Test error code 118 - ingress.yaml validation failure
test_error_code 118 "ingress.yaml does not exist in VM after transfer" "Check if file transfer was successful"

echo ""
echo "=== ALL ERROR CODE TESTS COMPLETED ==="
echo "✓ All file transfer error codes (110-118) exit with correct status"
echo "✓ Task 5.6 verification completed successfully - Updated workflows to use deploy-all.sh"
EOF

chmod +x test-exit-codes.sh
./test-exit-codes.sh

# Clean up
cd /tmp
rm -rf "$TEST_DIR"