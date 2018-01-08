#!/bin/bash

set -o pipefail
set -o errtrace
set -o nounset
set -o errexit

# if [ "$(/usr/bin/whoami)" != "root" ]; then
#     echo "[ERROR] Must be run as root"
#     exit 1
# fi

yum update -y && yum upgrade -y && yum install -y epel-release
yum update -y && yum upgrade -y

yum provides '*/applydeltarpm'
yum install -y deltarpm

# base layout

yum install -y \
        wget \
        curl \
        rkhunter

# timezone and ntpd
timedatectl set-timezone Europe/Athens
timedatectl

yum install -y ntp

systemctl start ntpd
systemctl enable ntpd

# lynis
echo -e '[lynis]\nname=CISOfy Software - Lynis package\nbaseurl=https://packages.cisofy.com/community/lynis/rpm/\nenabled=1\ngpgkey=https://packages.cisofy.com/keys/cisofy-software-rpms-public.key\ngpgcheck=1\n' > /etc/yum.repos.d/cisofy-lynis.repo
yum makecache fast
yum update -y  && yum install -y lynis

yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install -y docker-ce.x86_64

usermod -aG docker $USER
systemctl enable docker
systemctl start docker

mkdir -p /opt/toolbox && cd /opt/toolbox

# HARDENING
rm -rf /etc/ssh/sshd_config
rm -rf /etc/sysctl.d/99-sysctl.conf
rm -rf /etc/login.defs

mkdir -p /opt/etc
cd /opt/etc

wget https://raw.githubusercontent.com/d4gh0s7/CentOS-Node-Init/master/layout/etc/login.defs
wget https://raw.githubusercontent.com/d4gh0s7/CentOS-Node-Init/master/layout/etc/ssh/sshd_config
wget https://raw.githubusercontent.com/d4gh0s7/CentOS-Node-Init/master/layout/etc/sysctl/99-sysctl.conf

cp login.defs /etc/login.defs
cp 99-sysctl.conf /etc/sysctl.d/99-sysctl.conf
cp sshd_config /etc/ssh/sshd_config

sysctl -p
