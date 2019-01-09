sed -f transforms2sed.sed coredns.yaml.base > coredns.yaml
kubectl apply -f coredns.yaml
kubectl get pods -n kube-system -l k8s-app=kube-dns
