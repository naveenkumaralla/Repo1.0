#!/usr/bin/env bash

power_command() {
    local action=${1:-}
    local vm=${2:-}

    require_vm "$vm"

    case "$action" in
        start)
            [[ "$(vm_state "$vm")" != "running" ]] || { echo "VM '$vm' is already running."; return 0; }
            virsh start "$vm"
            ;;
        shutdown)
            [[ "$(vm_state "$vm")" != "shut off" ]] || { echo "VM '$vm' is already stopped."; return 0; }
            virsh shutdown "$vm"
            ;;
        reboot)
            [[ "$(vm_state "$vm")" == "running" ]] || die "VM '$vm' must be running to reboot."
            virsh reboot "$vm"
            ;;
        destroy)
            [[ "$(vm_state "$vm")" != "shut off" ]] || { echo "VM '$vm' is already stopped."; return 0; }
            confirm_exact "Force-stop '$vm'? Type yes to continue:" "yes" || die "cancelled."
            virsh destroy "$vm"
            ;;
        delete)
            echo -e "${RED}${BOLD}WARNING:${RESET} this permanently deletes '$vm' and its storage."
            confirm_exact "Type DELETE to continue:" "DELETE" || die "cancelled."
            [[ "$(vm_state "$vm")" == "shut off" ]] || virsh destroy "$vm" >/dev/null 2>&1 || true
            virsh undefine "$vm" --remove-all-storage --nvram
            ;;
        *) die "unknown power action: $action" ;;
    esac

    log_msg INFO "$action requested for $vm"
}
