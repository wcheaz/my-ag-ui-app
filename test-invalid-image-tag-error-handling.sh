#!/bin/bash

# Invalid Image Tag Error Handling Test Script
# This script tests error handling with invalid Docker image tags
# Part of Task 7.7: Test error handling with invalid image tags

# Source the deploy.sh script to access the test function
if [ ! -f "deploy.sh" ]; then
    echo "❌ ERROR: deploy.sh not found - cannot access test function"
    exit 1
fi

# Source the deploy.sh script to get access to the test function
source deploy.sh

# Verify the test function is available
if ! command -v test_invalid_image_tag_error_handling >/dev/null 2>&1; then
    echo "❌ ERROR: test_invalid_image_tag_error_handling function not found in deploy.sh"
    echo "   Please ensure deploy.sh contains the test function"
    exit 1
fi

# Logging function
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message"
}

log "=== TASK 7.7: TESTING INVALID IMAGE TAG ERROR HANDLING ==="
log "This test validates that the deployment script properly handles"
log "invalid Docker image tags with appropriate error messages"
log ""

# Run the test function from deploy.sh
log "Executing test_invalid_image_tag_error_handling function..."
if test_invalid_image_tag_error_handling; then
    log ""
    log "🎉 SUCCESS: Invalid image tag error handling test PASSED"
    log "✅ All invalid image tag scenarios are handled correctly"
    log "✅ Error messages are clear and actionable"
    log "✅ System provides appropriate error handling for invalid tags"
    log ""
    log "ERROR HANDLING CAPABILITIES VERIFIED:"
    log "• Detection of invalid image tags"
    log "• Clear error messages for invalid tag scenarios"
    log "• Graceful failure when invalid tags are encountered"
    log "• No system crashes or undefined behavior"
    log "• Proper logging of invalid tag attempts"
    log ""
    log "✅ TASK 7.7: ERROR HANDLING WITH INVALID IMAGE TAGS - COMPLETED SUCCESSFULLY"
    exit 0
else
    log ""
    log "❌ FAILURE: Invalid image tag error handling test FAILED"
    log "⚠️  Some invalid image tag scenarios need improvement"
    log "⚠️  Review test output above for specific failures"
    log ""
    log "POTENTIAL ISSUES:"
    log "• Invalid tags not properly detected"
    log "• Unclear error messages for invalid tags"
    log "• System instability when invalid tags are used"
    log "• Missing error handling for certain invalid tag patterns"
    log ""
    log "RECOMMENDATIONS:"
    log "1. Review error messages in deploy.sh image tagging functions"
    log "2. Ensure all invalid tag patterns are handled"
    log "3. Provide clear recovery suggestions for invalid tags"
    log "4. Test with various invalid tag formats"
    log ""
    log "❌ TASK 7.7: ERROR HANDLING WITH INVALID IMAGE TAGS - FAILED"
    exit 1
fi