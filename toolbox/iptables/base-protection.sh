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

    # Create Protocol-Specific Chains
    $sh_c "iptables -N UDP"
    $sh_c "iptables -N TCP"
    $sh_c "iptables -N ICMP"
    
    # Allow ssh
    $sh_c "iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT"
    # $sh_c "iptables -A TCP -p tcp --dport 22 -j ACCEPT"

    # Accept all traffic that is part of an established connection or is related to an established connection
    $sh_c "iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
    # Accept incoming traffic for lo adapter
    $sh_c "iptables -A INPUT -i lo -j ACCEPT"
    # Drop invalid connection
    $sh_c "iptables -A INPUT -m conntrack --ctstate INVALID -j DROP"

    # Create the Jump Rules to the Protocol-Specific Chains
    $sh_c "iptables -A INPUT -p udp -m conntrack --ctstate NEW -j UDP"
    $sh_c "iptables -A INPUT -p tcp --syn -m conntrack --ctstate NEW -j TCP"
    $sh_c "iptables -A INPUT -p icmp -m conntrack --ctstate NEW -j ICMP"

    # Drop incoming and outgoing ICMP and incoming UDP
    $sh_c "iptables -A OUTPUT -p icmp --icmp-type 8 -j DROP"
    $sh_c "iptables -I INPUT -p icmp --icmp-type 8 -j DROP"
    $sh_c "iptables -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable"

    # Drop port scans - very basic
    $sh_c "iptables -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j DROP"

    # Defaults
    # $sh_c "iptables -P INPUT DROP"
    # $sh_c "iptables -P FORWARD DROP"

    # Drop ipv6
    $sh_c "ip6tables -P INPUT DROP"
    $sh_c "ip6tables -P FORWARD DROP"
    $sh_c "ip6tables -P OUTPUT DROP"
}

configure_base_protection