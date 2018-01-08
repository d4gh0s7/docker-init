#!/bin/bash

set -o pipefail
set -o errtrace
set -o nounset
set -o errexit

# if [ "$(/usr/bin/whoami)" != "root" ]; then
#     echo "[ERROR] Must be run as root"
#     exit 1
# fi

# base layout

yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install -y docker-ce.x86_64

systemctl enable docker
systemctl start docker