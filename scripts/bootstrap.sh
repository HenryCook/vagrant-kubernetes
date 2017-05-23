#!/bin/bash

set -eu

# Update repo and install dependencies
sudo apt-get update && \
     sudo apt-get upgrade -y && \
     sudo apt-get install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     software-properties-common

# Add source list for Docker
if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo "Docker CE APT list is not present, creating now."
    sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    sudo bash -c "echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /etc/apt/sources.list.d/docker.list"
fi

# Add source list for Kubernetes
if [ ! -f /etc/apt/sources.list.d/kubernetes.list ]; then
    echo "Kubernetes APT list is not present, creating now."
    sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    sudo bash -c "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list"
fi

# # Download flannel binary
# if [ ! -f /usr/local/bin/flanneld ]; then
#     echo "flannel binary is not present, downloading now."
#     sudo curl -O https://storage.googleapis.com/kubernetes-release/flannel/flannel-0.5.5-linux-amd64.tar.gz
#     sudo tar -zxvf flannel-0.5.5-linux-amd64.tar.gz
#     sudo cp flannel-0.5.5/flanneld /usr/local/bin/
#     sudo rm -rf flannel-0.5.5 flannel-0.5.5-linux-amd64.tar.gz
# fi

# # Create Flannel service
# sudo cat >/lib/systemd/system/flannel.service << EOF
# [Unit]
# Description=flannel daemon
#
# Wants=flannel.socket
# After=flannel.socket
#
# [Service]
# ExecStart=/usr/local/bin/flanneld -etcd-endpoints=http://10.0.0.10:4001 -iface=enp0s8
#
# Restart=always
# StartLimitInterval=0
# RestartSec=10
#
# [Install]
# WantedBy=multi-user.target
# EOF

# Docker Daemon file
# mkdir -p /etc/docker
# sudo cat >/etc/docker/daemon.json << EOF
# {
#   "bip": "10.10.0.0/16",
#   "ip-masq": true,
#   "mtu": 1472
# }
# EOF

# Starting flannel service
# sudo systemctl daemon-reload
# sudo service flannel start

exit 0
