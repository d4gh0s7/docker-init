#!/bin/bash

set -o pipefail
set -o errtrace
set -o nounset
set -o errexit

if [ "$(/usr/bin/whoami)" != "root" ]; then
    echo "[ERROR] Must be run as root"
    exit 1
fi

yum update -y && yum upgrade -y && yum install -y epel-release
yum update -y && yum upgrade -y

yum provides '*/applydeltarpm'
yum install -y deltarpm

# base layout

yum install -y \
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
        rkhunter


# firewalld
systemctl start firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-port=11260/tcp
firewall-cmd --permanent --add-port=11269/tcp
firewall-cmd --get-services
firewall-cmd --permanent --list-all
firewall-cmd --reload
systemctl enable firewalld

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

cd /opt
# python pip
mkdir -p ./python/pip && cd ./python/pip
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install jinja2 pyyaml setuptools a2x
yum install -y asciidoc rpm-build python2-devel python-setuptools PyYAML python-jinja2 python-paramiko python-six python2-cryptography sshpass

pip install -y --upgrade pip
hash -r

# supervisor
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

mkdir -p /opt/toolbox && cd /opt/toolbox

# go-lang
mkdir go-lang && cd go-lang

wget -O "go.tar.gz" https://storage.googleapis.com/golang/go1.9.2.linux-amd64.tar.gz

tar --no-same-permissions -xf go.tar.gz

cp -r go /usr/local

export PATH=$PATH:/usr/local/go/bin

# goofys
cd .. && mkdir goofys && cd goofys

wget https://github.com/kahing/goofys/releases/download/v0.0.18/goofys

chmod +x ./goofys

cp goofys /usr/bin

echo 'goofys#web-stack.ime.ninja    /s3-storage     fuse    _netdev,allow_other,--file-mode=0777    0 0' >> /etc/fstab

mount -a

# gosu
cd .. && mkdir gosu && cd gosu

wget -O "gosu" "https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64"

chmod +x ./gosu

cp gosu /usr/bin



