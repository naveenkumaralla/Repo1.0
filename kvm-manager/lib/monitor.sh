#!/usr/bin/env bash

monitor_command() {
    local vm=${1:-}

    if [[ -n "$vm" ]]; then
        require_vm "$vm"
        echo -e "${BOLD}CPU stats:${RESET}"
        virsh cpu-stats "$vm" || true
        echo
        echo -e "${BOLD}Memory stats:${RESET}"
        virsh dommemstat "$vm" || true
        echo
        echo -e "${BOLD}Block stats:${RESET}"
        virsh domblklist "$vm" | awk 'NR>2 {print $1}' | while read -r target; do
            [[ -n "$target" && "$target" != "-" ]] || continue
            echo "[$target]"
            virsh domblkstat "$vm" "$target" || true
        done
    else
        virsh list --all
        echo
        virsh nodeinfo
    fi
}
