# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 1.9.3"

MASTER_IP="10.0.0.10"
WORKER_IP="10.0.0.11"

MASTER_HOSTNAME="master.kubernetes.com"
WORKER_HOSTNAME="worker.kubernetes.com"

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.provision :shell, path: "scripts/bootstrap.sh"
  config.vm.synced_folder "files/certs", "/etc/kubernetes/ssl"
  config.vm.synced_folder "files/kubeconfigs", "/etc/kubernetes/kubeconfigs"
  config.vm.synced_folder "files/addons", "/etc/kubernetes/addons"
  config.vm.synced_folder "files/deployments", "/etc/kubernetes/deployments"
  config.vm.synced_folder "files/cni", "/etc/cni/net.d"

  config.vm.define "master" do |master|
    master.vm.host_name = MASTER_HOSTNAME
    master.vm.synced_folder "files/manifests/master", "/etc/kubernetes/manifests"
    master.vm.network :private_network, ip: MASTER_IP
    master.vm.network "forwarded_port", guest: 6443, host: 6443
    master.vm.provision :shell, path: "scripts/master.sh"
  end

  config.vm.define "worker" do |worker|
   worker.vm.host_name = WORKER_HOSTNAME
   worker.vm.synced_folder "files/manifests/worker", "/etc/kubernetes/manifests"
   worker.vm.network :private_network, ip: WORKER_IP
   worker.vm.provision :shell, path: "scripts/worker.sh"
  end

end
