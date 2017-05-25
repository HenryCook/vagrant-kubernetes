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

# Wait for /run/flannel/subnet.env to be created
while ! test -f "/run/flannel/subnet.env"; do
  echo "Waiting for flannel subnet.env to be generated"
  sleep 10
done

# Docker to use Flannel as bridge
sudo cat >/lib/systemd/system/docker.service <<'EOF'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target docker.socket firewalld.service
Wants=network-online.target
Requires=docker.socket

[Service]
EnvironmentFile=/run/flannel/subnet.env
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd --bip=${FLANNEL_SUBNET} --mtu=${FLANNEL_MTU} -H fd://
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=1048576
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
# restart the docker process if it exits prematurely
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF

# Restarting Docker to use Flannel bridge
echo "'/run/flannel/subnet.env' is now present, restarting Docker"

sudo systemctl daemon-reload
sudo service docker restart

exit 0
