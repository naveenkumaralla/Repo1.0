#!/usr/bin/env bash

clone_command() {
    local source_vm=${1:-}
    local new_vm=${2:-}

    require_command virt-clone
    require_vm "$source_vm"
    [[ -n "$new_vm" ]] || die "new VM name is required."
    vm_exists "$new_vm" && die "VM '$new_vm' already exists."

    virt-clone --original "$source_vm" --name "$new_vm" --auto-clone
    ok "Cloned '$source_vm' to '$new_vm'."
}
