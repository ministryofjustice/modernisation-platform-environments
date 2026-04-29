#!/bin/bash
set -x
exec > >(tee /var/log/userdata.log)
exec 2>&1

# Create marker file to prove userdata started
echo "Userdata started at $(date)" > /tmp/userdata_started

# Replace SSH keys with new Terraform-generated keys
echo "Replacing SSH keys with new Terraform-generated keys..."

# Fetch the public key from EC2 instance metadata
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
NEW_PUBLIC_KEY=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key 2>/dev/null)

if [ -n "$NEW_PUBLIC_KEY" ]; then
    echo "New public key retrieved from metadata service"
    
    # Update authorized_keys for ec2-user
    if id "ec2-user" &>/dev/null; then
        echo "Updating authorized_keys for ec2-user"
        mkdir -p /home/ec2-user/.ssh
        echo "$NEW_PUBLIC_KEY" > /home/ec2-user/.ssh/authorized_keys
        chmod 700 /home/ec2-user/.ssh
        chmod 600 /home/ec2-user/.ssh/authorized_keys
        chown -R ec2-user:ec2-user /home/ec2-user/.ssh
        echo "ec2-user SSH keys updated successfully"
    fi
    
    # Update authorized_keys for root
    echo "Updating authorized_keys for root"
    mkdir -p /root/.ssh
    echo "$NEW_PUBLIC_KEY" > /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
    echo "root SSH keys updated successfully"
    
    # Update authorized_keys for oracle user if it exists
    if id "oracle" &>/dev/null; then
        echo "Updating authorized_keys for oracle"
        mkdir -p /home/oracle/.ssh
        echo "$NEW_PUBLIC_KEY" > /home/oracle/.ssh/authorized_keys
        chmod 700 /home/oracle/.ssh
        chmod 600 /home/oracle/.ssh/authorized_keys
        chown -R oracle:dba /home/oracle/.ssh
        echo "oracle SSH keys updated successfully"
    fi
else
    echo "WARNING: Could not retrieve public key from metadata service"
fi

# Set hostname
hostnamectl set-hostname oas

# Update DNS resolv.conf
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
# Use lsblk to identify volumes by size
# Larger volume = /oracle/software (oracle home)
# Smaller volume = /stage

echo "Detecting volume sizes..."
lsblk -b -n -o NAME,SIZE,TYPE | grep disk

# Find non-root volumes and assign based on size (larger = oracle, smaller = stage)
ORACLE_SOFTWARE=""
STAGE=""
declare -A volumes

for dev in /dev/nvme*n1; do
    if [ "$dev" == "/dev/nvme0n1" ]; then
        continue
    fi

    size=$(lsblk -b -n -d -o SIZE "$dev")
    echo "Device $dev has size $size bytes"
    volumes["$dev"]=$size
done

# Sort volumes by size and assign (largest = oracle, smallest = stage)
# This works for any volume sizes configured in terraform
for dev in "${!volumes[@]}"; do
    size=${volumes[$dev]}
    
    # Skip volumes smaller than 100GB to avoid conflicts
    if [ "$size" -lt 107374182400 ]; then
        echo "Skipping $dev (size $size) - too small to be oracle/stage volume"
        continue
    fi
    
    # Assign larger volume to ORACLE_SOFTWARE if not set or if this is larger
    if [ -z "$ORACLE_SOFTWARE" ]; then
        ORACLE_SOFTWARE="$dev"
        ORACLE_SIZE=$size
    elif [ "$size" -gt "$ORACLE_SIZE" ]; then
        # This volume is larger, so previous becomes STAGE
        STAGE="$ORACLE_SOFTWARE"
        ORACLE_SOFTWARE="$dev"
        ORACLE_SIZE=$size
    elif [ -z "$STAGE" ]; then
        # This is smaller than ORACLE_SOFTWARE, assign to STAGE
        STAGE="$dev"
    fi
done

echo "Assigned ORACLE_SOFTWARE=$ORACLE_SOFTWARE (size: $ORACLE_SIZE bytes)"
echo "Assigned STAGE=$STAGE"

# Mount oracle software volume (larger volume)
if [ -n "$ORACLE_SOFTWARE" ]; then
    echo "Mounting $ORACLE_SOFTWARE to /oracle/software"
    if ! grep -q "/oracle/software" /etc/fstab; then
        echo "$ORACLE_SOFTWARE /oracle/software ext4 defaults,nofail 0 2" >> /etc/fstab
    fi
    mount "$ORACLE_SOFTWARE" /oracle/software && echo "Successfully mounted /oracle/software" || echo "Failed to mount /oracle/software"
else
    echo "ERROR: Oracle software volume not found"
fi

# Mount stage volume (smaller volume)
if [ -n "$STAGE" ]; then
    echo "Mounting $STAGE to /stage"
    if ! grep -q "/stage" /etc/fstab; then
        echo "$STAGE /stage ext4 defaults,nofail 0 2" >> /etc/fstab
    fi
    mount "$STAGE" /stage && echo "Successfully mounted /stage" || echo "Failed to mount /stage"
else
    echo "ERROR: Stage volume not found"
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

# Function to configure NTP based on RHEL/Oracle Linux major version
ntp_config(){
    local RHEL=$(rpm -E %{rhel} 2>/dev/null || cat /etc/redhat-release | grep -oE '[0-9]+' | head -1)
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
        7|8)
            ChronyD
            ;;
        *)
            echo "Unsupported RHEL/Oracle Linux version: ${RHEL}. Skipping NTP configuration."
            ;;
    esac
}

# Configure NTP
ntp_config

# Install required packages
echo "Installing required packages..."
cd /tmp

# Disable deltarpm and prestodelta to avoid 404 errors and timeouts
# Detect OS version to use correct configuration file
RHEL_VERSION=$(rpm -E %{rhel} 2>/dev/null || cat /etc/redhat-release | grep -oE '[0-9]+' | head -1)

if [ "$RHEL_VERSION" = "8" ]; then
    # Oracle Linux 8 uses DNF configuration
    echo "Configuring deltarpm for Oracle Linux 8 (DNF)..."
    if [ -f /etc/dnf/dnf.conf ]; then
        sed -i 's/^deltarpm=.*/deltarpm=0/' /etc/dnf/dnf.conf
        if ! grep -q "^deltarpm=" /etc/dnf/dnf.conf; then
            echo "deltarpm=0" >> /etc/dnf/dnf.conf
        fi
    fi
else
    # Oracle Linux 7 and earlier use YUM configuration
    echo "Configuring deltarpm for Oracle Linux 7 (YUM)..."
    sed -i 's/^deltarpm=.*/deltarpm=0/' /etc/yum.conf
    if ! grep -q "^deltarpm=" /etc/yum.conf; then
        echo "deltarpm=0" >> /etc/yum.conf
    fi
fi

# Disable prestodelta in EPEL repo
if [ -f /etc/yum.repos.d/epel.repo ]; then
    sed -i '/^\[epel\]/a deltarpm=0' /etc/yum.repos.d/epel.repo
fi

yum clean all
yum -y install sshpass
yum -y install jq
yum -y install xorg-x11-xauth
yum -y install xclock xterm

# Install and configure SSM agent and firewall
# Check if SSM agent is already installed (may exist on OL8 AMI)
if ! rpm -q amazon-ssm-agent >/dev/null 2>&1; then
    echo "SSM agent not found, installing..."
    yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
else
    echo "SSM agent already installed, skipping installation"
fi

# Ensure SSM agent is started and enabled
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl stop firewalld
systemctl disable firewalld

# Ensure SSH host keys exist (may be missing from AMI)
echo "Checking SSH host keys..."
if [ ! -f /etc/ssh/ssh_host_rsa_key ] || [ ! -f /etc/ssh/ssh_host_ecdsa_key ] || [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    echo "SSH host keys missing, regenerating..."
    ssh-keygen -A
    echo "SSH host keys regenerated successfully"
else
    echo "SSH host keys already exist"
fi

# Configure SSH keepalive to prevent session timeouts
if ! grep -q "^ClientAliveInterval" /etc/ssh/sshd_config; then
    echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
    echo "ClientAliveCountMax 120" >> /etc/ssh/sshd_config
    echo "SSH keepalive settings added to sshd_config"
else
    echo "SSH keepalive settings already configured"
fi

# Test sshd configuration before restart
if sshd -t 2>/dev/null; then
    systemctl restart sshd
    echo "SSH keepalive configured: 60s interval, 120 retries = 2 hours max idle"
else
    echo "WARNING: sshd configuration test failed, skipping restart"
    sshd -t
fi

echo "Userdata script completed at $(date)"