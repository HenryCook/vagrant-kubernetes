# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.provision :shell, path: "scripts/bootstrap.sh"
  config.vm.synced_folder "files/certs", "/srv/kubernetes"

  config.vm.define "master" do |master|
    master.vm.host_name = "master.kubernetes.com"
    master.vm.synced_folder "files/manifests/master", "/etc/kubernetes/manifests"
    master.vm.network :private_network, ip: "10.1.1.10"
    master.vm.provision :shell, path: "scripts/master.sh"
  end

  config.vm.define "node" do |node|
   node.vm.host_name = "node.kubernetes.com"
   node.vm.synced_folder "files/manifests/node", "/etc/kubernetes/manifests"
   node.vm.network :private_network, ip: "10.1.1.11"
   node.vm.provision :shell, path: "scripts/node.sh"
  end

end
