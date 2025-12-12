#!/bin/bash

cd /tmp
yum -y install sshpass
yum -y install jq
sudo yum -y install xorg-x11-xauth
sudo yum -y install xclock xterm
sudo yum -y install nvme-cli

hostnamectl set-hostname oas

sed -i '2s/.*/search $${dns_zone_name} eu-west-2.compute.internal/' /etc/resolv.conf

yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl stop firewalld
systemctl disable firewalld

# Wait for EBS volumes to be available
sleep 10

# Mount EBS volumes
# nvme0n1 is the root volume
# nvme1n1 should be /dev/sdb (oracle software)
# nvme2n1 should be /dev/sdc (stage)

mkdir -p /oracle/software
mkdir -p /stage

# Check if volumes are already in fstab to avoid duplicates
if ! grep -q "/oracle/software" /etc/fstab; then
    echo "/dev/nvme1n1 /oracle/software ext4 defaults,nofail 0 2" >> /etc/fstab
fi

if ! grep -q "/stage" /etc/fstab; then
    echo "/dev/nvme2n1 /stage ext4 defaults,nofail 0 2" >> /etc/fstab
fi

# Mount all filesystems from fstab
mount -a

# Verify mounts
df -h | grep -E "oracle|stage" || echo "WARNING: Volumes not mounted"

# Set ownership and permissions if volumes are mounted
if mountpoint -q /oracle/software; then
    chown oracle:dba /oracle/software 2>/dev/null || true
    chmod -R 777 /oracle/software 2>/dev/null || true
fi

if mountpoint -q /stage; then
    chown oracle:dba /stage 2>/dev/null || true
    chmod -R 777 /stage 2>/dev/null || true
fi
dd if=/dev/zero of=/root/myswapfile bs=1M count=1024
chmod 600 /root/myswapfile
mkswap /root/myswapfile
swapon /root/myswapfile
echo "/root/myswapfile swap swap defaults 0 0" >> /etc/fstab

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