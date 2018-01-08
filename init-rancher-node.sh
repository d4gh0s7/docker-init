#!/bin/bash

set -o pipefail
set -o errtrace
set -o nounset
set -o errexit

if [ "$(/usr/bin/whoami)" != "root" ]; then
    echo "[ERROR] Must be run as root"
    exit 1
fi

yum update -y
yum upgrade -y

yum provides '*/applydeltarpm'
yum install -y deltarpm

yum install -y wget curl net-tools vim nano firewalld python tzdata ca-certificates nss openssl git rkhunter yum-utils

systemctl start firewalld

firewall-cmd --permanent --add-service=ssh
firewall-cmd --get-services
firewall-cmd --permanent --list-all
firewall-cmd --reload
systemctl enable firewalld

timedatectl set-timezone Europe/Athens
timedatectl

yum install -y ntp

systemctl start ntpd
systemctl enable ntpd

echo -e '[lynis]\nname=CISOfy Software - Lynis package\nbaseurl=https://packages.cisofy.com/community/lynis/rpm/\nenabled=1\ngpgkey=https://packages.cisofy.com/keys/cisofy-software-rpms-public.key\ngpgcheck=1\n' > /etc/yum.repos.d/cisofy-lynis.repo
yum makecache fast
yum update -y  && yum install -y lynis

mkdir -p ./python/pip && cd ./python/pip
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install jinja2 pyyaml setuptools a2x
yum install -y asciidoc rpm-build python2-devel python-setuptools PyYAML python-jinja2 python-paramiko python-six python2-cryptography sshpass

easy_install supervisor
echo_supervisord_conf
echo_supervisord_conf > /etc/supervisord.conf
supervisord -c /etc/supervisord.conf 

yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install -y docker-ce.x86_64

usermod -aG docker $USER
systemctl enable docker
