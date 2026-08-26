#!/usr/bin/env bash

dashboard_header() {
    printf "${BOLD}%-4s %-22s %-11s %-6s %-9s %-30s %-30s${RESET}\n" \
        "No." "Guest VM" "State" "vCPU" "CPU" "Memory utilisation" "IP address"
    printf '%s\n' "--------------------------------------------------------------------------------------------------------------------"
}

dashboard_vm_names() {
    local filter=${1:---all}
    local vm

    while IFS= read -r vm; do
        [[ "$filter" == "--running" || "$FILTER_RUNNING_ONLY" != "true" || "$(vm_state "$vm")" == "running" ]] || continue
        printf '%s\n' "$vm"
    done < <(vm_list_names)
}

dashboard_command() {
    local filter=${1:---all}
    local index=1
    local vm state ips color vcpus cpu memory

    [[ "$filter" == "--running" || "$filter" == "--all" || "$filter" == "" ]] || die "use --all or --running."

    dashboard_header

    while IFS= read -r vm; do
        state=$(vm_state "$vm")

        ips=$(vm_ips "$vm")
        vcpus=$(vm_vcpus "$vm")
        cpu=$(vm_cpu_usage "$vm")
        memory=$(vm_memory_usage "$vm")

        case "$state" in
            running) color=$GREEN ;;
            "shut off") color=$RED ;;
            paused) color=$YELLOW ;;
            *) color=$CYAN ;;
        esac

        printf "%-4s %-22.22s ${color}%-11s${RESET} %-6s %-9s %-30.30s %-30.30s\n" \
            "$index" "$vm" "$state" "$vcpus" "$cpu" "$memory" "$ips"
        index=$((index + 1))
    done < <(dashboard_vm_names "$filter")

    [[ "$index" -gt 1 ]] || echo "No VMs found."
}

guest_summary() {
    local vm=$1 state color
    state=$(vm_state "$vm")
    case "$state" in
        running) color=$GREEN ;;
        "shut off") color=$RED ;;
        paused) color=$YELLOW ;;
        *) color=$CYAN ;;
    esac

    clear
    echo -e "${BOLD}Guest VM details${RESET}"
    printf '%s\n' "------------------------------------------------------------"
    printf '%-20s %s\n' "Guest:" "$vm"
    printf '%-20s ' "State:"
    echo -e "${color}${state}${RESET}"
    printf '%-20s %s\n' "Operating system:" "$(vm_os "$vm")"
    printf '%-100s %s\n' "IP address:" "$(vm_ips "$vm")"
    printf '%-20s %s\n' "vCPUs:" "$(vm_vcpus "$vm")"
    #printf '%-20s %s\n' "CPU utilisation:" "$(vm_cpu_usage "$vm")"
    printf '%-100s %s\n' "Memory utilisation:" "$(vm_memory_usage "$vm")"
    printf '%s\n' "-----------------------------------------------------------"
}

dashboard_menu() {
    local choice vm option
    local -a vms

    while true; do
        clear
        mapfile -t vms < <(dashboard_vm_names --all)
        dashboard_command --all

        echo
        read -rp "Select VM number, R to refresh, or Q to quit: " choice
        case "$choice" in
            q|Q) return 0 ;;
            r|R) continue ;;
            ''|*[!0-9]*) continue ;;
        esac

        (( choice >= 1 && choice <= ${#vms[@]} )) || continue
        vm=${vms[$((choice - 1))]}

        guest_summary "$vm"
        echo "1. Refresh guest metrics"
        echo "2. Full guest information"
        echo "3. Start"
        echo "4. Shutdown"
        echo "5. Reboot"
        echo "6. Force stop"
        echo "7. Snapshots"
        echo "8. Storage"
        echo "9. Network"
        echo "10. Live monitor"
        echo "11. Console"
        echo "12. ssh"
        echo "13. Delete"
        echo "14. Back to guest list"
        read -rp "Choose option: " option

        case "$option" in
            1) continue ;;
            2) info_command "$vm" ;;
            3) power_command start "$vm" ;;
            4) power_command shutdown "$vm" ;;
            5) power_command reboot "$vm" ;;
            6) power_command destroy "$vm" ;;
            7) snapshot_command list "$vm" ;;
            8) storage_command "$vm" ;;
            9) network_command "$vm" ;;
            10) monitor_command "$vm" ;;
            11) console_command "$vm" ;;
	    12) ssh_command  ;;
            13) power_command delete "$vm" ;;
            14) continue ;;
            *) echo "Invalid option." ;;
        esac

        echo
        read -rp "Press ENTER to continue..."
    done
}
