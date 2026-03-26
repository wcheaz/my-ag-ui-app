#!/bin/bash

# Enable strict error handling
set -euo pipefail

# Common error handling functions for deployment scripts
# This file should be sourced by all deployment scripts

# Global error codes
ERROR_GENERAL=1
ERROR_DEPENDENCY=200
ERROR_REGISTRY=201
ERROR_DOCKER=202
ERROR_KUBERNETES=203
ERROR_NETWORK=204
ERROR_VALIDATION=205

# Global variables
VM_NAME="${VM_NAME:-my-ag-ui-app-k8s}"
LOG_FILE="${LOG_FILE:-/tmp/deploy-$(date +%Y%m%d-%H%M%S).log}"

# Common logging function
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Info level logging function
log_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] INFO: $message" | tee -a "$LOG_FILE"
}

# Warning level logging function
log_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] WARNING: $message" | tee -a "$LOG_FILE"
}

# Error level logging function
log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $message" | tee -a "$LOG_FILE"
}

# Structured error logging function with detailed fields
log_structured_error() {
    local error_type="$1"
    local diagnostic="$2"
    local common_causes="$3"
    local recovery="$4"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] ══════════════════════════════════════════════════════════════════════════════" | tee -a "$LOG_FILE"
    echo "[$timestamp]                          STRUCTURED ERROR" | tee -a "$LOG_FILE"
    echo "[$timestamp] ══════════════════════════════════════════════════════════════════════════════" | tee -a "$LOG_FILE"
    echo "[$timestamp] ERROR TYPE: $error_type" | tee -a "$LOG_FILE"
    echo "[$timestamp] DIAGNOSTIC: $diagnostic" | tee -a "$LOG_FILE"
    echo "[$timestamp] COMMON CAUSES: $common_causes" | tee -a "$LOG_FILE"
    echo "[$timestamp] RECOVERY: $recovery" | tee -a "$LOG_FILE"
    echo "[$timestamp] ══════════════════════════════════════════════════════════════════════════════" | tee -a "$LOG_FILE"
}

# Common error handler
handle_error() {
    local error_code="$1"
    local error_message="$2"
    local recovery_suggestion="$3"
    local error_type="${4:-GENERAL}"
    
    log "═══════════════════════════════════════════════════════════════════════════════"
    log "                          $error_type ERROR"
    log "═══════════════════════════════════════════════════════════════════════════════"
    log "ERROR CODE: $error_code"
    log "ERROR SUMMARY: $error_message"
    log "═══════════════════════════════════════════════════════════════════════════════"
    log "QUICK FIX: $recovery_suggestion"
    log "═══════════════════════════════════════════════════════════════════════════════"
    
    exit "$error_code"
}

# Dependency validation error handler
handle_dependency_error() {
    handle_error "$ERROR_DEPENDENCY" "$1" "$2" "DEPENDENCY VALIDATION"
}

# Registry error handler
handle_registry_error() {
    handle_error "$ERROR_REGISTRY" "$1" "$2" "REGISTRY"
}

# Docker error handler
handle_docker_error() {
    handle_error "$ERROR_DOCKER" "$1" "$2" "DOCKER"
}

# Kubernetes error handler
handle_kubernetes_error() {
    handle_error "$ERROR_KUBERNETES" "$1" "$2" "KUBERNETES"
}

# Network error handler
handle_network_error() {
    handle_error "$ERROR_NETWORK" "$1" "$2" "NETWORK"
}

# Validation error handler
handle_validation_error() {
    handle_error "$ERROR_VALIDATION" "$1" "$2" "VALIDATION"
}