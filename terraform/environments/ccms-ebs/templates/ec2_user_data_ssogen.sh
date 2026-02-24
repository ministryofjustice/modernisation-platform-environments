#!/bin/bash
set -exuo pipefail

# === Set hostname ===
hostnamectl set-hostname "${hostname}"
echo "127.0.0.1   ${hostname}" >> /etc/hosts

# === Base updates and packages ===
yum update -y
yum install -y unzip wget curl git lsof tree java-1.8.0-openjdk

# Install AWS SSM Agent
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent


# === Install AWS CLI ===
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# === Install Amazon CloudWatch Agent ===
wget https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config

# === Optional: Create oracle user & dirs ===
mkdir -p /oracle
useradd -g dba -m oracle || true
chown -R oracle:dba /oracle
chmod 775 /oracle

# nvme1n1 = first attached volume goes to root
# nvme2n1 = second attached volume, etc.
DISKSARRAY=(
  "/dev/nvme2n1:/u01/product/fmw"
  "/dev/nvme3n1:/u01/product/runtime/Domain/mserver"
  "/dev/nvme4n1:/tmp"
)

# Wait for disks to appear
sleep 5

for entry in "${DISKSARRAY[@]}"; do
  IFS=":" read -r disk mount <<< "$entry"
  echo "Processing $disk -> $mount"
  # Ensure directory exists
  mkdir -p "$mount"

  # Check if disk already has a filesystem
  if ! file -s "$disk" | grep -q "data"; then
    echo "Creating filesystem on $disk"
    mkfs.xfs "$disk"
  else
    echo "Filesystem already exists on $disk"
  fi

  # Mount disk
  echo "Mounting $disk to $mount"
  mount "$disk" "$mount"

  # Get UUID for persistent mount
  uuid=$(blkid -s UUID -o value "${disk}p1")
  
  # Add to fstab if not already present
  if ! grep -q "$uuid" /etc/fstab; then
    echo "Adding to /etc/fstab"
    echo "UUID=$uuid $mount xfs defaults,nofail 0 2" >> /etc/fstab
  else
    echo "Entry already exists in /etc/fstab"
  fi

done

deploy_cortex() {
  CORTEX_DIR=/tmp/CortexAgent
  CORTEX_VERSION=linux_8_8_0_133595_rpm

  #--Prep
  mkdir -p $CORTEX_DIR/linux_8_8_0_133595_rpm
  mkdir /etc/panw
  aws s3 sync s3://ccms-shared/CortexAgent/ $CORTEX_DIR #--ccms-shared is in the EBS dev account 767123802783. Bucket is shared at the ORG LEVEL.
  tar zxf $CORTEX_DIR/$CORTEX_VERSION.tar.gz -C $CORTEX_DIR/$CORTEX_VERSION
  cp $CORTEX_DIR/$CORTEX_VERSION/cortex.conf /etc/panw/cortex.conf
  sed -i -e '$a\' /etc/panw/cortex.conf && echo "--endpoint-tags ccms,ssogen" >> /etc/panw/cortex.conf

  #--Installs
  yum install -y selinux-policy-devel
  rpm -Uvh $CORTEX_DIR/$CORTEX_VERSION/cortex-*.rpm
  systemctl status traps_pmd
  echo "Cortex Install Routine Complete. Installation Is NOT GUARANTEED -- Check Logs For Success"
}

if [[ "${deploy_environment}" = "production" ]]; then
  deploy_cortex
fi

#--Configure EFS
EFS_MOUNT_POINT_ARRAY=("/stage" "/u01/shared/product/fmw" "/u01/shared/product/runtime/Domain/aserver" "/u01/shared/product/runtime/Domain/config")
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export HOME=/root
. "$HOME/.cargo/env"
env
yum -y install git rpm-build make rust cargo openssl-devel gcc gcc-c++ cmake wget perl
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> /root/.bashrc
# export PS1="[\u@\h \W]\$"
# source /root/.bashrc
rm go1.22.0.linux-amd64.tar.gz
cd /root
cmake --version
export PATH=/usr/local/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/bin:/sbin:/root/.cargo/bin:/usr/local/go/bin:/root/bin
wget https://cmake.org/files/v3.20/cmake-3.20.0.tar.gz
echo "get cmake tar"
tar -xzf cmake-3.20.0.tar.gz
cd cmake-3.20.0
env
./bootstrap && make -j$(nproc) && make install
cmake --version
/root/.cargo/bin/rustc --version
/root/.cargo/bin/cargo --version
cd /root
git clone https://github.com/aws/efs-utils
cd efs-utils
sed -i 's/--with system_rust --noclean/--without system_rust --noclean/g' /root/efs-utils/Makefile
env
make rpm
sudo yum -y install build/amazon-efs-utils*rpm
for var in "${EFS_MOUNT_POINT_ARRAY[@]}"; do
mkdir $var
mount -t efs -o tls ${efs_id}:/ $var
chmod go+rw $var
# create large file for better EFS performance 
# https://docs.aws.amazon.com/efs/latest/ug/performance.html
dd if=/dev/urandom of=$var/large_file_for_efs_performance bs=1024k count=10000
done

rm -fr /root/efs-utils

#--Hardening to level 1 standard
# git clone https://github.com/srikanththummala0470/RHEL7-CIS.git
# cd RHEL7-CIS
# git checkout feature/my-feature
pip3 install --upgrade pip setuptools wheel
pip3 install setuptools-rust
pip3 install cryptography
python3 -m pip install ansible-core==2.11.12
# export PATH=/usr/local/bin:$PATH
ansible --version
# ansible-galaxy collection install -r collections/requirements.yml
# ansible-playbook -i inventory.ini site.yml --tags level1-server

# === Final logs ===
echo "SSOGEN instance bootstrap completed for ${hostname}" >> /var/log/user-data.log
