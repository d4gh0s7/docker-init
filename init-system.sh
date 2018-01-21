#!/bin/sh
set -e

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

echo_docker_as_nonroot() {
	if command_exists docker && [ -e /var/run/docker.sock ]; then
		(
			set -x
			$sh_c 'docker version'
		) || true
	fi
	your_user=your-user
	[ "$user" != 'root' ] && your_user="$user"
	# intentionally mixed spaces and tabs here -- tabs are stripped by "<<-EOF", spaces are kept in the output
	cat <<-EOF

	If you would like to use Docker as a non-root user, you should now consider
	adding your user to the "docker" group with something like:

	  sudo usermod -aG docker $your_user

	Remember that you will have to log out and back in for this to take effect!

	EOF
}

tune_selinux() {
	sh_c='sh -c'

	$sh_c "semanage port -a -t ssh_port_t -p tcp 11260"
	$sh_c "semanage port -a -t http_port_t -p tcp 11267"
	$sh_c "semanage port -a -t http_port_t -p tcp 11269"
}

build_layout() {
	sh_c='sh -c'
	workdir='/opt/layout'
	$sh_c "mkdir -p $workdir/usr/local/bin"

	# Get the yum wrappers
	$sh_c "wget -O $workdir/usr/local/bin/yum-cleanup  https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/usr/local/bin/yum-cleanup"
	$sh_c "wget -O $workdir/usr/local/bin/yum-install  https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/usr/local/bin/yum-install"
	$sh_c "wget -O $workdir/usr/local/bin/yum-upgrade  https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/usr/local/bin/yum-upgrade"
	$sh_c "wget -O $workdir/usr/local/bin/yum-update  https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/usr/local/bin/yum-update"

	$sh_c "chmod +x /opt/layout/usr/local/bin/yum-*"
	$sh_c "ln -s $workdir/usr/local/bin/* /usr/local/bin"

	# Prepare the room for an hardenend system layout
	$sh_c "rm -rf /etc/ssh/sshd_config && \
		   rm -rf /etc/sysctl.d/99-sysctl.conf && \ 
		   rm -rf /etc/login.defs && \
		   rm -rf /etc/issue && \
		   rm -rf /etc/issue.net && \
		   rm -rf /etc/profile && \
		   rm -rf /etc/bashrc && \
		   rm -rf /etc/init.d/functions && \
		   rm -rf /etc/postfix/main.cf"

	# Get the hardenend system layout
	$sh_c "wget -O /etc/login.defs https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/login.defs"
	$sh_c "wget -O /etc/sysctl.d/99-sysctl.conf https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/sysctl.d/99-sysctl.conf"
	$sh_c "wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/ssh/sshd_config"
	$sh_c "wget -O /etc/issue https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/issue"
	$sh_c "wget -O /etc/issue.net https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/issue"
	$sh_c "wget -O /etc/postfix/main.cf https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/postfix/main.cf"
	$sh_c "wget -O /etc/bashrc https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/bashrc"
	$sh_c "wget -O /etc/init.d/functions https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/init.d/functions"
	$sh_c "wget -O /etc/profile https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/profile"

	# modprob.d blacklist files
	$sh_c "wget -O /etc/modprobe.d/blacklist-usb.conf https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/modprobe.d/blacklist-usb.conf"
	$sh_c "wget -O /etc/modprobe.d/blacklist-firewire.conf https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/modprobe.d/blacklist-firewire.conf"
	
	# Reload the kernel's value hardened
	$sh_c "sysctl -p"
}

get_toolbox() {
	sh_c='sh -c'
	workdir='/opt/toolbox'

	# Firewalld Tor Blocker
	$sh_c "mkdir -p $workdir/firewalld"
	$sh_c "wget -O $workdir/firewalld/tor-blocker.sh https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/toolbox/firewalld/tor-blocker.sh"
	$sh_c "chmod +x $workdir/firewalld/tor-blocker.sh"

	# Iptables Base Protection
	$sh_c "mkdir -p $workdir/iptables"
	$sh_c "wget -O $workdir/iptables/basic-protection.sh https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/toolbox/iptables/basic-protection.sh"
	$sh_c "chmod +x $workdir/iptables/basic-protection.sh"

	# acme.sh Let's Encrypt Client https://get.acme.sh ^_^
	$sh_c "mkdir -p $workdir/acme"
	$sh_c "wget -O $workdir/acme/acme.sh https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/vendor/acme/acme.sh"

	# gosync https://github.com/webdevops/go-sync/releases
	$sh_c "mkdir -p $workdir/go"
	$sh_c "wget -O $workdir/go/go-sync https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/toolbox/go/go-sync"

	# go-replace https://github.com/webdevops/go-replace
	$sh_c "wget -O $workdir/go/go-replace https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/toolbox/go/go-replace"

	# go-crond https://github.com/webdevops/go-crond/releases
	$sh_c "wget -O $workdir/go/go-crond https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/toolbox/go/go-crond"

	# go-syslogd https://github.com/webdevops/go-syslogd/releases
	$sh_c "wget -O $workdir/go/go-syslogd https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/toolbox/go/go-syslogd"
	# go-syslog base config file
	$sh_c "wget -O /etc/go-syslog.yml https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/go-syslog.yml"

	$sh_c "chmod +x $workdir/go/go-*"
	$sh_c "ln -s $workdir/go/* /usr/local/bin"
}

setup_process_accounting() {
	sh_c='sh -c'

	$sh_c "chkconfig psacct on"
	$sh_c "systemctl enable psacct"
	$sh_c "systemctl start psacct"

	$sh_c "touch /var/log/pacct"
	$sh_c "chown root /var/log/pacct"
	$sh_c "chmod 0644 /var/log/pacct"

	$sh_c "wget -O /etc/init.d/pacct https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/init.d/pacct"
	$sh_c "chmod +x /etc/init.d/pacct"
}

setup_arpwatch() {
	sh_c='sh -c'

	$sh_c "chkconfig --level 35 arpwatch on"
	$sh_c "systemctl enable arpwatch && systemctl start arpwatch"
	$sh_c "arpwatch -i eth0"
}

setup_sysstat() {
	sh_c='sh -c'

	$sh_c "touch /etc/default/sysstat"
	$sh_c "echo ENABLED=\"true\" > /etc/default/sysstat"
	$sh_c "service sysstat restart"
}

install_golang() {
	sh_c='sh -c'

	$sh_c "wget -O go.tar.gz https://storage.googleapis.com/golang/go1.9.2.linux-amd64.tar.gz"
	$sh_c "tar --no-same-permissions -xf go.tar.gz"
	$sh_c "cp -r go /usr/local"
	$sh_c "chmod +x /usr/local/go/bin/go"
	$sh_c "echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.bashrc"
}

configure_basic_protection() {
	sh_c='sh -c'

	# Download the Fail2Ban jails
	$sh_c "wget -O /etc/fail2ban/jail.d/10-sshd.conf https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/etc/fail2ban/jail.d/10-sshd.conf"
	
	# Download the rancher service configuration file
	$sh_c "wget -O /usr/lib/firewalld/services/rancher.xml https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/layout/usr/lib/firewalld/services/rancher.xml"
	
	# Enable and start the firewalld and fail2ban services 
	$sh_c "systemctl start firewalld && systemctl enable firewalld && systemctl start fail2ban && systemctl enable fail2ban"
	
	# Provision the ssh service to change the port to 11260
	$sh_c "sed -i -e \"s/22/11260/\" /usr/lib/firewalld/services/ssh.xml"
	
	$sh_c "firewall-cmd --zone=public --permanent --add-service=ssh"
	$sh_c "firewall-cmd --zone=public --permanent --add-service=http"
	$sh_c "firewall-cmd --zone=public --permanent --add-service=https"
	$sh_c "firewall-cmd --zone=public --permanent --add-service=rancher"
	$sh_c "firewall-cmd --zone=public --permanent --add-icmp-block={echo-request,echo-reply,address-unreachable,bad-header}"
	$sh_c "firewall-cmd --zone=public --permanent --add-icmp-block-inversion"
	$sh_c "firewall-cmd --reload"
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

	# curl=''
	# if command_exists curl; then
	# 	curl='curl -sSL'
	# elif command_exists wget; then
	# 	curl='wget -qO-'
	# elif command_exists busybox && busybox --list-modules | grep -q wget; then
	# 	curl='busybox wget -qO-'
	# fi

	set -x

	# Change the mount point of /tmp partition, using tmpfs filesystem limited to 2G size. 
	$sh_c "echo 'tmpfs     /tmp     tmpfs     rw,noexec,nosuid,nodev,bind,SIZE=2G     0 0' >> /etc/fstab"
	$sc_c "mount -a"

	# Set the proper locale
	$sh_c "touch /etc/environment"
	$sh_c "echo 'LANG=en_US.utf-8' > /etc/environment"
	$sh_c "echo 'LC_ALL=en_US.utf-8' >> /etc/environment"

	# Base system layout
	$sh_c "yum update -y && yum upgrade -y && yum install -y epel-release"
	$sh_c "yum update -y"
	$sh_c "yum provides '*/applydeltarpm' && yum install -y deltarpm"

	$sh_c "yum install -y \
        wget \
        curl \
        net-tools \
        tzdata \
        nano \
        vim \
        git \
        fuse \
        zip \
        unzip \
        bzip2 \
        moreutils \
        dnsutils \
        bind-utils \
        rsync \
        arpwatch \
        firewalld \
		fail2ban-firewalld \
        net-tools \
        ca-certificates \
        rkhunter \
		ntp \
		psacct \
		sysstat \
		aide"

	# Set the correct Timezone and enable ntpd for time sync
	$sh_c "timedatectl set-timezone Europe/Athens && timedatectl && systemctl start ntpd && systemctl enable ntpd"

	# Tune selinux
	tune_selinux

	# Build system layout
	build_layout

	# Get the toolbox
	get_toolbox

	# Setup process accounting
	setup_process_accounting

	# Arpwatch base setup
	setup_arpwatch

	# Sysstat base setup
	setup_sysstat

	# Install golang
	install_golang

	# firewalld and fail2ban
	configure_basic_protection	

	# configure repo and install lynis 
	$sh_c "echo -e '[lynis]\nname=CISOfy Software - Lynis package\nbaseurl=https://packages.cisofy.com/community/lynis/rpm/\nenabled=1\ngpgkey=https://packages.cisofy.com/keys/cisofy-software-rpms-public.key\ngpgcheck=1\n' > /etc/yum.repos.d/cisofy-lynis.repo"
	$sh_c "yum makecache fast && yum -y update && yum install -y lynis"

	# Docker ce-17.09.1.ce-1.el7.centos pre-requisites and installation
	$sh_c "yum install -y yum-utils \
		   device-mapper-persistent-data \
		   lvm2"
	$sh_c "yum-config-manager \
			--add-repo \
			https://download.docker.com/linux/centos/docker-ce.repo"

	$sh_c "sleep 3; yum-install docker-ce"

	$sh_c "systemctl start docker"
	$sh_c "systemctl enable docker"

	echo_docker_as_nonroot

	### Docker hardening
	# auditd
	$sh_c "mkdir -p /opt/docker"
	$sh_c "wget -O /opt/docker/docker-auditd-setup.sh https://raw.githubusercontent.com/d4gh0s7/centos-docker-init/master/docker/docker-auditd-setup.sh"
	$sh_c "chmod +x /opt/docker/docker-auditd-setup.sh"
	$sh_c "/opt/docker/docker-auditd-setup.sh"

	# Cleanup the system
	$sh_c "yum-cleanup"
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
