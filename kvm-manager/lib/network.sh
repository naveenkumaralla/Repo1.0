#!/usr/bin/env bash

network_command() {
    local vm=${1:-}
    require_vm "$vm"

    echo -e "${BOLD}Interfaces:${RESET}"
    virsh domiflist "$vm"

    echo
    echo -e "${BOLD}Addresses:${RESET}"
    virsh domifaddr "$vm" --source agent 2>/dev/null || virsh domifaddr "$vm" --source lease 2>/dev/null || true
}
