#!/bin/bash

# vm.sh - Manage the multipass VM for my-ag-ui-app
# Usage: ./vm.sh [start|stop|restart|status]

set -euo pipefail

VM_NAME="${VM_NAME:-my-ag-ui-app-k8s}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

get_vm_state() {
    multipass info "$VM_NAME" 2>/dev/null | grep "State:" | awk '{print $2}'
}

check_prerequisites() {
    if ! command -v multipass &>/dev/null; then
        log_error "multipass is not installed. Install from https://multipass.run/"
        exit 1
    fi

    if ! multipass list 2>/dev/null | grep -q "$VM_NAME"; then
        log_error "VM '$VM_NAME' not found. Available VMs:"
        multipass list
        exit 1
    fi
}

do_start() {
    local state
    state=$(get_vm_state)

    if [ "$state" = "Running" ]; then
        log_info "VM '$VM_NAME' is already running"
    else
        log_info "Starting VM '$VM_NAME'..."
        multipass start "$VM_NAME"
        log_success "VM '$VM_NAME' started"
    fi

    local ipv4
    ipv4=$(multipass info "$VM_NAME" | grep "IPv4:" | awk '{print $2}')
    log_info "IPv4: $ipv4"
}

do_stop() {
    local state
    state=$(get_vm_state)

    if [ "$state" = "Stopped" ] || [ "$state" = "Suspended" ]; then
        log_info "VM '$VM_NAME' is already $state"
    else
        log_info "Stopping VM '$VM_NAME'..."
        multipass stop "$VM_NAME"
        log_success "VM '$VM_NAME' stopped"
    fi
}

do_restart() {
    do_stop
    do_start
}

do_status() {
    local state
    state=$(get_vm_state)
    echo "VM '$VM_NAME' state: $state"

    if [ "$state" = "Running" ]; then
        multipass info "$VM_NAME"
    fi
}

check_prerequisites

ACTION="${1:-status}"

case "$ACTION" in
    start)   do_start   ;;
    stop)    do_stop    ;;
    restart) do_restart ;;
    status)  do_status  ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
