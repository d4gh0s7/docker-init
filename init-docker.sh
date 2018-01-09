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

do_install() {

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

	curl=''
	if command_exists curl; then
		curl='curl -sSL'
	elif command_exists wget; then
		curl='wget -qO-'
	elif command_exists busybox && busybox --list-modules | grep -q wget; then
		curl='busybox wget -qO-'
	fi

	set -x
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
        net-tools \
        ca-certificates \
        nss \
        rkhunter \
		ntp"

	$sh_c "timedatectl set-timezone Europe/Athens && timedatectl && systemctl start ntpd && systemctl enable ntpd"

    $sh_c "yum install -y yum-utils \
            device-mapper-persistent-data \
            lvm2"
    $sh_c "yum-config-manager \
                --add-repo \
                https://download.docker.com/linux/centos/docker-ce.repo"

	$sh_c "sleep 3; yum -y -q install docker-ce-17.09.1.ce-1.el7.centos"

	$sh_c "systemctl start docker"
	$sh_c "systemctl enable docker"

	$sh_c "rm -rf /etc/ssh/sshd_config && rm -rf /etc/sysctl.d/99-sysctl.conf && rm -rf /etc/login.defs"
	$sh_c "wget https://raw.githubusercontent.com/d4gh0s7/CentOS-Node-Init/master/layout/etc/login.defs"
	$sh_c "wget https://raw.githubusercontent.com/d4gh0s7/CentOS-Node-Init/master/layout/etc/ssh/sshd_config"
	$sh_c "wget https://raw.githubusercontent.com/d4gh0s7/CentOS-Node-Init/master/layout/etc/sysctl/99-sysctl.conf"
	
	$sh_c "cp login.defs /etc/login.defs && cp 99-sysctl.conf /etc/sysctl.d/99-sysctl.conf && cp sshd_config /etc/ssh/sshd_config"

	$sh_c "sysctl -p"

    echo_docker_as_nonroot
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
do_install