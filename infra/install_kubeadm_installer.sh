#!/bin/sh

set -x

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

apt update
apt install -y docker.io
systemctl enable docker.service

sudo sysctl --system

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
kubeadm init

echo "Wait a bit"
sleep 10

mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config

echo "Deploy CNI"
kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

echo "Enable scheduling to master"
kubectl --kubeconfig /etc/kubernetes/admin.conf taint node `hostname` node-role.kubernetes.io/master:NoSchedule-

kubectl --kubeconfig /etc/kubernetes/admin.conf taint node `hostname` node.kubernetes.io/not-ready:NoSchedule-

wall "Bootstrap ready"

echo "Install helm"
snap install helm --classic

echo "Install efk stack"
cd /root
git clone https://github.com/sztanyoo/efk-stack-helm.git
kubectl create ns logging
helm install efk --namespace logging ./efk-stack-helm

echo "Deploy metrics server"
cd /root
git clone https://github.com/kodekloudhub/kubernetes-metrics-server
#cd kubernetes-metrics-server
kubectl apply -f kubernetes-metrics-server

cd /root

#helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
#helm repo add stable https://kubernetes-charts.storage.googleapis.com/
#helm repo update
#helm install prometheus --namespace monitoring prometheus-community/kube-prometheus-stack
