#!/bin/bash

set -eu

# Variables
KUBELET_VERSION=1.6.3-00
KUBECTL_VERSION=1.6.3-00

# Edit /etc/hosts file
sudo bash -c "echo '10.0.0.11 node.kubernetes.com' >> /etc/hosts"
sudo bash -c "echo '10.0.0.11 node' >> /etc/hosts"

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
  --kubeconfig=/etc/kubernetes/kubeconfigs/kubelet-kubeconfig.yaml \
  --require-kubeconfig \
  --client-ca-file=/srv/kubernetes/ssl/ca.pem \
  --pod-manifest-path=/etc/kubernetes/manifests \
  --container-runtime=docker \
  --allow-privileged=true \
  --register-with-taints=role=master:NoSchedule \
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

# Checking to see if etcd endpoint is up
until curl --output /dev/null --silent --fail "http://10.0.0.10:4001/version"; do
    echo "Waiting for etcd endpoint to become available"
    sleep 10
done

# Creating flannel network
echo "Attempting to create Flannel network"
until kubectl exec etcd-server-master --namespace=kube-system -- etcdctl set /coreos.com/network/config '{ "Network": "10.10.0.0/16" }'; do
  echo "The kube-apiserver is currently unavailable, trying again in 10 seconds"
  sleep 10
done

# Applying kube-flannel daemon set
kubectl create -f /etc/kubernetes/components/network/kube-flannel.yaml

# Spinning up busybox node
kubectl create -f /etc/kubernetes/components/examples/busybox.yaml

exit 0
