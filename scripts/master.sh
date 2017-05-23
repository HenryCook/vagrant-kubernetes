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

# Pre download images
docker pull gcr.io/google_containers/hyperkube:v1.6.3
docker pull quay.io/coreos/etcd:v3.1.7

# Reload systemctl daemon after kubelet.service change
sudo systemctl daemon-reload

# Restart kubelet service
sudo service kubelet restart

# Creating flannel network
echo "Sleeping for 60 seconds while we wait for Kubelet to start to then create kube-flannel deployment"
sleep 60
kubectl exec etcd-server-master --namespace=kube-system -- etcdctl set /coreos.com/network/config '{ "Network": "10.10.0.0/16" }'
kubectl create -f /etc/kubernetes/components/network/kube-flannel.yaml

exit 0
