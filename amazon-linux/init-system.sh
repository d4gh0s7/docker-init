#!/bin/sh
set -e

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

# tune_selinux() {
# 	sh_c='sh -c'

# 	$sh_c "semanage port -a -t ssh_port_t -p tcp 11260"
# 	$sh_c "semanage port -a -t http_port_t -p tcp 11269"

# 	$sh_c "restorecon -Rv /opt/*"
# 	$sh_c "restorecon -Rv /mnt/*"

# 	$sh_c "setsebool -P virt_sandbox_use_fusefs 1"
# }

build_layout() {
	sh_c='sh -c'
	workdir='/opt/layout'
	$sh_c "mkdir -p $workdir/usr/bin"

	# Get the yum wrappers
	$sh_c "wget -O $workdir/usr/bin/yum-cleanup  https://raw.githubusercontent.com/d4gh0s7/docker-init/master/layout/usr/bin/yum-cleanup"
	$sh_c "wget -O $workdir/usr/bin/yum-install  https://raw.githubusercontent.com/d4gh0s7/docker-init/master/layout/usr/bin/yum-install"
	$sh_c "wget -O $workdir/usr/bin/yum-upgrade  https://raw.githubusercontent.com/d4gh0s7/docker-init/master/layout/usr/bin/yum-upgrade"
	$sh_c "wget -O $workdir/usr/bin/yum-update  https://raw.githubusercontent.com/d4gh0s7/docker-init/master/layout/usr/bin/yum-update"

	$sh_c "chmod +x $workdir/usr/bin/yum-*"
	$sh_c "ln -s $workdir/usr/bin/* /usr/bin"

	$sh_c "rm -rf /etc/ssh/sshd_config && \
	 	   rm -rf /etc/issue && \
	 	   rm -rf /etc/issue.net && \
	 	   rm -rf /etc/login.defs
	 	   rm -rf /etc/profile && \
	 	   rm -rf /etc/bashrc"

	# Get the hardenend system layout
	$sh_c "wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/d4gh0s7/docker-init/master/amazon-linux/layout/etc/ssh/sshd_config"
	$sh_c "wget -O /etc/issue https://raw.githubusercontent.com/d4gh0s7/docker-init/master/layout/etc/issue"
	$sh_c "wget -O /etc/issue.net https://raw.githubusercontent.com/d4gh0s7/docker-init/master/layout/etc/issue"
	$sh_c "wget -O /etc/login.defs https://raw.githubusercontent.com/d4gh0s7/docker-init/master/amazon-linux/layout/etc/login.defs"
	$sh_c "wget -O /etc/profile https://raw.githubusercontent.com/d4gh0s7/docker-init/master/amazon-linux/layout/etc/profile"
	$sh_c "wget -O /etc/bashrc https://raw.githubusercontent.com/d4gh0s7/docker-init/master/amazon-linux/layout/etc/etc/bashrc"

	$sh_c "sed -i -e \"s/022/077/\" /etc/init.d/functions"
	# modprob.d blacklist files
	# $sh_c "wget -O /etc/modprobe.d/blacklist-usb.conf https://raw.githubusercontent.com/d4gh0s7/docker-init/master/layout/etc/modprobe.d/blacklist-usb.conf"
	# $sh_c "wget -O /etc/modprobe.d/blacklist-firewire.conf https://raw.githubusercontent.com/d4gh0s7/docker-init/master/layout/etc/modprobe.d/blacklist-firewire.conf"
	
	# Reload the kernel's value hardened
	$sh_c "sysctl -p"
}

get_toolbox() {
	sh_c='sh -c'
	workdir='/opt/toolbox'

	# gosync https://github.com/webdevops/go-sync/releases
	$sh_c "mkdir -p $workdir/go"
	$sh_c "wget -O $workdir/go/go-sync https://raw.githubusercontent.com/d4gh0s7/docker-init/master/toolbox/go/go-sync"

	# go-replace https://github.com/webdevops/go-replace
	$sh_c "wget -O $workdir/go/go-replace https://raw.githubusercontent.com/d4gh0s7/docker-init/master/toolbox/go/go-replace"

	# go-crond https://github.com/webdevops/go-crond/releases
	$sh_c "wget -O $workdir/go/go-crond https://raw.githubusercontent.com/d4gh0s7/docker-init/master/toolbox/go/go-crond"

	# go-syslogd https://github.com/webdevops/go-syslogd/releases
	$sh_c "wget -O $workdir/go/go-syslogd https://raw.githubusercontent.com/d4gh0s7/docker-init/master/toolbox/go/go-syslogd"
	# go-syslog base config file
	$sh_c "wget -O /etc/go-syslog.yml https://raw.githubusercontent.com/d4gh0s7/docker-init/master/layout/etc/go-syslog.yml"

	$sh_c "chmod +x $workdir/go/go-*"
	$sh_c "ln -s $workdir/go/* /usr/local/bin"
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

install_pip() {
	sh_c='sh -c'
	$sh_c "easy_install pip"
}

setup_supervisor() {
	sh_c='sh -c'
	$sh_c "easy_install supervisor"
	# $sh_c "echo_supervisord_conf > /etc/supervisord.conf"
	# $sh_c "mkdir /etc/supervisord.d/"
	# $sh_c "echo '[include]' | sudo tee -a /etc/supervisord.conf"
	# $sh_c "echo 'files = /etc/supervisord.d/*.conf' | sudo tee -a /etc/supervisord.conf"
	# $sh_c "wget -O /etc/rc.d/init.d/supervisord https://raw.githubusercontent.com/d4gh0s7/docker-init/master/layout/etc/rc.d/init.d/supervisord"
	# $sh_c "sed -i -e \"s/file=\/tmp\/supervisor.sock/file=\/var\/run\/supervisor.sock/\" /etc/supervisord.conf"
	# $sh_c "sed -i -e \"s/file=\/tmp\/supervisord.pid/file=\/var\/run\/supervisord.pid/\" /etc/supervisord.conf"
	# $sh_c "sed -i -e \"s/unix:\/\/\/tmp\/supervisor.sock/unix:\/\/\/var\/run\/supervisord.sock/\" /etc/supervisord.conf"
	# $sh_c "touch /var/run/supervisord.sock"

	# $sh_c "chmod +x /etc/rc.d/init.d/supervisord"
	# $sh_c "chkconfig --add supervisord"
	# $sh_c "chkconfig supervisord on"
	# $sh_c "service supervisord start"
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
	$sh_c "yum update -y && yum upgrade -y && yum install -y epel-release"
	$sh_c "yum update -y"
	$sh_c "yum provides '*/applydeltarpm' && yum install -y deltarpm"

	$sh_c "yum install -y \
        wget \
        curl \
        net-tools \
		libselinux \
		policycoreutils \
		policycoreutils-python \
		selinux-policy \
		selinux-policy-devel \
		libselinux-utils \
		selinux-policy-minimum \
		selinux-policy-mls \
		selinux-policy-targeted \
		policycoreutils \
        nano \
        vim \
        git \
        fuse \
        zip \
        unzip \
        bzip2 \
        rsync \
        arpwatch \
        ca-certificates \
        rkhunter \
		ntp \
		psacct \
		sysstat \
		aide \
		python-setuptools"

	# Set the correct Timezone and enable ntpd for time sync
	#$sh_c "timedatectl set-timezone Europe/Athens && timedatectl && systemctl start ntpd && systemctl enable ntpd"

	# Build system layout
	build_layout

	# Get the toolbox
	get_toolbox

	# Sysstat base setup
	setup_sysstat

	# Install golang
	install_golang

	# pip
	install_pip

	# supervisor
	setup_supervisor

	# configure repo and install lynis 
	$sh_c "echo -e '[lynis]\nname=CISOfy Software - Lynis package\nbaseurl=https://packages.cisofy.com/community/lynis/rpm/\nenabled=1\ngpgkey=https://packages.cisofy.com/keys/cisofy-software-rpms-public.key\ngpgcheck=1\n' > /etc/yum.repos.d/cisofy-lynis.repo"
	$sh_c "yum makecache fast && yum -y update && yum install -y lynis"

	# Docker ce-17.09.1.ce-1.el7.centos pre-requisites and installation
	$sh_c "yum install -y yum-utils \
		   device-mapper-persistent-data \
		   lvm2"

	# Cleanup the system
	$sh_c "yum-cleanup"

	# Enable user namespace [requires reboot] - disable it as follows: 
	# grubby --remove-args="user_namespace.enable=1" --update-kernel=$(grubby --default-kernel)
	grubby --args="user_namespace.enable=1" --update-kernel=$(grubby --default-kernel)
	grubby --args="namespace.unpriv_enable=1" --update-kernel=$(grubby --default-kernel)
	$sh_c "echo \"user.max_user_namespaces=15076\" >> /etc/sysctl.d/99-sysctl.conf"
	$sh_c "sysctl -p"

	# Tune selinux
	#tune_selinux

	cat >&2 <<-'EOF'

	  All done. The system requires a reboot ASAP and some testing.

	EOF
	
	exit 0

	# intentionally mixed spaces and tabs here -- tabs are stripped by "<<-'EOF'", spaces are kept in the output
	cat >&2 <<-'EOF'

	  Something went wrong.

	EOF
	exit 1
}

# wrapped up in a function so that we have some protection against only getting
# half the file during "curl | sh"
init_system
