#!/bin/bash
echo "Update SO..."
sudo su
sudo swapoff -a
sudo apt-get update 
sudo apt-get upgrade -y

echo "Install net-tools..."
sudo apt-get install net-tools -y

echo "Install Docker..."
sudo curl https://releases.rancher.com/install-docker/20.10.sh | sh

echo "Allow modprobes"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe -a br_netfilter
sudo modprobe overlay
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

echo "Change cgroup driver..."
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
sudo systemctl restart docker

echo "Remove containerd config..."
sudo rm -rf /etc/containerd/config.toml
sudo systemctl restart containerd

echo "Install kubectl..."
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl