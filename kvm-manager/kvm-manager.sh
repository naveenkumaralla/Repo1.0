#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=/dev/null
source "$BASE_DIR/config.conf"

for module in \
    utils dashboard power info snapshot storage network backup clone create monitor console ssh
do
    # shellcheck source=/dev/null
    source "$BASE_DIR/lib/${module}.sh"
done

usage() {
    cat <<EOF
Usage:
  $(basename "$0") dashboard
  $(basename "$0") menu
  $(basename "$0") list [--all|--running]
  $(basename "$0") info <vm>
  $(basename "$0") start|shutdown|reboot|destroy|delete <vm>
  $(basename "$0") snapshot list|create|revert|delete <vm> [snapshot]
  $(basename "$0") storage <vm>
  $(basename "$0") network <vm>
  $(basename "$0") backup <vm>
  $(basename "$0") clone <source_vm> <new_vm>
  $(basename "$0") create
  $(basename "$0") monitor [vm]
  $(basename "$0") console <vm>

Examples:
  $(basename "$0") list --all
  $(basename "$0") snapshot create ubuntu01 before-upgrade
  $(basename "$0") backup ubuntu01
EOF
}

run_command() {
    local command=${1:-}
    shift || true

    case "$command" in
        -h|--help|help|'') usage ;;
        dashboard|list) dashboard_command "$@" ;;
        menu) dashboard_menu ;;
        info) info_command "$@" ;;
        start|shutdown|reboot|destroy|delete) power_command "$command" "$@" ;;
        snapshot) snapshot_command "$@" ;;
        storage) storage_command "$@" ;;
        network) network_command "$@" ;;
        backup) backup_command "$@" ;;
        clone) clone_command "$@" ;;
        create) create_command "$@" ;;
        monitor) monitor_command "$@" ;;
        console) console_command "$@" ;;
        ssh) ssh_command "$@" ;;
        *) usage; return 1 ;;
    esac
}

main() {
    ensure_runtime_dirs

    case "${1:-}" in
        -h|--help|help|'')
            usage
            return 0
            ;;
    esac

    require_virsh
    run_command "$@"
}

main "$@"
