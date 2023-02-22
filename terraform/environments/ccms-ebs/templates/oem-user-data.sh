#!/usr/bin/env bash

yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
yum install -y https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
yum install -y jq telnet

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

groupadd oinstall
useradd -g oinstall applmgr

FSTAB=/etc/fstab
MOUNT_DIR=/mnt

# Create app mount point
FS_LABEL="APP"
FS_DIR=$${MOUNT_DIR}/oem/app
mkdir -p $${FS_DIR}
mkfs.ext4 -L $${FS_LABEL} /dev/xvdf
echo "LABEL=$${FS_LABEL} $${MOUNT_DIR}/oem/app ext4 defaults 0 0" >> $${FSTAB}

# Create inst mount point
FS_LABEL="INST"
FS_DIR=$${MOUNT_DIR}/oem/inst
mkdir -p $${FS_DIR}
mkfs.ext4 -L $${FS_LABEL} /dev/xvdg
echo "LABEL=$${FS_LABEL} $${MOUNT_DIR}/oem/inst ext4 defaults 0 0" >> $${FSTAB}

# Create dbf mount point
FS_LABEL="DBF"
FS_DIR=$${MOUNT_DIR}/oem/dbf
mkdir -p $${FS_DIR}
mkfs.ext4 -L $${FS_LABEL} /dev/xvdh
echo "LABEL=$${FS_LABEL} $${MOUNT_DIR}/oem/dbf ext4 defaults 0 0" >> $${FSTAB}

# Create the swap partition
swapoff -a
mkswap /dev/xvdi
swapon -L swap1 /dev/xvdi
echo "/dev/xvdi swap swap defaults 0 0" >> $${FSTAB}

# File Permissions
chown -R oracle:dba $${MOUNT_DIR}

# Mount shared disk
FS_DIR=$${MOUNT_DIR}/oem/shared
mkdir -p $${FS_DIR}
chmod go+rw $${FS_DIR}
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_id}.efs.eu-west-2.amazonaws.com:/ $${FS_DIR}
echo "${efs_id}.eu-west-2.amazonaws.com:/ $${FS_DIR} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >> $${FSTAB}

# Set hostname
hostnamectl set-hostname ${hostname}

# Mount all file systems in fstab
sed -i '11d' $${FSTAB}
mount -a
