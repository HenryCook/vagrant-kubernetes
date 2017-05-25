# vagrant-kubernetes

Kubernetes Cluster from scratch in Vagrant


## Overview

The reason behind this was to gain a greater understanding of how Kubernetes fits together to then figure out a deployment strategy via the usual methods e.g. Salt, Userdata. As it stands it's super basic and was purely for learning so it doesn't do much past bootstrapping at the moment.

Using the docs on [kubernetes.io](kubernetes.io) I was able to piece this cluster together.

As per Kubernetes' instructions I have installed the `kubelet` and docker binaries, and then configured all the other components via static pod manifests (see the `files/manifests` directory). This allows for a very clean and repeatable bootstrap experience. I have used the `hyperkube` Docker image that contains the `hyperkube` all-in-one binary, which means you can run all your components with just the one binary e.g. `kube-proxy`, `kube-apiserver`, `kube-controller-manager` and `kube-scheduler`.

### SSL

With thanks to [kelseyhightower](https://github.com/kelseyhightower) I was able to create valid self signed certs via his repo [docker-kubernetes-tls-guide](https://github.com/kelseyhightower/docker-kubernetes-tls-guide).

You just need to clone the repo, install the [CFSSL](https://github.com/cloudflare/cfssl) tool, edit the relevant json files and create your SSL certs.


### Reading

See below for some links I used to help build this:

- [Creating a Custom Cluster from Scratch](https://kubernetes.io/docs/getting-started-guides/scratch/)
- [Building High-Availability Clusters](https://kubernetes.io/docs/admin/high-availability/)
- [etcd Cluster Guide](https://github.com/coreos/etcd/blob/master/Documentation/op-guide/clustering.md)
- [Kubernetes The Hard Way ](https://github.com/kelseyhightower/kubernetes-the-hard-way)


## Usage

Using Vagrant I spin up 2 nodes, one master (`master.kubernetes.com`) and one worker (`node.kubernetes.com`).

To start the cluster, you just need run vagrant.

```
vagrant up
```

If you just want to bring up a single node e.g. master, you can specify the individual node `vagrant up master`.

Once provisioned you can log into each box and play around with the functionality of Kubernetes.

```
vagrant ssh master
vagrant ssh node
```

If everything has successfully provisioned (which should look like this).

```
May 19 14:57:39 master kubelet[9406]: I0519 14:57:39.831847    9406 kubelet_node_status.go:77] Attempting to register node master
May 19 14:57:39 master kubelet[9406]: I0519 14:57:39.845771    9406 kubelet_node_status.go:80] Successfully registered node master
May 19 14:57:49 master kubelet[9406]: I0519 14:57:49.868895    9406 kuberuntime_manager.go:902] updating runtime config through cri with podcidr 10.10.0.0/24
May 19 14:57:49 master kubelet[9406]: I0519 14:57:49.869405    9406 docker_service.go:277] docker cri received runtime config &RuntimeConfig{NetworkConfig:&NetworkConfig{PodCidr:10.10.0.0/24,},}
May 19 14:57:49 master kubelet[9406]: I0519 14:57:49.869757    9406 kubelet_network.go:326] Setting Pod CIDR:  -> 10.10.0.0/24
```

You can then use `kubectl` to have a play with the `kube-apiserver`.

```
kubectl get pods --all-namespaces
```

When finished you can destroy the cluster.

```
vagrant destroy -f
```


## To Do

- Secure communication between `kube-apiserver` > `etcd`
- Access webpages e.g. `Kubernetes-dashboard` from guest on the host
- Configure the DNS add-on
- ~~Overlay network with flannel using CNI plugin~~ - **DONE**
- ~~Fix TLS/certificate issues with `kube-apiserver` (currently using http)~~ - **DONE**
- ~~Use `--kubeconfig` instead of `--api-servers` for the `kubelet` config~~ - **DONE**
- ~~Upgrade etcd from 2 > 3~~ - **DONE**
- ~~Pods to only run on nodes, and not on the master, via the use of labels~~ - **DONE**
