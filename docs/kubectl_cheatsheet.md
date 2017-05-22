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
