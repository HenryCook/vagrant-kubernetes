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

# Wait for Flannel to be up
while ! test -f "/run/flannel/subnet.env"; do
 echo "Waiting for flannel subnet.env to be generated"
 sleep 10
done

# Isn't very pretty but it clears all iptable rules (https://github.com/kubernetes/kubernetes/issues/20391)
# Reason being is that pod > pod and host > pod communicated doesn't work due to flannel --ip-masq not working as intended
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -F
sudo iptables -X

# Restart docker to then allow communcation between hosts and pods
sudo service docker restart

exit 0
