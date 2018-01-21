#!/bin/sh
set -e

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

configure_base_protection() {
    user="$(id -un 2>/dev/null || true)"

	sh_c='sh -c'
	if [ "$user" != 'root' ]; then
		if command_exists sudo; then
			sh_c='sudo -E sh -c'
		elif command_exists su; then
			sh_c='su -c'
		else
			cat >&2 <<-'EOF'
			Error: this installer needs the ability to run commands as root.
			We are unable to find either "sudo" or "su" available to make this happen.
			EOF
			exit 1
		fi
	fi

    # INPUT iptables Rules
    # Accept loopback input
    iptables -A INPUT -i lo -p all -j ACCEPT

    # Allow 3 way handshake
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    # DROP spoofing packets
    iptables -A INPUT -s 10.0.0.0/8 -j DROP 
    iptables -A INPUT -s 169.254.0.0/16 -j DROP
    iptables -A INPUT -s 172.16.0.0/12 -j DROP
    iptables -A INPUT -s 127.0.0.0/8 -j DROP
    iptables -A INPUT -s 192.168.0.0/24 -j DROP

    iptables -A INPUT -s 224.0.0.0/4 -j DROP
    iptables -A INPUT -d 224.0.0.0/4 -j DROP
    iptables -A INPUT -s 240.0.0.0/5 -j DROP
    iptables -A INPUT -d 240.0.0.0/5 -j DROP
    iptables -A INPUT -s 0.0.0.0/8 -j DROP
    iptables -A INPUT -d 0.0.0.0/8 -j DROP
    iptables -A INPUT -d 239.255.255.0/24 -j DROP
    iptables -A INPUT -d 255.255.255.255 -j DROP

    # Implement SMURF attack protection
    iptables -A INPUT -p icmp -m icmp --icmp-type address-mask-request -j DROP
    iptables -A INPUT -p icmp -m icmp --icmp-type timestamp-request -j DROP
    iptables -A INPUT -p icmp -m icmp -m limit --limit 1/second -j ACCEPT

    # Drop all invalid packets
    iptables -A INPUT -m state --state INVALID -j DROP
    iptables -A FORWARD -m state --state INVALID -j DROP
    iptables -A OUTPUT -m state --state INVALID -j DROP

    # Trying flooding of RST packets, smurf attack mitigation
    iptables -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT

    # Protecting portscans
    # Attacking IP will be locked for 24 hours (3600 x 24 = 86400 Seconds)
    iptables -A INPUT -m recent --name portscan --rcheck --seconds 86400 -j DROP
    iptables -A FORWARD -m recent --name portscan --rcheck --seconds 86400 -j DROP

    # Remove attacking IP after 24 hours
    iptables -A INPUT -m recent --name portscan --remove
    iptables -A FORWARD -m recent --name portscan --remove

    exit 0
}