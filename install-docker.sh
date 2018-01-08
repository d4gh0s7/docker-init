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