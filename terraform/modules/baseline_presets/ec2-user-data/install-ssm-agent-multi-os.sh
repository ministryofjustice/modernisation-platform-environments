#!/bin/bash

# Function to install SSM Agent on RHEL
install_ssm_agent_rhel() {
    # Update the package repository
    if [[ -f /etc/redhat-release && $(grep -o 'release 7' /etc/redhat-release) ]]; then
    # For RHEL 7.x
    sudo yum update -y
    sudo yum install -y python3
    else
    # For other RHEL versions (e.g., RHEL 8.x)
    sudo dnf update -y
    sudo dnf install -y python3
    fi

    # Determine the architecture
    ARCH=$(uname -m)
    OS_VERSION=$(grep -oE '[0-9]+' /etc/redhat-release | head -1)

    echo "System architecture is: $ARCH"
    echo "OS version is: $OS_VERSION"

    # Install SSM Agent based on architecture and OS version
    if [[ "$ARCH" == "aarch64" ]]; then
    # For ARM64 architecture
    echo "Installing ARM64 version of the SSM Agent."
    if [[ "$OS_VERSION" -eq 7 ]]; then
        sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm
    else
        sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm
    fi
    else
    # For AMD64 architecture (including x86_64)
    echo "Installing AMD64 version of the SSM Agent."
    if [[ "$OS_VERSION" -eq 7 ]]; then
        sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    else
        sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    fi
    fi
}

# Function to install SSM Agent on Debian
install_ssm_agent_debian() {
    # Create a temporary directory for SSM installation
    mkdir -p /tmp/ssm
    cd /tmp/ssm

    # Determine the architecture
    ARCH=$(uname -m)

    # Download the appropriate SSM Agent package based on the architecture
    if [[ "$ARCH" == "aarch64" ]]; then
    wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_arm64/amazon-ssm-agent.deb
    else
    wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
    fi

    # Install the SSM Agent package
    sudo dpkg -i amazon-ssm-agent.deb
}

# Main script logic
if [[ -f /etc/redhat-release ]]; then
    install_ssm_agent_rhel
elif [[ -f /etc/debian_version ]]; then
    install_ssm_agent_debian
fi

# Enable and start the SSM Agent service
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Verify that the SSM Agent is running
sudo systemctl status amazon-ssm-agent