#! /bin/bash

# disable swap for k8s
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# add kubernetes pkgs
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# update and install 
sudo apt-get update -y
sudo apt-get install -y \
  curl \
  lsb-release

#Install docker
curl -fsSL https://get.docker.com | bash

sudo echo '{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}' > /etc/docker/daemon.json

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

#Install kubelet kubectl kubeadm and make sure that is in place
sudo apt-get install -y kubelet kubectl kubeadm
sudo apt-mark hold kubelet kubeadm kubectl

# Fix network error. refer: https://stackoverflow.com/questions/42338519/can-not-access-cluster-ip-with-same-node
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1

