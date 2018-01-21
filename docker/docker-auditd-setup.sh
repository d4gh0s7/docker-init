#!/bin/sh
set -e

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

configure_auditd_docker() {

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

    set -x

    if command_exists auditd; then
        # 1.5  - Ensure auditing is configured for the Docker daemon
        echo "-w /usr/bin/docker -p wa" | sudo tee -a /etc/audit/rules.d/audit.rules
        # 1.6  - Ensure auditing is configured for Docker files and directories - /var/lib/docker
        echo "-w /var/lib/docker -p wa" | sudo tee -a /etc/audit/rules.d/audit.rules
        # 1.7  - Ensure auditing is configured for Docker files and directories - /etc/docker"
        echo "-w /etc/docker -p wa" | sudo tee -a /etc/audit/rules.d/audit.rules
        # 1.8  - Ensure auditing is configured for Docker files and directories - docker.service
        echo "-w /lib/systemd/system/docker.service -p wa" | sudo tee -a /etc/audit/rules.d/audit.rules
        # 1.9  - Ensure auditing is configured for Docker files and directories - docker.socket
        echo "-w /lib/systemd/system/docker.socket -p wa" | sudo tee -a /etc/audit/rules.d/audit.rules
        # 1.10 - Ensure auditing is configured for Docker files and directories - /etc/default/docker
        echo "-w /etc/default/docker -p wa" | sudo tee -a /etc/audit/rules.d/audit.rules
        # 1.11 - Ensure auditing is configured for Docker files and directories - /etc/docker/daemon.json
        echo "-w /etc/docker/daemon.json -p wa" | sudo tee -a /etc/audit/rules.d/audit.rules
        # 1.12 - Ensure auditing is configured for Docker files and directories - /usr/bin/docker-containerd
        echo "-w /usr/bin/docker-containerd -p wa" | sudo tee -a /etc/audit/rules.d/audit.rules
        # 1.13 - Ensure auditing is configured for Docker files and directories - /usr/bin/docker-runc
        echo "-w /usr/bin/docker-runc -p wa" | sudo tee -a /etc/audit/rules.d/audit.rules

        $sh_c "service auditd restart"

		cat >&2 <<-'EOF'
        Success: auditd rules for docker have been configured.
        TODO: lock the audit configuration to prevent any modification of this file. 
        If you want to be able to modify the audit rules again after locking you will have to reboot for changes to take place
        -e 2
		EOF

        exit 0
    else
        $sh_c "yum-update && yum-install auditd"

		cat >&2 <<-'EOF'
		Error: auditd wasn't installed in your system, now it is.
		Configure it and run this script again.
		EOF

        exit 1
    fi
}

configure_auditd_docker