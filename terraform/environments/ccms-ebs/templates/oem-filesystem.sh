#!/usr/bin/env bash

# Create oinstall group
groupadd oinstall

# Create applmgr user
useradd -g oinstall applmgr

MOUNT_DIR=/mnt

# Create appst mount point
FS_LABEL="APP"
FS_DIR=${MOUNT_DIR}/oem/app
mkdir -p ${FS_DIR}
mkfs.ext4 -L $FS_LABEL /dev/xvdf
echo "LABEL=$FS_LABEL ${MOUNT_DIR}/oem/app ext4 defaults 0 0" >> /etc/fstab

# Create inst mount point
FS_LABEL="INST"
FS_DIR=${MOUNT_DIR}/oem/inst
mkdir -p ${FS_DIR}
mkfs.ext4 -L $FS_LABEL /dev/xvdg
echo "LABEL=$FS_LABEL ${MOUNT_DIR}/oem/inst ext4 defaults 0 0" >> /etc/fstab

# Create dbf mount point
FS_LABEL="DBF"
FS_DIR=${MOUNT_DIR}/oem/dbf
mkdir -p ${FS_DIR}
mkfs.ext4 -L $FS_LABEL /dev/xvdh
echo "LABEL=$FS_LABEL ${MOUNT_DIR}/oem/dbf ext4 defaults 0 0" >> /etc/fstab

# Create the swap partition
swapoff -a
mkswap /dev/xvdi
swapon -L swap1 /dev/xvdi
echo "/dev/xvdi swap swap defaults 0 0" >> /etc/fstab

# File Permissions
chown -R oracle:dba ${MOUNT_DIR}

# Mount shared disk
FS_DIR=${MOUNT_DIR}/oem/shared
mkdir -p ${FS_DIR}
chmod go+rw ${FS_DIR}
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_id}.efs.eu-west-2.amazonaws.com:/ ${FS_DIR}
echo "${efs_id}.eu-west-2.amazonaws.com:/ ${FS_DIR} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >> /etc/fstab

# Set hostname
hostnamectl set-hostname ${hostname}

# Mount all file systems in fstab
sed -i '11d' /etc/fstab
mount -a
