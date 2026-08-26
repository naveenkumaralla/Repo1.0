#!/usr/bin/env bash

info_command() {
    local vm=${1:-}
    require_vm "$vm"

    echo -e "${BOLD}VM:${RESET} $vm"
    echo -e "${BOLD}State:${RESET} $(vm_state "$vm")"
    echo -e "${BOLD}OS:${RESET} $(vm_os "$vm")"
    echo -e "${BOLD}IP:${RESET} $(vm_ips "$vm")"
    echo
    virsh dominfo "$vm"
}
