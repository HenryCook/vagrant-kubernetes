#!/bin/bash

set -eu

# Variables
KUBELET_VERSION=1.6.3-00

# Edit /etc/hosts file
sudo bash -c "echo '10.0.0.10 master.kubernetes.com' >> /etc/hosts"
sudo bash -c "echo '10.0.0.10 master' >> /etc/hosts"

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
  --container-runtime=docker \
  --allow-privileged=true \
  --anonymous-auth=false \
  --cluster_dns=10.10.0.10 \
  --cluster_domain=cluster.local \
  --network-plugin=cni \
  --cni-conf-dir=/etc/cni/net.d \
  --cni-bin-dir=/opt/cni/bin

Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemctl daemon after kubelet.service change and restart
sudo systemctl daemon-reload
sudo service kubelet restart

# Flush iptable and restart docker (https://github.com/coreos/flannel/issues/115)
sudo iptables -t nat -F
sudo ip link del docker0
sudo service docker restart

exit 0
