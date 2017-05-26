# Show all pods and IP addresses
kubectl get pods -o wide --all-namespaces

# Show all pods in yaml format
kubectl get pods --all-namespaces -o yaml

# Show all pods including IP and node
kubectl get pods --all-namespaces -o yaml

# Detailed info for all pods
kubectl describe pods --all-namespaces

# Detailed info for indivdual pod
kubectl describe pods etcd-server-master --all-namespaces

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
wget http://<pod-ip>:80

# Spin up an interactive pod
kubectl run -i --tty busybox --image=busybox --generator="run-pod/v1"

# Get all resources with different types
kubectl get all --all-namespaces -o wide

# Testing auth
curl -sSk -H "Authorization: Bearer <auth_token>" https://master.kubernetes.com:6443/api/v1
