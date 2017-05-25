# Show all pods and IP addresses
kubectl get pods -o wide --all-namespaces

# Show all pods in yaml format
kubectl get pods --all-namespaces -o yaml

# Detailed info for all pods
kubectl describe pods --all-namespaces

# Show logs for pod and continously tails them
kubectl logs -f nginx

# Execute comand in pod
kubectl exec nginx

# View cluster info e.g. url for services
kubectl cluster-info

# View logs for pods running in kube-system namespace
kubectl logs etcd-server-master --namespace=kube-system

# Run nginx pod and expose port 80
kubectl run my-nginx --image=nginx --replicas=2 --port=80
kubectl expose deployment my-nginx --port=80
#wget http://<pod-ip>:80
