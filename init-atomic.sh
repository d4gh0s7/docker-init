#!/bin/sh
set -e

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

tune_selinux() {
	sh_c='sh -c'

	$sh_c "semanage port -a -t ssh_port_t -p tcp 11260"
	$sh_c "semanage port -a -t http_port_t -p tcp 11267"
	$sh_c "semanage port -a -t http_port_t -p tcp 11269"

	# Docker
	$sh_c "setsebool -P daemons_dump_core 1"
	$sh_c "setsebool -P daemons_use_tcp_wrapper 1"
	$sh_c "setsebool -P daemons_use_tty 1"
}

build_layout() {
	sh_c='sh -c'
	workdir='/opt/layout'
	$sh_c "mkdir -p $workdir/usr/local/bin"

	$sh_c "rm -rf /etc/ssh/sshd_config && \
		   rm -rf /etc/sysctl.d/99-sysctl.conf && \
		   rm -rf /etc/issue && \
		   rm -rf /etc/issue.net"

	# Get the hardenend system layout
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/ssh/sshd_config -o /etc/ssh/sshd_config"
    $sh_c "sed -i -e \"s/11260/22/\" /etc/ssh/sshd_config"
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/sysctl.d/99-sysctl.conf -o /etc/sysctl.d/99-sysctl.conf"
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/issue -o /etc/issue"
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/issue -o /etc/issue.net"

	# modprob.d blacklist files
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/modprobe.d/blacklist-usb.conf -o /etc/modprobe.d/blacklist-usb.conf"
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/modprobe.d/blacklist-firewire.conf -o /etc/modprobe.d/blacklist-firewire.conf"
	
	# Reload the kernel's value hardened
	$sh_c "sysctl -p"
}

get_toolbox() {
	sh_c='sh -c'
	workdir='/opt/toolbox'

	# acme.sh Let's Encrypt Client https://get.acme.sh ^_^
	$sh_c "mkdir -p $workdir/acme"
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/vendor/acme/acme.sh -o  $workdir/acme/acme.sh"

	# gosync https://github.com/webdevops/go-sync/releases
	$sh_c "mkdir -p $workdir/go"
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/toolbox/go/go-sync -o $workdir/go/go-sync"

	# go-replace https://github.com/webdevops/go-replace
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/toolbox/go/go-replace -o $workdir/go/go-replace"

	# go-crond https://github.com/webdevops/go-crond/releases
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/toolbox/go/go-crond -o $workdir/go/go-crond"

	# go-syslogd https://github.com/webdevops/go-syslogd/releases
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/toolbox/go/go-syslogd -o $workdir/go/go-syslogd"
	# go-syslog base config file
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/go-syslog.yml -o /etc/go-syslog.yml"

	$sh_c "chmod +x $workdir/go/go-*"
	$sh_c "ln -s $workdir/go/* /usr/local/bin"
}

install_golang() {
	sh_c='sh -c'

	$sh_c "curl -fsSL https://storage.googleapis.com/golang/go1.9.2.linux-amd64.tar.gz -o go.tar.gz"
	$sh_c "tar --no-same-permissions -xf go.tar.gz"
	$sh_c "cp -r go /usr/local"
	$sh_c "chmod +x /usr/local/go/bin/go"
	$sh_c "echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.bashrc"
}

init_system() {

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

	# Set the proper locale
	$sh_c "touch /etc/environment"
	$sh_c "echo 'LANG=en_US.utf-8' > /etc/environment"
	$sh_c "echo 'LC_ALL=en_US.utf-8' >> /etc/environment"

	# Base system layout
	$sh_c "rpm-ostree upgrade"

	# Set the correct Timezone and enable ntpd for time sync
	$sh_c "timedatectl set-timezone Europe/Athens && timedatectl"

	# Build system layout
	build_layout

	# Get the toolbox
	get_toolbox

	# Install golang
	install_golang

	# Docker compose
	$sh_c "curl -fsSL https://github.com/docker/compose/releases/download/1.18.0/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose"
	$sh_c "chmod +x /usr/local/bin/docker-compose"

	# docker bash completion
	$sh_c "curl -L https://raw.githubusercontent.com/docker/docker/v$(docker -v | cut -d' ' -f3 | tr -d ',')/contrib/completion/bash/docker > /etc/bash_completion.d/docker"
	
	# docker-compose bash completion
	$sh_c "curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose"

	### Docker hardening
	# Several
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/docker/daemon.json -o /etc/docker/daemon.json"
# {
#     "disable-legacy-registry": true,
#     "live-restore": true,
#     "userland-proxy": false,
#     "userns-remap": "default"
# }
	$sh_c "groupadd dockremap"
	$sh_c "useradd -g dockremap dockremap -s /sbin/nologin -M"
	$sh_c "echo 'dockremap:808080:1000' >> /etc/subuid"
	$sh_c "echo 'dockremap:808080:1000' >> /etc/subgid"
	# $sh_c "echo 'dockremap:165536:65536' >> /etc/subuid"
	# $sh_c "echo 'dockremap:165536:65536' >> /etc/subgid"

	# 1.5, 1.6, 1.7  - Ensure auditing is configured for the Docker daemon and files and directories - /var/lib/docker, /etc/docker
	$sh_c "mkdir -p /opt/docker"
	$sh_c "curl -fsSL https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/docker/docker-auditd-setup.sh -o /opt/docker/docker-auditd-setup.sh"
	$sh_c "chmod +x /opt/docker/docker-auditd-setup.sh"
	$sh_c "/opt/docker/docker-auditd-setup.sh"

	# 4.5  - Ensure Content trust for Docker is Enabled
	# echo "DOCKER_CONTENT_TRUST=1" | sudo tee -a /etc/environment

	# 1.1  - Ensure a separate partition for containers has been created
	# $sh_c "mkdir -p /mnt/docker-data-store"
	# $sh_c "echo '/var/lib/docker /mnt/docker-data-store  bind  defaults,bind 0 0' >> /etc/fstab"

	# Enable user namespace [requires reboot] - disable it as follows: 
	# grubby --remove-args="user_namespace.enable=1" --update-kernel=$(grubby --default-kernel)
	grubby --args="user_namespace.enable=1" --update-kernel=$(grubby --default-kernel)
	grubby --args="namespace.unpriv_enable=1" --update-kernel=$(grubby --default-kernel)
	$sh_c "echo \"user.max_user_namespaces=15076\" >> /etc/sysctl.d/99-sysctl.conf"
	$sh_c "sysctl -p"

	# Tune selinux
	tune_selinux

	cat >&2 <<-'EOF'

	  All done. The system requires a reboot ASAP and some testing.

	EOF
	
	exit 0

	# intentionally mixed spaces and tabs here -- tabs are stripped by "<<-'EOF'", spaces are kept in the output
	cat >&2 <<-'EOF'

	  Either your platform is not easily detectable, is not supported by this
	  installer script (yet - PRs welcome! [hack/install.sh]), or does not yet have
	  a package for Docker.  Please visit the following URL for more detailed
	  installation instructions:

	    https://docs.docker.com/engine/installation/

	EOF
	exit 1
}

# wrapped up in a function so that we have some protection against only getting
# half the file during "curl | sh"
init_system
