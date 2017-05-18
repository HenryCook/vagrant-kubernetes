#!/bin/bash

set -eu

# Variables
KUBELET_VERSION=1.6.3-00
KUBECTL_VERSION=1.6.3-00

# Update repo list and install Docker/Kubelet
sudo apt-get update && \
     sudo apt-get install -y \
     kubelet=$KUBELET_VERSION \
     kubectl=$KUBECTL_VERSION \
     docker-engine

# Edit kubelet.service with correct flags
sudo cat >/lib/systemd/system/kubelet.service << EOF
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=http://kubernetes.io/docs/

[Service]
ExecStart=/usr/bin/kubelet \
  --api-servers=http://127.0.0.1:8080 \
  --pod-manifest-path=/etc/kubernetes/manifests \
  --client-ca-file=/srv/kubernetes/ca.crt \
  --tls-cert-file=/srv/kubernetes/server.cert \
  --tls-private-key-file=/srv/kubernetes/server.key \
  --container-runtime=docker \
  --allow-privileged=true \
  --anonymous-auth=false
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemctl daemon after kubelet.service change
sudo systemctl daemon-reload

# Restart kubelet service
sudo service kubelet restart

exit 0
