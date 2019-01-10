#!/bin/bash

#安装docker
apt-get update && apt-get install -y apt-transport-https curl wget
wget -qO- https://get.docker.com/ | sh
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

#安装k8s组件
apt-get update && apt-get install -y kubelet kubeadm kubectl

cat <<EOF >/etc/default/kubelet
KUBELET_EXTRA_ARGS="--pod-infra-container-image=k8s.gcr.io/pause:3.1 --fail-swap-on=false"
EOF

#安装nginx
apt-get update && apt-get install -y nginx

cat <<EOF >/etc/nginx/sites-available/default
server {
    listen       80;
    server_name  localhost;
    location / {
        proxy_pass   http://127.0.0.1:30000;
    }
}
EOF

#启动服务
systemctl restart docker
systemctl restart kubelet
systemctl restart nginx
systemctl enable docker
systemctl enable kubelet
systemctl enable nginx

# docker pull k8s.gcr.io/kube-apiserver:v1.13.1
# docker pull k8s.gcr.io/kube-controller-manager:v1.13.1
# docker pull k8s.gcr.io/kube-scheduler:v1.13.1
# docker pull k8s.gcr.io/kube-proxy:v1.13.1
# docker pull k8s.gcr.io/pause:3.1
# docker pull k8s.gcr.io/etcd:3.2.24
# docker pull k8s.gcr.io/coredns:1.2.6
# docker pull gcr.io/google-containers/kubernetes-dashboard-amd64:v1.10.1
# docker pull gcr.io/google-containers/heapster-amd64:v1.5.4
# docker pull gcr.io/google-containers/heapster-influxdb-amd64:v1.5.2
# docker pull gcr.io/google-containers/heapster-grafana-amd64:v5.0.4
# docker pull quay.io/coreos/flannel:v0.10.0-amd64

# docker save k8s.gcr.io/kube-apiserver:v1.13.1 > kube-apiserver-v1.13.1.tar
# docker save k8s.gcr.io/kube-controller-manager:v1.13.1 > kube-controller-manager-v1.13.1.tar
# docker save k8s.gcr.io/kube-scheduler:v1.13.1 > kube-scheduler-v1.13.1.tar
# docker save k8s.gcr.io/kube-proxy:v1.13.1 > kube-proxy-v1.13.1.tar
# docker save k8s.gcr.io/pause:3.1 > pause-3.1.tar
# docker save k8s.gcr.io/etcd:3.2.24 > etcd-3.2.24.tar
# docker save k8s.gcr.io/coredns:1.2.6 > coredns-1.2.6.tar
# docker save gcr.io/google-containers/kubernetes-dashboard-amd64:v1.10.1 > kubernetes-dashboard-amd64-v1.10.1.tar
# docker save gcr.io/google-containers/heapster-amd64:v1.5.4 > heapster-amd64-v1.5.4.tar
# docker save gcr.io/google-containers/heapster-influxdb-amd64:v1.5.2 > heapster-influxdb-amd64-v1.5.2.tar
# docker save gcr.io/google-containers/heapster-grafana-amd64:v5.0.4 > heapster-grafana-amd64-v5.0.4.tar
# docker save quay.io/coreos/flannel:v0.10.0-amd64 > flannel-v0.10.0-amd64.tar

#下载docker镜像
wget http://www.monsterk.cn/file/kube-apiserver-v1.13.1.tar
wget http://www.monsterk.cn/file/kube-controller-manager-v1.13.1.tar
wget http://www.monsterk.cn/file/kube-scheduler-v1.13.1.tar
wget http://www.monsterk.cn/file/kube-proxy-v1.13.1.tar
wget http://www.monsterk.cn/file/pause-3.1.tar
wget http://www.monsterk.cn/file/etcd-3.2.24.tar
wget http://www.monsterk.cn/file/coredns-1.2.6.tar
wget http://www.monsterk.cn/file/kubernetes-dashboard-amd64-v1.10.1.tar
wget http://www.monsterk.cn/file/heapster-amd64-v1.5.4.tar
wget http://www.monsterk.cn/file/heapster-influxdb-amd64-v1.5.2.tar
wget http://www.monsterk.cn/file/heapster-grafana-amd64-v5.0.4.tar
wget http://www.monsterk.cn/file/flannel-v0.10.0-amd64.tar

#导入docker镜像
docker load < kube-apiserver-v1.13.1.tar
docker load < kube-controller-manager-v1.13.1.tar
docker load < kube-scheduler-v1.13.1.tar
docker load < kube-proxy-v1.13.1.tar
docker load < pause-3.1.tar
docker load < etcd-3.2.24.tar
docker load < coredns-1.2.6.tar
docker load < kubernetes-dashboard-amd64-v1.10.1.tar
docker load < heapster-amd64-v1.5.4.tar
docker load < heapster-influxdb-amd64-v1.5.2.tar
docker load < heapster-grafana-amd64-v5.0.4.tar
docker load < flannel-v0.10.0-amd64.tar

#使用kubeadm初始化
#修改apiserver为自己的IP地址
kubeadm init \
   --kubernetes-version=v1.13.1 \
   --pod-network-cidr=10.0.0.0/16 \
   --apiserver-advertise-address=192.168.0.81 \
   --ignore-preflight-errors=Swap

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint nodes ubuntu node-role.kubernetes.io/master-

echo "waiting 60s for start..."
sleep 60

#创建容器
kubectl create -f https://raw.githubusercontent.com/kian1990/k8s/master/dockerfile/kube-flannel.yml
kubectl create -f https://raw.githubusercontent.com/kian1990/k8s/master/dockerfile/kubernetes-dashboard/kubernetes-dashboard.yaml
kubectl create -f https://raw.githubusercontent.com/kian1990/k8s/master/dockerfile/coredns/coredns.yaml
kubectl create -f https://raw.githubusercontent.com/kian1990/k8s/master/dockerfile/heapster/grafana.yaml
kubectl create -f https://raw.githubusercontent.com/kian1990/k8s/master/dockerfile/heapster/heapster-rbac.yaml
kubectl create -f https://raw.githubusercontent.com/kian1990/k8s/master/dockerfile/heapster/heapster.yaml
kubectl create -f https://raw.githubusercontent.com/kian1990/k8s/master/dockerfile/heapster/influxdb.yaml

echo "waiting 30s for start..."
sleep 30

#查看容器运行状态
kubectl get pods,service --all-namespaces
