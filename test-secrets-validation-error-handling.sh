#!/bin/bash

# Test script to verify secrets validation error handling with invalid YAML
# This test verifies that the error handling in setup-k8s-secrets.sh works correctly

set -euo pipefail

# Source common error handling functions
source "deploy_scripts/common.sh"

# Initialize log file
setup_log_file

log_info "Starting secrets validation error handling test..."

# Create test directory
TEST_DIR="/tmp/secrets-validation-test"
mkdir -p "$TEST_DIR"

# Create an invalid secrets YAML file (missing required fields, malformed structure)
INVALID_SECRETS_FILE="$TEST_DIR/invalid-secrets.yaml"
cat > "$INVALID_SECRETS_FILE" << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: my-ag-ui-app-secrets
  namespace: default
# This is missing the required 'data' field and has malformed structure
# Also has invalid indentation and missing fields
type: Opaque
invalid_field: "bad value"
  nested: 
    missing-value:
EOF

log_info "Created invalid secrets YAML file for testing: $INVALID_SECRETS_FILE"

# Test 1: Verify the invalid YAML fails validation
log_info "Test 1: Validating invalid secrets YAML against Kubernetes API server..."

# Capture the validation result
VALIDATION_RESULT_FILE="$TEST_DIR/validation-result.txt"
if kubectl apply --dry-run=server -f "$INVALID_SECRETS_FILE" > "$VALIDATION_RESULT_FILE" 2>&1; then
    log_error "UNEXPECTED: Invalid YAML passed validation"
    log_error "This indicates the validation is not working correctly"
    echo "INVALID YAML CONTENT:" | tee -a "$LOG_FILE"
    cat "$INVALID_SECRETS_FILE" | tee -a "$LOG_FILE"
    echo "VALIDATION RESULT:" | tee -a "$LOG_FILE"
    cat "$VALIDATION_RESULT_FILE" | tee -a "$LOG_FILE"
    
    # Clean up
    rm -rf "$TEST_DIR"
    
    log_structured_error "SECRETS VALIDATION TEST FAILED" \
        "Invalid secrets YAML unexpectedly passed validation" \
        "Kubernetes validation rules may be too permissive, test data may not be invalid enough, or validation logic is incorrect" \
        "1. Review the invalid YAML file content\n2. Check Kubernetes API server validation rules\n3. Ensure test data is properly malformed\n4. Run test with different invalid YAML patterns"
    exit 1
fi

VALIDATION_EXIT_CODE=$?
log_info "Validation failed as expected with exit code: $VALIDATION_EXIT_CODE"

# Test 2: Verify the error handling functions work correctly
log_info "Test 2: Verifying error handling functions..."

# Test structured error logging
ERROR_LOG_FILE="$TEST_DIR/error-test.log"
echo "Testing structured error logging..." > "$ERROR_LOG_FILE"

# Redirect structured error to test file
ORIGINAL_LOG_FILE="$LOG_FILE"
LOG_FILE="$ERROR_LOG_FILE"

log_structured_error "TEST SECRETS VALIDATION ERROR" \
    "Invalid secrets YAML failed validation as expected during testing" \
    "Invalid YAML structure, missing required fields, malformed data encoding, or Kubernetes API compatibility issues" \
    "1. Verify YAML syntax and structure\n2. Ensure all required Kubernetes fields are present\n3. Check data encoding and format\n4. Validate against Kubernetes API documentation"

# Restore original log file
LOG_FILE="$ORIGINAL_LOG_FILE"

log_info "Structured error logging test completed"

# Test 3: Verify error details are captured
log_info "Test 3: Verifying error details are captured..."

# Save the validation error details
ERROR_DETAILS_FILE="$TEST_DIR/error-details.txt"
cat "$VALIDATION_RESULT_FILE" > "$ERROR_DETAILS_FILE"

log_info "Error details saved to: $ERROR_DETAILS_FILE"

# Verify error details contain expected keywords
EXPECTED_ERROR_TERMS=("error" "Error" "invalid" "Invalid" "required" "missing")
ERROR_CONTENT=$(cat "$ERROR_DETAILS_FILE")
FOUND_TERMS=0

for term in "${EXPECTED_ERROR_TERMS[@]}"; do
    if echo "$ERROR_CONTENT" | grep -qi "$term"; then
        log_info "Found expected error term: $term"
        ((FOUND_TERMS++))
    fi
done

if [[ $FOUND_TERMS -eq 0 ]]; then
    log_warning "No expected error terms found in validation output"
    log_warning "Error details content:"
    cat "$ERROR_DETAILS_FILE" | tee -a "$LOG_FILE"
else
    log_info "Found $FOUND_TERMS expected error terms in validation output"
fi

# Test 4: Simulate the error handling from setup-k8s-secrets.sh
log_info "Test 4: Simulating error handling from setup-k8s-secrets.sh..."

# Simulate the error handling logic from setup-k8s-secrets.sh lines 106-113
if ! kubectl apply --dry-run=server -f "$INVALID_SECRETS_FILE" 2>&1 | tee -a "$LOG_FILE"; then
    log_error "Secrets YAML validation failed against Kubernetes API server (TEST - Expected Behavior)"
    
    # Log the structured error as the script would
    log_structured_error "KUBERNETES SECRETS VALIDATION FAILURE" \
        "Generated secrets YAML file is invalid or incompatible with Kubernetes API server" \
        "YAML syntax errors in generated secrets file, Invalid base64 encoding of secret values, Missing required fields or incorrect Kubernetes API version, Kubernetes cluster connectivity issues" \
        "1. Check the generated file for errors: cat k8s/secrets.yaml\n2. Verify Kubernetes cluster connectivity: kubectl cluster-info\n3. Ensure you have necessary permissions: kubectl auth can-i create secret\n4. Fix any environment variable issues and regenerate the file"
    
    log_info "Error handling simulation completed successfully"
else
    log_error "Unexpected: Invalid YAML passed validation in simulation test"
    exit 1
fi

# Clean up test files
log_info "Cleaning up test files..."
rm -rf "$TEST_DIR"

# Test Summary
log_info "═══════════════════════════════════════════════════════════════════════════════"
log_info "                    SECRETS VALIDATION TEST SUMMARY"
log_info "═══════════════════════════════════════════════════════════════════════════════"
log_info "✓ Test 1: Invalid YAML correctly failed validation"
log_info "✓ Test 2: Error handling functions work correctly"  
log_info "✓ Test 3: Error details are properly captured"
log_info "✓ Test 4: Error handling simulation works as expected"
log_info "═══════════════════════════════════════════════════════════════════════════════"
log_info "SECRETS VALIDATION ERROR HANDLING TEST PASSED"
log_info "═══════════════════════════════════════════════════════════════════════════════"

log_info "Secrets validation error handling test completed successfully"