#! /bin/bash

# Execute the join command on the work node
/bin/bash /vagrant/configs/join.sh -v

# Setup non-root enviroment
sudo -i -u vagrant bash << EOF
mkdir -p /home/vagrant/.kube
cp -i /vagrant/configs/config /home/vagrant/.kube/
chown 1000:1000 /home/vagrant/.kube/config
NODENAME=$(hostname -s)
kubectl label node $(hostname -s) node-role.kubernetes.io/worker=worker-new
EOF

