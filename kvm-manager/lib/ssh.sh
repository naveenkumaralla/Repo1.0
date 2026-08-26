#!/usr/bin/env bash

ssh_command() {
    local ssh_ips
    ssh_ips=$(vm_ips "$vm" | sed 's/,/\n/g' | grep -v '127.0.0.1')

    if [ -z "$ssh_ips" ]; then
        echo -e "${BOLD}Error:${RESET} No valid IPs found for $vm." >&2
        return 1
    fi

    while read -r ip; do
        [ -z "$ip" ] && continue

        echo -e "Attempting SSH connection to: ${BOLD}$ip${RESET}" >&2

        while true; do
            if [ -n "$SUDO_USER" ]; then
                # < /dev/tty reconnects your keyboard to the SSH process
                sudo -u "$SUDO_USER" ssh -t -o ConnectTimeout=5 "$ip" < /dev/tty
            else
                ssh -o ConnectTimeout=5 "$ip" < /dev/tty
            fi

            if [ $? -eq 0 ]; then
                echo -e "Successfully connected to and disconnected from $ip." >&2
                echo "$ip"
                return 0
            else
                echo "Connection failed to $ip. Retrying in 3 seconds..." >&2
                sleep 3
            fi
        done
    done <<< "$ssh_ips"
}

