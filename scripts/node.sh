#!/bin/bash

set -eu

# Variables
KUBELET_VERSION=1.6.3-00

sudo bash -c "echo '10.0.0.10 master.kubernetes.com' >> /etc/hosts"

# Update repo list and install Docker/Kubelet
sudo apt-get update && \
     sudo apt-get install -y \
     kubelet=$KUBELET_VERSION \
     docker-engine

# Edit kubelet.service with correct flags
sudo cat >/lib/systemd/system/kubelet.service << EOF
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=http://kubernetes.io/docs/

[Service]
ExecStart=/usr/bin/kubelet \
  --kubeconfig=/etc/kubernetes/kubeconfigs/kubelet-kubeconfig.yaml \
  --require-kubeconfig \
  --client-ca-file=/srv/kubernetes/ssl/ca.pem \
  --pod-manifest-path=/etc/kubernetes/manifests \
  --node-labels=dedicated=worker \
  --container-runtime=docker \
  --allow-privileged=true \
  --anonymous-auth=false \
  --network-plugin=kubenet \
  --pod-cidr=10.10.0.0/16

Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Pre download images
docker pull gcr.io/google_containers/hyperkube:v1.6.3

# Reload systemctl daemon after kubelet.service change
sudo systemctl daemon-reload

# Restart kubelet service
sudo service kubelet restart

# Creating flannel network
#echo "Sleeping for 30 seconds while we wait for Kubelet to start"
#sleep 30
#kubectl create -f /etc/kubernetes/components/network/kube-flannel.yaml

exit 0
