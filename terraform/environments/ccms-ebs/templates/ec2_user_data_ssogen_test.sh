#!/bin/bash
set -exuo pipefail

# === Set hostname ===
hostnamectl set-hostname test-ssogen-manual

# === Configure resolv.conf ===
nmcli con modify "System eth0" ipv4.ignore-auto-dns no
nmcli con modify "System eth0" ipv4.dns-search "${mp_fqdn} eu-west-2.compute.internal"
nmcli con up "System eth0"
# === Base updates and packages ===
yum update -y

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config

# nvme1n1 = first attached volume goes to root
# nvme2n1 = second attached volume, etc.
# DISKSARRAY=(
#   "/dev/nvme2n1:/u01/product/fmw"
#   "/dev/nvme3n1:/u01/product/runtime/Domain/mserver"
#   "/dev/nvme4n1:/tmp"
# )

# Wait for disks to appear
sleep 25
IFS=',' read -r -a DISKS_ARRAY <<< "${DISKSARRAY}"

for entry in "$${DISKS_ARRAY[@]}"; do
  IFS=":" read -r disk mount <<< "$entry"
  echo "Processing $disk -> $mount"
  # Ensure directory exists
  mkdir -p "$mount"

  # Check if disk already has a filesystem
  if ! file -s "$disk" | grep -q "data"; then
    echo "Filesystem already exists on $disk"
  else
    echo "Creating filesystem on $disk"
    mkfs.xfs "$disk"
  fi

  # Mount disk
  echo "Mounting $disk to $mount"
  mount "$disk" "$mount"

  # Get UUID for persistent mount
  uuid=$(blkid -s UUID -o value "$${disk}")
  
  # Add to fstab if not already present
  if ! grep -q "$uuid" /etc/fstab; then
    echo "Adding to /etc/fstab"
    echo "UUID=$uuid $mount xfs defaults,nofail 0 2" >> /etc/fstab
  else
    echo "Entry already exists in /etc/fstab"
  fi
done

mkdir -p /mnt/efs
mount -t efs -o tls ${efs_id}:/ /mnt/efs
IFS=',' read -r -a EFS_MP_ARRAY <<< "${EFS_MOUNT_POINT_ARRAY}"

for var in "$${EFS_MP_ARRAY[@]}"; do
  IFS=":" read -r efsmount localmount <<< "$var"
  mkdir -p /mnt/efs/$efsmount
  mkdir -p $localmount
  mount -t efs -o tls ${efs_id}:/$efsmount $localmount
  chmod go+rw $localmount
  # create large file for better EFS performance 
  # https://docs.aws.amazon.com/efs/latest/ug/performance.html
  dd if=/dev/urandom of=$localmount/large_file_for_efs_performance bs=1024k count=10000
  echo "Adding to /etc/fstab"
  echo "${efs_id}:/$efsmount $localmount efs _netdev,tls,nofail 0 0" >> /etc/fstab
done

echo "SSOGEN instance bootstrap completed" >> /var/log/user-data.log