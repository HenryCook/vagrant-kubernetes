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

# Pre download image to speed up Kubernetes convergence
docker pull gcr.io/google_containers/hyperkube:v1.6.3

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
Environment="FLANNEL_SUBNET=172.17.0.1/16"
Environment="FLANNEL_MTU=1450"
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

# Reload systemctl daemon after kubelet.service change and restart
sudo systemctl daemon-reload
sudo service kubelet restart

# Wait for /run/flannel/subnet.env to be created
while ! test -f "/run/flannel/subnet.env"; do
  echo "Waiting for flannel subnet.env to be generated"
  sleep 10
done

echo "'/run/flannel/subnet.env' is now present, restarting Docker"

sudo service docker restart

exit 0
