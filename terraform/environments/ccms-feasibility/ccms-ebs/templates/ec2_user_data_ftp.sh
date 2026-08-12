#!/bin/bash
set -e

exec > /tmp/userdata.log 2>&1

yum install -y wget unzip vsftpd jq
dnf install -y git gcc libstdc++-devel automake libtool fuse fuse-devel curl-devel openssl-devel make libxml2-devel gcc-c++

# s3fs-fuse isn't in AL2023's package repos, so build it from source.
cd /usr/local/src
git clone https://github.com/s3fs-fuse/s3fs-fuse.git
cd s3fs-fuse
./autogen.sh
./configure
make
make install

# Mount the inbound/outbound S3 buckets using the FTP instance's own IAM
# role (iam_role=auto) rather than a persisted access key.
inbound_bucket="${ftp_inbound_bucket}"
outbound_bucket="${ftp_outbound_bucket}"

echo "user_allow_other" >> /etc/fuse.conf

mkdir -p "/mnt/$inbound_bucket" "/mnt/$outbound_bucket"

cp /etc/fstab "/etc/fstab.bak.$(date +%F-%H%M%S)"

LINE1="s3fs#$inbound_bucket /mnt/$inbound_bucket fuse _netdev,iam_role=auto,allow_other,mp_umask=0022,nonempty 0 0"
LINE2="s3fs#$outbound_bucket /mnt/$outbound_bucket fuse _netdev,iam_role=auto,allow_other,mp_umask=0022,nonempty 0 0"

grep -qxF "$LINE1" /etc/fstab || echo "$LINE1" >> /etc/fstab
grep -qxF "$LINE2" /etc/fstab || echo "$LINE2" >> /etc/fstab

echo "Testing mounts with: mount -a"
if ! mount -a 2>&1 | tee /etc/mount_errors.log; then
  echo "[ERROR] One or more mounts failed. See /etc/mount_errors.log:"
  cat /etc/mount_errors.log
  exit 1
else
  echo "[SUCCESS] All mounts applied successfully."
fi

echo "pasv_enable=YES" >> /etc/vsftpd/vsftpd.conf
echo "pasv_min_port=3000" >> /etc/vsftpd/vsftpd.conf
echo "pasv_max_port=3010" >> /etc/vsftpd/vsftpd.conf

systemctl enable vsftpd.service
systemctl restart vsftpd.service
