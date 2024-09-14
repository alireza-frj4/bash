#!/bin/bash

# Update the system
sudo dnf update -y

# Install necessary packages
sudo dnf install -y container-selinux selinux-policy-base
sudo dnf install -y https://rpm.rancher.io/rke2/latest/common/rke2-common-1.el8.noarch.rpm

# Configure firewall (if enabled)
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=9345/tcp
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --reload

# Disable swap (recommended for Kubernetes)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Create RKE2 config file
sudo mkdir -p /etc/rancher/rke2/
cat <<EOF | sudo tee /etc/rancher/rke2/config.yaml
write-kubeconfig-mode: "0644"
EOF

# Install specific version of RKE2 server
curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=v1.28.10+rke2r1 INSTALL_RKE2_TYPE=server sh -

# Enable and start RKE2 service
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service

# Set up environment variables
echo 'export PATH=$PATH:/var/lib/rancher/rke2/bin' | sudo tee -a /etc/profile.d/rke2.sh
echo 'export KUBECONFIG=/etc/rancher/rke2/rke2.yaml' | sudo tee -a /etc/profile.d/rke2.sh
source /etc/profile.d/rke2.sh

# Wait for the node to become ready
until kubectl get nodes | grep -q " Ready"; do
  echo "Waiting for node to be ready..."
  sleep 5
done

echo "RKE2 v1.28.10 installation complete on Rocky Linux 8.5. Node is ready."
