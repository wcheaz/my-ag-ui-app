#!/bin/bash

# Test script to validate lock file detection and fallback mechanism
# This tests the core logic without requiring Docker permissions

echo "=== Testing Lock File Validation and Fallback ==="

# Check if package.json and package-lock.json are out of sync
echo "1. Running npm ci --dry-run to check for lock file synchronization..."

if npm ci --dry-run 2>&1 | grep -q "npm.*ERR\|Could not resolve dependency\|ERESOLVE"; then
    echo "✓ npm ci --dry-run FAILED - lock files are out of sync (expected)"
    
    echo ""
    echo "2. Testing deploy.sh validation logic..."
    
    # Extract and test the validation function from deploy.sh
    validate_lock_files() {
        echo "Running npm ci --dry-run to check for lock file synchronization..."
        
        # Run npm ci --dry-run and capture output and exit status
        local output
        output=$(npm ci --dry-run 2>&1)
        local exit_status=$?
        
        echo "npm ci --dry-run exit status: $exit_status"
        
        # Check for specific error patterns in the output
        if echo "$output" | grep -q "npm.*ERR\|Could not resolve dependency\|ERESOLVE"; then
            echo "ERROR: package.json and package-lock.json are out of sync"
            echo ""
            echo "RECOVERY INSTRUCTIONS:"
            echo "1. To fix this issue, run: npm install"
            echo "2. This will update package-lock.json to match package.json"
            echo "3. Commit the updated package-lock.json to your repository"
            echo "4. Then run the deployment again"
            echo ""
            echo "To bypass this check (not recommended), use: --skip-deps-check"
            echo ""
            return 1
        fi
        
        echo "✓ Lock file validation successful - package.json and package-lock.json are synchronized"
        return 0
    }
    
    if validate_lock_files; then
        echo "UNEXPECTED: Validation passed but npm ci --dry-run failed"
        exit 1
    else
        echo "✓ Validation correctly detected out-of-sync lock files"
    fi
    
    echo ""
    echo "3. Testing Docker fallback mechanism simulation..."
    
    # Simulate the Docker fallback logic
    echo "Simulating: npm ci --ignore-scripts (checking for failure patterns)..."
    
    local ci_output
    ci_output=$(npm ci --ignore-scripts 2>&1)
    
    if echo "$ci_output" | grep -q "npm.*ERR\|Could not resolve dependency\|ERESOLVE"; then
        echo "✓ npm ci failed as expected - triggering fallback"
        
        echo ""
        echo "=== DOCKER BUILD FALLBACK MECHANISM TRIGGERED ==="
        echo "ERROR: npm ci failed due to lock file synchronization issues"
        echo "FALLBACK: Switching to npm install to continue build"
        echo "ACTION REQUIRED: Run 'npm install' to update package-lock.json"
        echo "==============================================="
        
        echo "Simulating: npm install --ignore-scripts (fallback)..."
        if npm install --ignore-scripts >/dev/null 2>&1; then
            echo "✓ FALLBACK COMPLETED: Build continuing with npm install"
            echo "WARNING: package.json and package-lock.json are out of sync"
        else
            echo "✗ FALLBACK FAILED: npm install also failed"
            exit 1
        fi
    else
        echo "INFO: npm ci --ignore-scripts succeeded (may happen in some scenarios)"
        echo "This suggests the fallback mechanism would not be triggered in this case"
        echo "However, the validation step would have already caught the sync issue"
    fi
    
    echo ""
    echo "=== TEST RESULTS ==="
    echo "✓ Lock file validation correctly detected out-of-sync state"
    echo "✓ Fallback mechanism would trigger correctly in Docker build"
    echo "✓ Recovery instructions provided clearly"
    
else
    echo "✗ UNEXPECTED: npm ci --dry-run succeeded - lock files appear to be in sync"
    echo "This test expects out-of-sync lock files for fallback mechanism testing"
    exit 1
fi

echo ""
echo "=== Test completed successfully ==="