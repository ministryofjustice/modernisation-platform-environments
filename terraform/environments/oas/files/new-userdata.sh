#!/bin/bash
set -x  # Enable debug mode
exec > >(tee /var/log/userdata.log)
exec 2>&1

# Create marker file to prove userdata started
echo "Userdata started at $(date)" > /tmp/userdata_started

# Set hostname (quick operation)
hostnamectl set-hostname oas

# Update DNS resolv.conf (quick operation)
sed -i '2s/.*/search $${dns_zone_name} eu-west-2.compute.internal/' /etc/resolv.conf

# Function to wait for EBS volumes to be attached
wait_for_volumes() {
    echo "Waiting for EBS volumes to be attached..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        # Check if we have at least 3 NVMe devices (root + 2 EBS volumes)
        local nvme_count=$(ls /dev/nvme*n1 2>/dev/null | wc -l)
        echo "Attempt $attempt: Found $nvme_count NVMe devices"
        
        if [ $nvme_count -ge 3 ]; then
            echo "All volumes detected!"
            ls -la /dev/nvme*n1
            return 0
        fi
        
        sleep 5
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: Timeout waiting for EBS volumes"
    ls -la /dev/nvme* 2>/dev/null || echo "No NVMe devices found"
    return 1
}

# Wait for volumes to be attached
wait_for_volumes

# Create mount points
mkdir -p /oracle/software
mkdir -p /stage

# Mount EBS volumes
# nvme0n1 is the root volume
# nvme1n1 should be the first attached EBS volume (oracle software)
# nvme2n1 should be the second attached EBS volume (stage)

echo "Attempting to mount /dev/nvme1n1 to /oracle/software"
if [ -b /dev/nvme1n1 ]; then
    if ! grep -q "/oracle/software" /etc/fstab; then
        echo "/dev/nvme1n1 /oracle/software ext4 defaults,nofail 0 2" >> /etc/fstab
    fi
    mount /dev/nvme1n1 /oracle/software && echo "Successfully mounted /oracle/software" || echo "Failed to mount /oracle/software"
else
    echo "ERROR: /dev/nvme1n1 not found"
fi

echo "Attempting to mount /dev/nvme2n1 to /stage"
if [ -b /dev/nvme2n1 ]; then
    if ! grep -q "/stage" /etc/fstab; then
        echo "/dev/nvme2n1 /stage ext4 defaults,nofail 0 2" >> /etc/fstab
    fi
    mount /dev/nvme2n1 /stage && echo "Successfully mounted /stage" || echo "Failed to mount /stage"
else
    echo "ERROR: /dev/nvme2n1 not found"
fi

# Verify mounts
echo "Current mounts:"
df -h

# Set ownership and permissions if volumes are mounted
if mountpoint -q /oracle/software; then
    echo "Setting permissions on /oracle/software"
    chown oracle:dba /oracle/software 2>/dev/null || echo "oracle user not found, skipping chown"
    chmod 777 /oracle/software
fi

if mountpoint -q /stage; then
    echo "Setting permissions on /stage"
    chown oracle:dba /stage 2>/dev/null || echo "oracle user not found, skipping chown"
    chmod 777 /stage
fi

# Configure swap file
dd if=/dev/zero of=/root/myswapfile bs=1M count=1024
chmod 600 /root/myswapfile
mkswap /root/myswapfile
swapon /root/myswapfile
echo "/root/myswapfile swap swap defaults 0 0" >> /etc/fstab

# Function to configure NTP based on RHEL version
ntp_config(){
    local RHEL=$(cat /etc/redhat-release | cut -d. -f1 | awk '{print $NF}')
    local SOURCE=169.254.169.123

    NtpD(){
        local CONF=/etc/ntp.conf
        sed -i 's/server \S/#server \S/g' ${CONF} && \
        sed -i "20i\server ${SOURCE} prefer iburst" ${CONF}
        /etc/init.d/ntpd status >/dev/null 2>&1 \
            && /etc/init.d/ntpd restart || /etc/init.d/ntpd start
        ntpq -p
    }
    ChronyD(){
        local CONF=/etc/chrony.conf
        sed -i 's/server \S/#server \S/g' ${CONF} && \
        sed -i "7i\server ${SOURCE} prefer iburst" ${CONF}
        systemctl status chronyd >/dev/null 2>&1 \
            && systemctl restart chronyd || systemctl start chronyd
        chronyc sources
    }
    case ${RHEL} in
        5)
            NtpD
            ;;
        7)
            ChronyD
            ;;
    esac
}

# Configure NTP
ntp_config

# Install required packages (moved to end to not block critical mount operations)
echo "Installing required packages..."
cd /tmp
yum -y install sshpass
yum -y install jq
yum -y install xorg-x11-xauth
yum -y install xclock xterm
yum -y install nvme-cli

# Install and configure SSM agent and firewall
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl stop firewalld
systemctl disable firewalld

echo "Userdata script completed at $(date)"