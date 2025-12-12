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

# Install NVMe tools FIRST before attempting to use them
curl -s https://raw.githubusercontent.com/aws/amazon-ec2-utils/master/ebsnvme-id > /sbin/ebsnvme-id
curl -s https://raw.githubusercontent.com/aws/amazon-ec2-utils/master/ec2nvme-nsid > /sbin/ec2nvme-nsid
sed -i '/^import argparse/i from __future__ import print_function' /sbin/ebsnvme-id
chmod +x /sbin/ebsnvme-id
chmod +x /sbin/ec2nvme-nsid

curl -s https://raw.githubusercontent.com/aws/amazon-ec2-utils/master/70-ec2-nvme-devices.rules > /etc/udev/rules.d/70-ec2-nvme-devices.rules
udevadm control --reload-rules && udevadm trigger && udevadm settle

# Wait for udev to settle
sleep 5

declare -A MOUNTS=(
    [/dev/sdb]="/oracle/software"
    [/dev/sdc]="/stage"
)

EFSTAB="/etc/fstab"

# Map NVMe devices to EBS volume names
declare -A NVMES=()
for n in /dev/nvme*n1; do
    if [[ -b "${n}" ]]; then
        D=$(ebsnvme-id "${n}" 2>/dev/null | grep -v 'Volume ID')
        if [[ -n ${D} ]]; then
            if [[ ${D} =~ /dev ]]; then
                NVMES[${D}]=${n}
            else
                NVMES[/dev/${D}]=${n}
            fi
        fi
    fi
done

# Mount the volumes
for M in "${!MOUNTS[@]}"; do
    L=${MOUNTS[${M}]}
    N=${NVMES[${M}]}
    if [[ -n ${N} ]]; then
        FS_DIR="${L}"
        if ! mountpoint -q "${FS_DIR}"; then
            mkdir -p "${FS_DIR}"
            # Add to fstab using the NVMe device name
            if ! grep -q "${N}" "${EFSTAB}"; then
                echo "${N} ${FS_DIR} ext4 defaults,nofail 0 2" >> "${EFSTAB}"
            fi
            mount "${N}" "${FS_DIR}"
        else
            echo "${FS_DIR} is already mounted:"
            mount | grep "${FS_DIR}"
        fi
    fi
done

# Set ownership and permissions
chown oracle:dba /oracle/software 2>/dev/null || true
chown oracle:dba /stage 2>/dev/null || true
chmod -R 777 /stage 2>/dev/null || true
chmod -R 777 /oracle/software 2>/dev/null || true
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