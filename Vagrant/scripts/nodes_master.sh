#! /bin/bash

#Setup variables to config kubeadm correctly
MASTER_IP="192.168.56.10"
NODENAME=$(hostname -s)
POD_CIDR="192.168.56.0/21"

# Cache images
sudo kubeadm config images pull

# Init kubeadm with the set variables above
sudo kubeadm init --apiserver-advertise-address=$MASTER_IP  --apiserver-cert-extra-sans=$MASTER_IP --pod-network-cidr=$POD_CIDR --node-name $NODENAME --ignore-preflight-errors Swap

# Setup admin.conf
mkdir -p $HOME/.kube; sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Make sure that directory is clear and exists on vagrant shared folder
dirconfig="/vagrant/configs"
rm -fR $dirconfig/*
[[ ! -d "$dirconfig" ]] && mkdir -p $dirconfig

# Copy files to shared vagrant folder to be consumed to worker nodes
cp -i /etc/kubernetes/admin.conf /vagrant/configs/config
touch /vagrant/configs/join.sh
chmod +x /vagrant/configs/join.sh       

kubeadm token create --print-join-command > /vagrant/configs/join.sh

# Install Calico Network Plugin
# curl https://docs.projectcalico.org/manifests/calico.yaml -O
# kubectl apply -f calico.yaml

# Install Weave Network Plugin
sudo modprobe br_netfilter ip_vs_rr ip_vs_wrr ip_vs_sh nf_conntrack_ipv4 ip_vs
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# Install Metrics Server
kubectl apply -f https://raw.githubusercontent.com/scriptcamp/kubeadm-scripts/main/manifests/metrics-server.yaml

# Install Kubernetes Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml

# Create Dashboard User
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Save conf to join nodes in vagrant shared folder
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}" >> /vagrant/configs/token

# Setup non-root enviroment
sudo -i -u vagrant bash << EOF
mkdir -p /home/vagrant/.kube
sudo cp -ap /vagrant/configs/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF




