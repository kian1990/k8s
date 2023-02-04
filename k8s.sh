#Ubuntu Server 22.04 LTS部署Kubernetes 1.26.0

关闭Swap
swapoff -a
# 取消挂载swap分区，在swap行首添加# 
例如 #/swap.img      none    swap    sw      0       0
vim /etc/fstab

安装Docker
# 更新安装源列表
apt-get update
# 安装前提必须文件
apt-get install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# 添加docker源
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
# 安装dokcer和容器运行时等
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
# 运行docker，并加入开机启动
systemctl enable --now docker

使用阿里镜像源安装Kubeadm
apt-get install -y apt-transport-https

curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.ustc.edu.cn/kubernetes/apt/ kubernetes-xenial main
EOF

apt-get update
apt-get install -y kubelet kubeadm kubectl
systemctl enable --now kubelet

安装Kubernetes
生成并编辑containerd配置文件
containerd config default | tee /etc/containerd/config.toml
# 使用阿里源替换不可访问的国外源
sed -i 's/registry.k8s.io/registry.aliyuncs.com\/google_containers/g' /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
在config.toml的[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]条目下，将SystemdCgroup = false改为SystemdCgroup = true
注意，config.toml有多处SystemdCgroup配置，不要改错了位置

systemctl enable containerd
systemctl restart containerd

使用Kubeadm部署Kubernetes
# 根据环境配置你的--pod-network-cidr和--apiserver-advertise-address的值，不能与已有的网络重复
kubeadm init --apiserver-advertise-address=192.168.2.11 --image-repository registry.aliyuncs.com/google_containers --pod-network-cidr=10.10.0.0/16

复制配置文件到当前用户目录
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

安装Flannel网络插件
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# 编辑kube-flannel.yml，确保cidr配置的值与之前--pod-network-cidr的值相同
kubectl create -f kube-flannel.yml

查看结果
以下命令需要显示所有的pod处于Running状态
watch kubectl get -A pods
kubectl get pods,service --all-namespaces

安装配置Nginx访问Dashboard
apt-get install -y nginx
cat <<"EOF" >/etc/nginx/sites-available/default
server {
    listen       80;
    server_name  localhost;
    location / {
        proxy_pass   http://127.0.0.1:30080;
    }
}
EOF
systemctl enable nginx
systemctl restart nginx

安装Dashboard
#允许安装Dashboard到主节点
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

开始部署Dashboard
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
# 编辑recommended.yaml实现http免密登录，参考https://raw.githubusercontent.com/kian1990/k8s/master/recommended.yaml
kubectl apply -f recommended.yaml

添加管理员权限

kubectl apply -f admin-user.yaml

官方文档
https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

查看容器日志
kubectl describe pod dashboard-metrics-scraper-7bc864c59-9kqwp -n kubernetes-dashboard
