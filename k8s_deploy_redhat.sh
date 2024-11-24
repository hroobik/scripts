#!/bin/bash
install_prerequisites() {
    echo "Installing prerequisites..."
    mkdir -p /etc/yum.repos.d/
    dnf install -y dnf-utils ca-certificates curl
}
configure_kubernetes_repo() {
    echo "Configuring Kubernetes repository..."
    cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
}
disable_selinux_firewall() {
    echo "Disabling SELinux and Firewall..."
    setenforce 0
    sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
    systemctl stop firewalld && systemctl disable firewalld
}
install_kubernetes_components() {
    echo "Installing Kubernetes components..."
    yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
    systemctl enable --now kubelet
}
configure_kernel_modules() {
    echo "Configuring kernel modules..."
    modprobe bridge
    modprobe br_netfilter
    echo "bridge" > /etc/modules-load.d/bridge.conf
    echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf
    cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
    cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
    sysctl --system
}
install_containerd() {
    echo "Installing and configuring containerd..."
    dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
    dnf update -y
    dnf install -y containerd
    mkdir -p /etc/containerd
    containerd config default | tee /etc/containerd/config.toml
    sed -i '/SystemdCgroup = false/c\SystemdCgroup = true' /etc/containerd/config.toml
    systemctl restart containerd
    systemctl enable containerd
}
main() {
    install_prerequisites
    configure_kubernetes_repo
    disable_selinux_firewall
    install_kubernetes_components
    configure_kernel_modules
    install_containerd
    echo "Kubernetes setup completed successfully!"
}
# Execute the main function
main

