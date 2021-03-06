#!/usr/bin/env bash

set -eu

# Variables
KUBELET_VERSION=1.7.5-00
KUBECTL_VERSION=1.7.5-00

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
  --kubeconfig=/etc/kubernetes/kubeconfigs/default-kubeconfig.yaml \
  --require-kubeconfig \
  --authentication-token-webhook \
  --authorization-mode=Webhook \
  --client-ca-file=/etc/kubernetes/ssl/ca.pem \
  --pod-manifest-path=/etc/kubernetes/manifests \
  --container-runtime=docker \
  --allow-privileged=true \
  --register-with-taints=role=master:NoSchedule \
  --anonymous-auth=false \
  --cluster_dns=10.20.0.10 \
  --node-labels=role=master \
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
until curl --output /dev/null --silent --fail "http://127.0.0.1:4001/version"; do
    echo "Waiting for etcd endpoint to become available"
    sleep 10
done

# Creating flannel network
echo "Attempting to create Flannel network"
until kubectl exec $(kubectl get pods --all-namespaces | awk '/etcd-server/ {print $2;exit;}') --namespace=kube-system -- etcdctl set /coreos.com/network/config '{ "Network": "10.10.0.0/16" }'; do
  echo "The kube-apiserver is currently unavailable"
  sleep 10
done

# Applying kube-flannel daemon set
kubectl create -f /etc/kubernetes/addons/kube-flannel.yaml

# Applying kube-dns service
kubectl create -f /etc/kubernetes/addons/kube-dns.yaml

# Applying kube-dashboard service
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

# Applying node-exporter daemon set
kubectl create -f /etc/kubernetes/addons/node_exporter.yaml

# Applying kube-state-metrics daemon set
kubectl create -f /etc/kubernetes/addons/kube-state-metrics.yaml

# Creating flannel network
until kubectl get serviceaccounts default; do
  echo "Waiting for the 'default' service account to be created"
  sleep 10
done

# Spinning up busybox node
kubectl create -f /etc/kubernetes/deployments/examples/busybox.yaml

# Spinning up nginx node
kubectl create -f /etc/kubernetes/deployments/examples/nginx.yaml

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
