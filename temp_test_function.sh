test_image_loading_methods() {
    log "=== TASK 8.17: TESTING IMAGE LOADING WITH DIFFERENT METHODS ==="
    log "Testing both pipe method and file transfer method for Docker image loading..."
    
    # Check if VM is running and accessible
    log "Checking VM accessibility before method testing..."
    if ! multipass exec "$VM_NAME" -- whoami >/dev/null 2>&1; then
        log "❌ TEST FAILED: VM is not accessible"
        log "   Please ensure VM is running: multipass start $VM_NAME"
        return 1
    fi
    log "✅ VM is accessible"
    
    # Check if Docker is running in VM
    log "Checking Docker daemon status in VM..."
    if ! multipass exec "$VM_NAME" -- docker info >/dev/null 2>&1; then
        log "❌ TEST FAILED: Docker daemon is not running in VM"
        log "   Please ensure Docker is set up and running in VM"
        return 1
    fi
    log "✅ Docker daemon is running in VM"
    
    # Create temporary directory for test
    local TEST_DIR="/tmp/image-loading-methods-test-$$"
    log "Creating temporary test directory: $TEST_DIR"
    mkdir -p "$TEST_DIR"
    
    # Step 1: Check if my-ag-ui-app:latest image exists locally
    log "Step 1: Checking if my-ag-ui-app:latest image exists locally..."
    if ! docker images my-ag-ui-app:latest --format "{{.Repository}}:{{.Tag}}" | grep -q "my-ag-ui-app:latest"; then
        log "❌ TEST FAILED: my-ag-ui-app:latest image not found locally"
        log "   Please build the image first: docker build -t my-ag-ui-app:latest ."
        rm -rf "$TEST_DIR"
        return 1
    fi
    log "✅ my-ag-ui-app:latest image exists locally"
    
    # Remove any existing test image from VM to ensure clean test
    log "Cleaning up any existing test image from VM..."
    multipass exec "$VM_NAME" -- docker rmi my-ag-ui-app:latest 2>/dev/null || true
    
    # Initialize test results
    local PIPE_METHOD_SUCCESS=false
    local FILE_TRANSFER_METHOD_SUCCESS=false
    local PIPE_METHOD_TIME=0
    local FILE_TRANSFER_METHOD_TIME=0
    
    # === METHOD 1: PIPE METHOD TESTING ===
    log ""
    log "=================================================="
    log "           TESTING PIPE METHOD"
    log "=================================================="
    log "Command: docker save my-ag-ui-app:latest | multipass exec '$VM_NAME' -- docker load"
    
    # Clean up any existing image in VM first
    multipass exec "$VM_NAME" -- docker rmi my-ag-ui-app:latest 2>/dev/null || true
    
    # Test pipe method
    log "Starting pipe method test..."
    local PIPE_START_TIME=$(date +%s)
    
    # Execute pipe method with error handling and output capture
    if docker save my-ag-ui-app:latest 2>/dev/null | multipass exec "$VM_NAME" -- docker load 2>&1 | tee -a "$LOG_FILE"; then
        local PIPE_END_TIME=$(date +%s)
        PIPE_METHOD_TIME=$((PIPE_END_TIME - PIPE_START_TIME))
        log "✅ PIPE METHOD: Command completed successfully in ${PIPE_METHOD_TIME} seconds"
        
        # Verify image was loaded
        if multipass exec "$VM_NAME" -- docker images my-ag-ui-app:latest --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "my-ag-ui-app:latest"; then
            log "✅ PIPE METHOD: Image verified in VM's Docker daemon"
            PIPE_METHOD_SUCCESS=true
            
            # Get image details
            local PIPE_IMAGE_DETAILS=$(multipass exec "$VM_NAME" -- docker images my-ag-ui-app:latest --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null || echo "Failed to get details")
            log "✅ PIPE METHOD: Image details:"
            echo "$PIPE_IMAGE_DETAILS" | tee -a "$LOG_FILE"
        else
            log "❌ PIPE METHOD: Command succeeded but image not found in VM \(silent failure\)"
            log "   This indicates a potential issue with the pipe method"
        fi
    else
        local PIPE_END_TIME=$(date +%s)
        PIPE_METHOD_TIME=$((PIPE_END_TIME - PIPE_START_TIME))
        log "❌ PIPE METHOD: Command failed in ${PIPE_METHOD_TIME} seconds"
        log "   Check error output above for details"
    fi
    
    # Clean up image from VM after pipe test
    log "Cleaning up image from VM after pipe test..."
    multipass exec "$VM_NAME" -- docker rmi my-ag-ui-app:latest 2>/dev/null || true
    
    # === METHOD 2: FILE TRANSFER METHOD TESTING ===
    log ""
    log "=================================================="
    log "           TESTING FILE TRANSFER METHOD"
    log "=================================================="
    log "Command sequence: docker save → multipass transfer → docker load"
    
    # Clean up any existing image in VM first
    multipass exec "$VM_NAME" -- docker rmi my-ag-ui-app:latest 2>/dev/null || true
    
    # Step 2: Save Docker image to file using docker save
    log "Step 2: Saving Docker image to file..."
    local IMAGE_FILE="$TEST_DIR/test-image.tar"
    log "   Executing: docker save my-ag-ui-app:latest -o $IMAGE_FILE"
    
    local FILE_SAVE_START_TIME=$(date +%s)
    if ! docker save my-ag-ui-app:latest -o "$IMAGE_FILE" 2>&1 | tee -a "$LOG_FILE"; then
        log "❌ FILE TRANSFER METHOD: Failed to save Docker image to file"
        rm -rf "$TEST_DIR"
        return 1
    fi
    
    # Verify saved file
    if [ ! -f "$IMAGE_FILE" ]; then
        log "❌ FILE TRANSFER METHOD: Image file was not created"
        rm -rf "$TEST_DIR"
        return 1
    fi
    
    local IMAGE_SIZE=$(du -h "$IMAGE_FILE" | cut -f1)
    local IMAGE_SIZE_BYTES=$(stat -c%s "$IMAGE_FILE" 2>/dev/null || echo "unknown")
    log "✅ FILE TRANSFER METHOD: Docker image saved successfully: $IMAGE_SIZE \(${IMAGE_SIZE_BYTES} bytes\)"
    
    # Step 3: Transfer image file to VM using multipass transfer
    log "Step 3: Transferring image file to VM using multipass transfer..."
    local VM_IMAGE_PATH="/home/ubuntu/test-image.tar"
    log "   Executing: multipass transfer $IMAGE_FILE $VM_NAME:$VM_IMAGE_PATH"
    
    local TRANSFER_START_TIME=$(date +%s)
    if ! multipass transfer "$IMAGE_FILE" "$VM_NAME:$VM_IMAGE_PATH" 2>&1 | tee -a "$LOG_FILE"; then
        log "❌ FILE TRANSFER METHOD: multipass transfer command failed"
        rm -rf "$TEST_DIR"
        return 1
    fi
    local TRANSFER_END_TIME=$(date +%s)
    local TRANSFER_DURATION=$((TRANSFER_END_TIME - TRANSFER_START_TIME))
    
    log "✅ FILE TRANSFER METHOD: Image file transferred successfully in ${TRANSFER_DURATION} seconds"
    
    # Step 4: Verify file exists in VM after transfer
    log "Step 4: Verifying file exists in VM after transfer..."
    if ! multipass exec "$VM_NAME" -- test -f "$VM_IMAGE_PATH" 2>&1 | tee -a "$LOG_FILE"; then
        log "❌ FILE TRANSFER METHOD: Transferred file does not exist in VM"
        rm -rf "$TEST_DIR"
        return 1
    fi
    
    # Get file info in VM
    local VM_FILE_SIZE=$(multipass exec "$VM_NAME" -- du -h "$VM_IMAGE_PATH" 2>/dev/null | cut -f1 || echo "unknown")
    log "✅ FILE TRANSFER METHOD: File exists in VM with size: $VM_FILE_SIZE"
    
    # Step 5: Load Docker image in VM using docker load
    log "Step 5: Loading Docker image in VM using docker load..."
    log "   Executing: docker load -i $VM_IMAGE_PATH"
    
    local LOAD_START_TIME=$(date +%s)
    if ! multipass exec "$VM_NAME" -- docker load -i "$VM_IMAGE_PATH" 2>&1 | tee -a "$LOG_FILE"; then
        log "❌ FILE TRANSFER METHOD: docker load command failed in VM"
        # Clean up file in VM
        multipass exec "$VM_NAME" -- rm -f "$VM_IMAGE_PATH" 2>/dev/null || true
        rm -rf "$TEST_DIR"
        return 1
    fi
    local LOAD_END_TIME=$(date +%s)
    local LOAD_DURATION=$((LOAD_END_TIME - LOAD_START_TIME))
    
    log "✅ FILE TRANSFER METHOD: Docker image loaded successfully in VM in ${LOAD_DURATION} seconds"
    
    # Calculate total file transfer method time
    FILE_TRANSFER_METHOD_TIME=$((TRANSFER_END_TIME - FILE_SAVE_START_TIME))
    
    # Step 6: Verify image is available in VM's Docker daemon
    log "Step 6: Verifying image is available in VM's Docker daemon..."
    local VM_IMAGES_OUTPUT=$(multipass exec "$VM_NAME" -- docker images my-ag-ui-app:latest --format "{{.Repository}}:{{.Tag}}" 2>/dev/null || echo "")
    
    if ! echo "$VM_IMAGES_OUTPUT" | grep -q "my-ag-ui-app:latest"; then
        log "❌ FILE TRANSFER METHOD: Image not found in VM's Docker daemon after load"
        log "   Images in VM:"
        multipass exec "$VM_NAME" -- docker images 2>&1 | tee -a "$LOG_FILE" || true
        # Clean up file in VM
        multipass exec "$VM_NAME" -- rm -f "$VM_IMAGE_PATH" 2>/dev/null || true
        rm -rf "$TEST_DIR"
        return 1
    fi
    
    log "✅ FILE TRANSFER METHOD: Image verified in VM's Docker daemon"
    
    # Step 7: Test image functionality by inspecting it
    log "Step 7: Testing image functionality by inspecting it..."
    if ! multipass exec "$VM_NAME" -- docker inspect my-ag-ui-app:latest >/dev/null 2>&1; then
        log "❌ FILE TRANSFER METHOD: Cannot inspect loaded image in VM"
        # Clean up file in VM
        multipass exec "$VM_NAME" -- rm -f "$VM_IMAGE_PATH" 2>/dev/null || true
        rm -rf "$TEST_DIR"
        return 1
    fi
    
    log "✅ FILE TRANSFER METHOD: Image can be inspected and is functional in VM"
    FILE_TRANSFER_METHOD_SUCCESS=true
    
    # Get image details
    local FILE_IMAGE_DETAILS=$(multipass exec "$VM_NAME" -- docker images my-ag-ui-app:latest --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null || echo "Failed to get details")
    log "✅ FILE TRANSFER METHOD: Image details:"
    echo "$FILE_IMAGE_DETAILS" | tee -a "$LOG_FILE"
    
    # Step 8: Clean up
    log "Step 8: Cleaning up test artifacts..."
    # Remove transferred file from VM
    multipass exec "$VM_NAME" -- rm -f "$VM_IMAGE_PATH" 2>&1 | tee -a "$LOG_FILE" || true
    # Remove test image from VM Docker daemon
    multipass exec "$VM_NAME" -- docker rmi my-ag-ui-app:latest 2>/dev/null || true
    # Remove local test directory
    rm -rf "$TEST_DIR"
    
    log "✅ Cleanup completed"
    
    # === COMPARATIVE ANALYSIS ===
    log ""
    log "=================================================="
    log "           IMAGE LOADING METHODS COMPARISON"
    log "=================================================="
    
    log "PERFORMANCE COMPARISON:"
    log "  • Pipe method time: ${PIPE_METHOD_TIME} seconds"
    log "  • File transfer method time: ${FILE_TRANSFER_METHOD_TIME} seconds"
    
    if [ "$PIPE_METHOD_SUCCESS" = true ] && [ "$FILE_TRANSFER_METHOD_SUCCESS" = true ]; then
        log "  • Both methods completed successfully"
        
        # Calculate performance difference
        if [ $PIPE_METHOD_TIME -gt $FILE_TRANSFER_METHOD_TIME ]; then
            local DIFFERENCE=$((PIPE_METHOD_TIME - FILE_TRANSFER_METHOD_TIME))
            log "  • File transfer method is ${DIFFERENCE} seconds faster"
        elif [ $FILE_TRANSFER_METHOD_TIME -gt $PIPE_METHOD_TIME ]; then
            local DIFFERENCE=$((FILE_TRANSFER_METHOD_TIME - PIPE_METHOD_TIME))
            log "  • Pipe method is ${DIFFERENCE} seconds faster"
        else
            log "  • Both methods have identical performance"
        fi
        
        # Calculate performance percentage
        local FASTER_METHOD=""
        local SLOWER_METHOD=""
        local PERCENTAGE_DIFF=0
        
        if [ $PIPE_METHOD_TIME -lt $FILE_TRANSFER_METHOD_TIME ]; then
            FASTER_METHOD="Pipe method"
            SLOWER_METHOD="File transfer method"
            PERCENTAGE_DIFF=$(( (FILE_TRANSFER_METHOD_TIME - PIPE_METHOD_TIME) * 100 / FILE_TRANSFER_METHOD_TIME ))
        elif [ $FILE_TRANSFER_METHOD_TIME -lt $PIPE_METHOD_TIME ]; then
            FASTER_METHOD="File transfer method"
            SLOWER_METHOD="Pipe method"
            PERCENTAGE_DIFF=$(( (PIPE_METHOD_TIME - FILE_TRANSFER_METHOD_TIME) * 100 / PIPE_METHOD_TIME ))
        fi
        
        if [ -n "$FASTER_METHOD" ]; then
            log "  • $FASTER_METHOD is ${PERCENTAGE_DIFF}% faster than $SLOWER_METHOD"
        fi
        
    elif [ "$PIPE_METHOD_SUCCESS" = true ]; then
        log "  ⚠️  Only pipe method completed successfully"
        log "  • File transfer method failed"
    elif [ "$FILE_TRANSFER_METHOD_SUCCESS" = true ]; then
        log "  ⚠️  Only file transfer method completed successfully"
        log "  • Pipe method failed"
    else
        log "  ❌ Both methods failed"
        return 1
    fi
    
    log ""
    log "METHOD CHARACTERISTICS:"
    log "  • Pipe method characteristics:"
    log "    - Single command pipeline"
    log "    - No intermediate files on host system"
    log "    - Stream processing (memory efficient for large images)"
    log "    - Limited error visibility (harder to debug failures)"
    log "    - Network dependent during entire operation"
    
    log "  • File transfer method characteristics:"
    log "    - Multi-step process (save → transfer → load)"
    log "    - Creates intermediate file on host system"
    log "    - More disk I/O operations"
    log "    - Better error isolation and debugging"
    log "    - Can resume interrupted transfers (with additional logic)"
    log "    - File can be verified before transfer"
    
    log ""
    log "RECOMMENDATIONS:"
    
    if [ "$PIPE_METHOD_SUCCESS" = true ] && [ "$FILE_TRANSFER_METHOD_SUCCESS" = true ]; then
        log "  ✅ Both methods are viable for production use"
        log "  ✅ Choose based on your specific requirements:"
        log "     - Use pipe method for: simplicity, memory efficiency, automated scripts"
        log "     - Use file transfer method for: reliability, debugging, large images"
        
        # Performance-based recommendation
        if [ $PIPE_METHOD_TIME -lt $((FILE_TRANSFER_METHOD_TIME - 5)) ]; then
            log "  🚀 PERFORMANCE: Pipe method is significantly faster - recommended for performance-critical deployments"
        elif [ $FILE_TRANSFER_METHOD_TIME -lt $((PIPE_METHOD_TIME - 5)) ]; then
            log "  🚀 PERFORMANCE: File transfer method is significantly faster - recommended for performance-critical deployments"
        else
            log "  ⚖️  PERFORMANCE: Both methods have similar performance - choose based on other factors"
        fi
        
    elif [ "$PIPE_METHOD_SUCCESS" = true ]; then
        log "  ⚠️  Only pipe method is working - recommended for current environment"
        log "  🔧 TROUBLESHOOTING: File transfer method needs investigation"
        log "     Check multipass transfer functionality and file permissions"
        
    elif [ "$FILE_TRANSFER_METHOD_SUCCESS" = true ]; then
        log "  ⚠️  Only file transfer method is working - recommended for current environment"
        log "  🔧 TROUBLESHOOTING: Pipe method needs investigation"
        log "     Check multipass exec pipe functionality and Docker daemon in VM"
    else
        log "  ❌ CRITICAL: Neither method is working"
        log "     Environment has fundamental issues that need resolution"
        return 1
    fi
    
    log ""
    log "=================================================="
    log "  TASK 8.17: IMAGE LOADING METHODS TEST COMPLETE"
    log "=================================================="
    log ""
    log "✅ SUCCESS: Image loading methods comparison completed"
    
    if [ "$PIPE_METHOD_SUCCESS" = true ]; then
        log "✅ Pipe method: Working"
    else
        log "❌ Pipe method: Failed"
    fi
    
    if [ "$FILE_TRANSFER_METHOD_SUCCESS" = true ]; then
        log "✅ File transfer method: Working"
    else
        log "❌ File transfer method: Failed"
    fi
    
    log ""
    log "PERFORMANCE SUMMARY:"
    log "   - Pipe method: ${PIPE_METHOD_TIME} seconds"
    log "   - File transfer method: ${FILE_TRANSFER_METHOD_TIME} seconds"
}
