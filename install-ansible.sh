#!/bin/bash
# Universal Ansible Installation Script
# Auto-detects Linux distro and installs Ansible via native package manager.
# Supported: Ubuntu, Debian, Fedora, CentOS/RHEL/Rocky/AlmaLinux/Oracle Linux, Arch, openSUSE, Amazon Linux.
# Author: Inspired by Ansible docs and community scripts (2025 update).
# Usage: ./install-ansible.sh

set -e  # Exit on error

error_exit() {
    echo "Error: $1"
    exit 1
}

# Check if Ansible is already installed
if command -v ansible >/dev/null 2>&1; then
    echo "Ansible is already installed."
    ansible --version
    exit 0
fi

# Source OS info
if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    error_exit "Cannot detect OS (missing /etc/os-release)."
fi

echo "Detected OS: $ID $VERSION_ID ($PRETTY_NAME)"

# Installation logic based on distro
case "$ID" in
    ubuntu|debian)
        # For Debian, map to compatible Ubuntu codename for PPA
        if [ "$ID" = "debian" ]; then
            case "$VERSION_ID" in
                10) UBUNTU_CODENAME="bionic" ;;
                11) UBUNTU_CODENAME="focal" ;;
                12) UBUNTU_CODENAME="jammy" ;;
                *) UBUNTU_CODENAME="bookworm" ;;  # Adjust for newer if needed
            esac
        else
            UBUNTU_CODENAME="${VERSION_CODENAME:-$VERSION_ID}"
        fi
        echo "Using Ubuntu codename: $UBUNTU_CODENAME for PPA."
        sudo apt update
        sudo apt install -y software-properties-common ca-certificates gnupg wget
        # Add Ansible PPA key (modern method, avoids deprecated apt-key)
        wget -qO- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list > /dev/null
        sudo apt update
        sudo apt install -y ansible
        ;;
    fedora)
        sudo dnf install -y dnf-plugins-core  # Ensure plugins if needed
        sudo dnf install -y ansible
        ;;
    centos|rhel|rocky|almalinux|ol)  # RHEL, Rocky, Alma, Oracle Linux
        # Enable EPEL for Ansible
        if command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %dist | cut -d. -f1).noarch.rpm
            sudo dnf install -y ansible
        else
            sudo yum install -y epel-release
            sudo yum install -y ansible
        fi
        ;;
    arch)
        sudo pacman -Sy --noconfirm ansible
        ;;
    opensuse*|suse)
        sudo zypper refresh
        sudo zypper install -y ansible
        ;;
    amazon)
        # Amazon Linux 2/2023
        if command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y epel-release
            sudo dnf install -y ansible
        else
            sudo yum install -y epel-release
            sudo yum install -y ansible
        fi
        ;;
    *)
        error_exit "Unsupported OS: $ID. Consider manual installation via pip: python3 -m pip install --user ansible"
        ;;
esac

echo "Ansible installed successfully!"
ansible --version
