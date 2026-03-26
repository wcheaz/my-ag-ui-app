#!/bin/bash

set -euo pipefail

# Simple test script
log_info() {
    local message="$1"
    echo "INFO: $message"
}

log_info "Test message"
log_info "Test completed"
exit 0
