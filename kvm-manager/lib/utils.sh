#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
BOLD='\033[1m'
RESET='\033[0m'

log_file=""

ensure_runtime_dirs() {
    mkdir -p "$BASE_DIR/${LOG_DIR#./}" "$BASE_DIR/${BACKUP_DIR#./}"
    log_file="$BASE_DIR/${LOG_DIR#./}/kvm-manager-$(date +%F).log"
}

log_msg() {
    local level=$1
    shift
    printf '%s [%s] %s\n' "$(date '+%F %T')" "$level" "$*" >>"$log_file"
}

die() {
    echo -e "${RED}Error:${RESET} $*" >&2
    log_msg ERROR "$*"
    exit 1
}

warn() {
    echo -e "${YELLOW}Warning:${RESET} $*" >&2
    log_msg WARN "$*"
}

ok() {
    echo -e "${GREEN}$*${RESET}"
    log_msg INFO "$*"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "$1 is not installed or not in PATH."
}

require_virsh() {
    require_command virsh
    virsh list >/dev/null 2>&1 || die "cannot connect to libvirt. Try sudo or check libvirt service."
}

confirm_exact() {
    local prompt=$1
    local expected=$2
    local answer

    read -rp "$prompt " answer
    [[ "$answer" == "$expected" ]]
}

vm_exists() {
    virsh dominfo "$1" >/dev/null 2>&1
}

require_vm() {
    local vm=${1:-}
    [[ -n "$vm" ]] || die "VM name is required."
    vm_exists "$vm" || die "VM '$vm' does not exist."
}

vm_state() {
    virsh domstate "$1" 2>/dev/null || printf 'unknown'
}

vm_os() {
    local os_name

    os_name=$(virsh guestinfo "$1" 2>/dev/null \
        | awk -F: 'tolower($1) ~ /os.pretty-name/ {sub(/^[ \t]+/, "", $2); print $2; exit}')

    [[ -n "$os_name" ]] && printf '%s\n' "$os_name" || printf 'Unknown/Agent Off\n'
}

vm_ips() {
    local vm=$1
    local ips

    ips=$(virsh domifaddr "$vm" --source agent 2>/dev/null \
        | awk '/ipv4/ {split($4, ip, "/"); print ip[1]}')

    if [[ -z "$ips" ]]; then
        ips=$(virsh domifaddr "$vm" --source lease 2>/dev/null \
            | awk '/ipv4/ {split($4, ip, "/"); print ip[1]}')
    fi

    if [[ -n "$ips" ]]; then
        printf '%s\n' "$ips" | paste -sd ',' -
    else
        printf 'N/A\n'
    fi
}

vm_list_names() {
    virsh list --all --name | awk 'NF'
}

bytes_to_human() {
    local kib=${1:-0}
    awk -v kib="$kib" 'BEGIN {
        if (kib >= 1048576) printf "%.1f GiB", kib / 1048576
        else if (kib >= 1024) printf "%.1f MiB", kib / 1024
        else printf "%.0f KiB", kib
    }'
}

vm_vcpus() {
    local count
    count=$(virsh vcpucount "$1" --live 2>/dev/null | awk '/^[[:space:]]*[0-9]+[[:space:]]*$/ {gsub(/[[:space:]]/, ""); print; exit}')
    [[ -n "$count" ]] || count=$(virsh vcpucount "$1" --config 2>/dev/null | awk '/^[[:space:]]*[0-9]+[[:space:]]*$/ {gsub(/[[:space:]]/, ""); print; exit}')
    printf '%s\n' "${count:-N/A}"
}

# Returns a compact "used / allocated (percent)" value when balloon statistics
# are available. Guests without the QEMU guest agent or balloon driver show N/A.
vm_memory_usage() {
    local vm=$1 actual unused used percent

    [[ "$(vm_state "$vm")" == "running" ]] || {
        printf 'N/A\n'
        return
    }

    actual=$(virsh dommemstat "$vm" 2>/dev/null | awk '$1 == "actual" {print $2; exit}')
    unused=$(virsh dommemstat "$vm" 2>/dev/null | awk '$1 == "unused" {print $2; exit}')

    if [[ "$actual" =~ ^[0-9]+$ && "$unused" =~ ^[0-9]+$ && "$actual" -gt 0 ]]; then
        (( unused > actual )) && unused=$actual
        used=$((actual - unused))
        percent=$((used * 100 / actual))
        printf '%s / %s (%s%%)\n' "$(bytes_to_human "$used")" "$(bytes_to_human "$actual")" "$percent"
    elif [[ "$actual" =~ ^[0-9]+$ && "$actual" -gt 0 ]]; then
        printf 'Allocated %s\n' "$(bytes_to_human "$actual")"
    else
        printf 'N/A\n'
    fi
}

# CPU time is sampled over a short interval and normalised against the guest's
# configured vCPUs. This makes 100% mean that all of the guest's vCPUs are busy.
# It is intentionally calculated per VM so it works with older libvirt releases.
vm_cpu_usage() {
    local vm=$1 first second elapsed vcpus percent

    [[ "$(vm_state "$vm")" == "running" ]] || {
        printf 'N/A\n'
        return
    }

    first=$(virsh domstats "$vm" --cpu-total 2>/dev/null | awk -F= '$1 ~ /cpu.time$/ {print $2; exit}')
    [[ "$first" =~ ^[0-9]+$ ]] || {
        printf 'N/A\n'
        return
    }

    # Bash's EPOCHREALTIME is not available on every supported distribution.
    sleep 0.2
    second=$(virsh domstats "$vm" --cpu-total 2>/dev/null | awk -F= '$1 ~ /cpu.time$/ {print $2; exit}')
    [[ "$second" =~ ^[0-9]+$ && "$second" -ge "$first" ]] || {
        printf 'N/A\n'
        return
    }

    vcpus=$(vm_vcpus "$vm")
    [[ "$vcpus" =~ ^[1-9][0-9]*$ ]] || vcpus=1
    elapsed=200000000
    percent=$(( (second - first) * 100 / elapsed / vcpus ))
    printf '%s%%\n' "$percent"
}
