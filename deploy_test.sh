setup_vm_docker() {
    if [ "$DOCKER_CLI_AVAILABLE" = true ] && [ "$DOCKER_DAEMON_RUNNING" = true ] && [ "$DOCKER_NO_SUDO_WORKING" = true ]; then
        echo "All good"
    elif [ "$DOCKER_CLI_AVAILABLE" = true ] && [ "$DOCKER_DAEMON_RUNNING" = true ] && [ "$DOCKER_NO_SUDO_WORKING" = false ]; then
        echo "Group issue"
    elif [ "$DOCKER_CLI_AVAILABLE" = true ] && [ "$DOCKER_DAEMON_RUNNING" = false ]; then
        echo "Daemon issue"
    elif [ "$DOCKER_CLI_AVAILABLE" = false ] && [ "$DOCKER_DAEMON_RUNNING" = true ]; then
        echo "CLI issue"
    else
        echo "Complete failure"
    fi
}
