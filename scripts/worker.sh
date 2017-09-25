#!/usr/bin/env bash

set -eu

# Variables
KUBELET_VERSION=1.7.5-00

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
  --kubeconfig=/etc/kubernetes/kubeconfigs/default-kubeconfig.yaml \
  --require-kubeconfig \
  --authentication-token-webhook \
  --authorization-mode=Webhook \
  --pod-manifest-path=/etc/kubernetes/manifests \
  --container-runtime=docker \
  --allow-privileged=true \
  --anonymous-auth=false \
  --node-labels=role=worker \
  --cluster_dns=10.20.0.10 \
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

# Wait for Flannel to be up
while ! test -f "/run/flannel/subnet.env"; do
 echo "Waiting for flannel subnet.env to be generated"
 sleep 10
done

# Isn't very pretty as this is a very heavy handed way of modifying the iptables rules:
# (https://github.com/coreos/flannel/issues/603)
# Reason being is that pod > pod and host > pod communicated doesn't work as intended,
# due to FORWARD being set to DROP by default with ufw on Ubuntu 16.04.
sudo iptables -P FORWARD ACCEPT

exit 0
