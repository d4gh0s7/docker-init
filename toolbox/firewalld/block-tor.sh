#!/bin/sh
set -e

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

apply_block() {

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

	if !command_exists wget; then
        $sh_c "yum install -y wget"
    fi

	set -x

    public_ip="$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')"
    tor_nodes="tor_nodes.list"
    $sh_c "wget -O $tor_nodes https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=$public_ip"

    if command_exists firewall-cmd; then
        for node in `/bin/grep -v -e ^# $tor_nodes` 
        do
            firewall-cmd --add-rich-rule='rule family="ipv4" source address="'$node'" drop'
        done
    else
        $sh_c "/sbin/iptables -N TORBLOCK"
        $sh_c "/sbin/iptables -F TORBLOCK"
        $sh_c "/sbin/iptables -I TORBLOCK -j RETURN"
        $sh_c "/sbin/iptables -I TORBLOCK -j RETURN"

        for node in `/bin/grep -v -e ^# $tor_nodes` 
        do
            /sbin/iptables -I TORBLOCK -s $node -j DROP
        done
    fi
    
    exit 0
}

apply_block
