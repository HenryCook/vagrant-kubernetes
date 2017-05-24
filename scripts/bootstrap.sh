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

exit 0
