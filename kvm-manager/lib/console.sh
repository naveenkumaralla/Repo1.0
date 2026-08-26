#!/usr/bin/env bash

console_command() {
    local vm=${1:-}
    require_vm "$vm"

    [[ "$(vm_state "$vm")" == "running" ]] || die "VM '$vm' must be running for console access."
    virsh console "$vm"
}
