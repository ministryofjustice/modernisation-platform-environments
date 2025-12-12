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
# Use lsblk to identify volumes by size
# 200GB volume = /oracle/software (oracle home)
# 150GB volume = /stage

echo "Detecting volume sizes..."
lsblk -b -n -o NAME,SIZE,TYPE | grep disk

# Find the 200GB volume (approximately 200*1024^3 = 214748364800 bytes)
# And 150GB volume (approximately 150*1024^3 = 161061273600 bytes)
ORACLE_SOFTWARE=""
STAGE=""

for dev in /dev/nvme*n1; do
    if [ "$dev" == "/dev/nvme0n1" ]; then
        continue  # Skip root volume
    fi
    
    size=$(lsblk -b -n -d -o SIZE "$dev")
    echo "Device $dev has size $size bytes"
    
    # Check if size is approximately 200GB (between 190GB and 210GB)
    if [ "$size" -gt 204010946560 ] && [ "$size" -lt 225485783040 ]; then
        ORACLE_SOFTWARE="$dev"
        echo "Found 200GB volume for /oracle/software: $dev"
    # Check if size is approximately 150GB (between 140GB and 160GB)
    elif [ "$size" -gt 150323855360 ] && [ "$size" -lt 171798691840 ]; then
        STAGE="$dev"
        echo "Found 150GB volume for /stage: $dev"
    fi
done

# Mount oracle software volume (200GB)
if [ -n "$ORACLE_SOFTWARE" ]; then
    echo "Mounting $ORACLE_SOFTWARE to /oracle/software"
    if ! grep -q "/oracle/software" /etc/fstab; then
        echo "$ORACLE_SOFTWARE /oracle/software ext4 defaults,nofail 0 2" >> /etc/fstab
    fi
    mount "$ORACLE_SOFTWARE" /oracle/software && echo "Successfully mounted /oracle/software" || echo "Failed to mount /oracle/software"
else
    echo "ERROR: 200GB volume not found"
fi

# Mount stage volume (150GB)
if [ -n "$STAGE" ]; then
    echo "Mounting $STAGE to /stage"
    if ! grep -q "/stage" /etc/fstab; then
        echo "$STAGE /stage ext4 defaults,nofail 0 2" >> /etc/fstab
    fi
    mount "$STAGE" /stage && echo "Successfully mounted /stage" || echo "Failed to mount /stage"
else
    echo "ERROR: 150GB volume not found"
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

# Disable deltarpm and prestodelta to avoid 404 errors and timeouts
sed -i 's/^deltarpm=.*/deltarpm=0/' /etc/yum.conf
if ! grep -q "^deltarpm=" /etc/yum.conf; then
    echo "deltarpm=0" >> /etc/yum.conf
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
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl stop firewalld
systemctl disable firewalld

echo "Userdata script completed at $(date)"