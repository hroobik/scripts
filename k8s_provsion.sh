#!/bin/bash

# Create the directory for apt keyrings if it doesn't exist
mkdir -p /etc/apt/keyrings/

# Install necessary packages for HTTPS transport, CA certificates, and curl
apt-get install -y apt-transport-https ca-certificates curl

# Download the GPG key for Kubernetes packages and add it to the keyring
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the Kubernetes apt repository to the system sources list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update the apt package index to include the new Kubernetes repository
apt update

# Install kubeadm, which is used to initialize and manage Kubernetes clusters
apt install kubeadm -y

# Load the bridge and br_netfilter modules for networking
modprobe bridge
modprobe br_netfilter

# Ensure the bridge and br_netfilter modules are loaded on boot
echo "bridge" >> /etc/modules
echo "br_netfilter" >> /etc/modules

# Enable IP forwarding and ensure traffic passes through iptables chains properly - required for Kubernetes networking
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# Apply the system control configurations immediately
sysctl -p /etc/sysctl.conf

# Update the package index again (Note: This might be redundant and could be removed to optimize the script)
apt-get update

# Install containerd, which is a container runtime used by Kubernetes
apt-get install -y containerd

# Create the containerd configuration directory if it doesn't exist
mkdir -p /etc/containerd

# Generate the default containerd configuration and write it to the config.toml file
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Modify the containerd configuration to use systemd for cgroup management, which is recommended for Kubernetes
sudo sed -i '/SystemdCgroup = false/c\SystemdCgroup = true' /etc/containerd/config.toml

# Restart containerd to apply the configuration changes
systemctl restart containerd

# Enable containerd to start on boot
systemctl enable containerd
