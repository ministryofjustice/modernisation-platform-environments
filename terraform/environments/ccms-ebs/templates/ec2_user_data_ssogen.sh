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

# 
#--Configure EFS
EFS_MOUNT_POINT=/SSOGEN
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
HOME=/root
. "$HOME/.cargo/env"
env
yum -y install git rpm-build make rust cargo openssl-devel gcc gcc-c++ cmake wget perl
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> /root/.bashrc
rm go1.22.0.linux-amd64.tar.gz
cmake --version
# wget https://cmake.org/files/v3.20/cmake-3.20.0.tar.gz
# echo "get cmake tar"
# tar -xzf cmake-3.20.0.tar.gz
# cd cmake-3.20.0
# ./bootstrap && make -j$(nproc) && make install
# sleep 5
# cmake --version
# VERSION=3.27.9
# curl -LO https://cmake.org/files/v3.27/cmake-$VERSION.tar.gz
# tar xf cmake-$VERSION.tar.gz
# cd cmake-$VERSION
# ./bootstrap --prefix=/usr/local
# make -j"$(nproc)"
# sudo make install
# cmake --version
/root/.cargo/bin/rustc --version
/root/.cargo/bin/cargo --version
cd /root
git clone https://github.com/aws/efs-utils
cd efs-utils
sed -i 's/--with system_rust --noclean/--without system_rust --noclean/g' /root/efs-utils/Makefile
env
make rpm
sudo yum -y install build/amazon-efs-utils*rpm
mkdir $EFS_MOUNT_POINT
mount -t efs -o tls ${efs_id}:/ $EFS_MOUNT_POINT
chmod go+rw $EFS_MOUNT_POINT
# create large file for better EFS performance 
# https://docs.aws.amazon.com/efs/latest/ug/performance.html
dd if=/dev/urandom of=$EFS_MOUNT_POINT/large_file_for_efs_performance bs=1024k count=10000
rm -fr /root/efs-utils
# === Final logs ===
echo "SSOGEN instance bootstrap completed for ${hostname}" >> /var/log/user-data.log
