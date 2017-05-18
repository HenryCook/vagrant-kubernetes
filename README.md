# vagrant-kubernetes

Kubernetes Cluster from scratch in Vagrant


## Overview

The reason behind this was to gain a greater understanding of how Kubernetes fits together to then figure out a deployment strategy via the usual methods e.g. Salt, Userdata. As it stands it's super basic and was purely for learning so it doesn't do much past bootstrapping at the moment.

Using the docs on [kubernetes.io](kubernetes.io) I was able to piece this mishapen cluster together.

As per Kubernetes' instructions I have installed the `kubelet` and docker binaries, and then configured all the other components via static pod manifests (see the `files/manifests` directory). This allows for a very clean and repeatable bootstrap experience. I have used the `hyperkube` Docker image that contains the `hyperkube` all-in-one binary, which means you can run all your components with just the one binary e.g. `kube-proxy`, `kube-apiserver`, `kube-controller-manager` and `kube-scheduler`.


## Usage

To start the cluster, you just need run vagrant.

```
vagrant up
```

Once provisioned you can log into each box and play around with the functionality of Kubernetes.

```
vagrant ssh master
vagrant ssh node
```

If everything has successfully provisioned (which should look like this).

```
May 18 16:26:26 master kubelet[10806]: I0518 16:26:26.939296   10806 kuberuntime_manager.go:902] updating runtime config through cri with podcidr 10.100.0.0/24
May 18 16:26:26 master kubelet[10806]: I0518 16:26:26.940009   10806 docker_service.go:277] docker cri received runtime config &RuntimeConfig{NetworkConfig:&NetworkConfig{PodCidr:10.100.0.0/24,},}
May 18 16:26:26 master kubelet[10806]: I0518 16:26:26.940550   10806 kubelet_network.go:326] Setting Pod CIDR:  -> 10.100.0.0/24
```

You can then use `kubectl` to have a play with the `kube-apiserver`

```
kubectl get pods --all-namespaces
```

When finished you can destroy the cluster.

```
vagrant destroy -f
```


## To Do

- Fix TLS/certificate issues (currently using http)
- Look to use API tokens for `kubelet` > `kube-apiserver` communication
- Secure communication between `kube-apiserver` > `etcd`
- Pods to only run nodes, and not the master
- Access webpages e.g. `Kubernetes-dashboard` from guest on the host
