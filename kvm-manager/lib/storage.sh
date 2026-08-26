#!/usr/bin/env bash

storage_command() {
    local vm=${1:-}
    require_vm "$vm"

    echo -e "${BOLD}Block Devices:${RESET}"
    virsh domblklist "$vm" --details

    echo
    echo -e "${BOLD}Block Stats:${RESET}"
    while read -r target source; do
        [[ "$target" == "Target" || "$target" == "-" || -z "$target" ]] && continue
        virsh domblkstat "$vm" "$target" 2>/dev/null || true
    done < <(virsh domblklist "$vm" | awk 'NR>2 {print $1, $2}')
}
