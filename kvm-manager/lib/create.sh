#!/usr/bin/env bash

create_command() {
    require_command virt-install

    cat <<EOF
Interactive VM creation is delegated to virt-install.

Example:
  virt-install \\
    --name ubuntu01 \\
    --memory 4096 \\
    --vcpus 2 \\
    --disk size=30 \\
    --cdrom /path/to/installer.iso \\
    --os-variant ubuntu24.04
EOF
}
