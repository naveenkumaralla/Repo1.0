#!/usr/bin/env bash

backup_command() {
    local vm=${1:-}
    local dest

    require_vm "$vm"
    require_command cp

    dest="$BASE_DIR/${BACKUP_DIR#./}/$vm-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$dest"

    virsh dumpxml "$vm" >"$dest/$vm.xml"
    virsh domblklist "$vm" --details >"$dest/block-devices.txt"

    while read -r _type device _target source; do
        [[ "$device" == "disk" && -f "$source" ]] || continue
        echo "Copying $source"
        cp --reflink=auto --sparse=always "$source" "$dest/"
    done < <(virsh domblklist "$vm" --details | awk 'NR>2 {print $2, $3, $4, $5}')

    ok "Backup saved to $dest"
}
