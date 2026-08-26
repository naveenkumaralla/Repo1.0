#!/usr/bin/env bash

snapshot_command() {
    local action=${1:-}
    local vm=${2:-}
    local snapshot=${3:-}

    require_vm "$vm"

    case "$action" in
        list)
            virsh snapshot-list "$vm"
            ;;
        create)
            [[ -n "$snapshot" ]] || snapshot="${SNAPSHOT_PREFIX}-$(date +%Y%m%d-%H%M%S)"
            virsh snapshot-create-as --domain "$vm" --name "$snapshot" --description "Created by kvm-manager"
            ;;
        revert)
            [[ -n "$snapshot" ]] || die "snapshot name is required."
            confirm_exact "Revert '$vm' to '$snapshot'? Type yes to continue:" "yes" || die "cancelled."
            virsh snapshot-revert "$vm" "$snapshot"
            ;;
        delete)
            [[ -n "$snapshot" ]] || die "snapshot name is required."
            confirm_exact "Delete snapshot '$snapshot'? Type yes to continue:" "yes" || die "cancelled."
            virsh snapshot-delete "$vm" "$snapshot"
            ;;
        *) die "usage: snapshot list|create|revert|delete <vm> [snapshot]" ;;
    esac
}
