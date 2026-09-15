#!/bin/bash
set -e
set -o pipefail

exec > /tmp/userdata.log 2>&1

yum install -y wget unzip vsftpd jq
dnf install -y git gcc libstdc++-devel automake libtool fuse3 fuse3-devel curl-devel openssl-devel make libxml2-devel gcc-c++

# s3fs-fuse isn't in AL2023's package repos, so build it from source.
cd /usr/local/src
git clone https://github.com/s3fs-fuse/s3fs-fuse.git
cd s3fs-fuse
./autogen.sh
./configure
make
make install

inbound_bucket="${ftp_inbound_bucket}"
outbound_bucket="${ftp_outbound_bucket}"

SSHD_CONFIG="/etc/ssh/sshd_config"

# Add port 8022 alongside the default 22 (needed by the 1stlocate ftp-lambda
# test target).
cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak_$(date +%F_%T)"
if ! grep -q '^Port 22' "$SSHD_CONFIG"; then
  echo "Port 22" >> "$SSHD_CONFIG"
fi
if ! grep -q '^Port 8022' "$SSHD_CONFIG"; then
  echo "Port 8022" >> "$SSHD_CONFIG"
fi

# --- Create the SSH test user used as the non-prod ftp-lambda SFTP target ---
SECRET_NAME="${ftp_test_user_secret_name}"

SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region eu-west-2 \
  --query SecretString \
  --output text)

USERNAME=$(echo "$SECRET_JSON" | jq -r '.USER')
PASSWORD=$(echo "$SECRET_JSON" | jq -r '.PASSWORD')

if [[ -z "$USERNAME" || "$USERNAME" == "null" ]]; then
  echo "USER key is missing or null in $SECRET_NAME!"
  exit 1
fi

if id "$USERNAME" &>/dev/null; then
  echo "User $USERNAME already exists."
else
  useradd -m "$USERNAME"
fi

if [[ -n "$PASSWORD" && "$PASSWORD" != "null" ]]; then
  chpasswd <<EOF
$USERNAME:$PASSWORD
EOF
fi

if grep -qE "^#?PasswordAuthentication\s+no" "$SSHD_CONFIG"; then
  sed -i 's/^#\?PasswordAuthentication\s\+no/PasswordAuthentication yes/' "$SSHD_CONFIG"
fi
if grep -qE "^#?ChallengeResponseAuthentication\s+yes" "$SSHD_CONFIG"; then
  sed -i 's/^#\?ChallengeResponseAuthentication\s\+yes/ChallengeResponseAuthentication no/' "$SSHD_CONFIG"
fi

systemctl restart sshd

# --- Mount the inbound/outbound S3 buckets, owned by the SSH test user ---
# Uses the FTP instance's own IAM role rather than a persisted access key.
# Mounted via a direct s3fs invocation rather than `mount -a`/fstab: this
# system has no mount.fuse3/mount.fuse.s3fs helper installed, so `mount -a`
# fails with "wrong fs type, bad option, bad superblock" even though s3fs
# itself works fine when run directly (confirmed against the same pattern
# the proven-working /rman mount on the ebsdb instance uses in
# ec2_user_data_ebs.sh). The fstab entry is still written for documentation/
# in case a helper becomes available later, but boot-time mounting doesn't
# depend on it.
U=$(id -u "$USERNAME")
G=$(id -g "$USERNAME")

echo "user_allow_other" >> /etc/fuse.conf

mkdir -p "/home/$USERNAME/S3/$inbound_bucket" "/home/$USERNAME/S3/$outbound_bucket"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/S3"

cp /etc/fstab "/etc/fstab.bak.$(date +%F-%H%M%S)"

# _netdev is only meaningful to fstab/systemd's boot ordering, not to s3fs
# itself - kept in the fstab line for documentation, left out of the direct
# invocation below.
S3FS_OPTS="allow_other,url=https://s3.eu-west-2.amazonaws.com,endpoint=eu-west-2,iam_role=${ftp_role_name},uid=$U,gid=$G,mp_umask=0022"
LINE1="$inbound_bucket /home/$USERNAME/S3/$inbound_bucket fuse.s3fs _netdev,$S3FS_OPTS 0 0"
LINE2="$outbound_bucket /home/$USERNAME/S3/$outbound_bucket fuse.s3fs _netdev,$S3FS_OPTS 0 0"

grep -qxF "$LINE1" /etc/fstab || echo "$LINE1" >> /etc/fstab
grep -qxF "$LINE2" /etc/fstab || echo "$LINE2" >> /etc/fstab

echo "Mounting buckets directly via s3fs"
if ! s3fs "$inbound_bucket" "/home/$USERNAME/S3/$inbound_bucket" -o "$S3FS_OPTS" 2>&1 | tee /etc/mount_errors.log \
  || ! s3fs "$outbound_bucket" "/home/$USERNAME/S3/$outbound_bucket" -o "$S3FS_OPTS" 2>&1 | tee -a /etc/mount_errors.log; then
  echo "[ERROR] One or more mounts failed. See /etc/mount_errors.log:"
  cat /etc/mount_errors.log
  exit 1
else
  echo "[SUCCESS] All mounts applied successfully."
  ln -s "/home/$USERNAME/S3/$inbound_bucket" "/home/$USERNAME/$inbound_bucket"
  ln -s "/home/$USERNAME/S3/$outbound_bucket" "/home/$USERNAME/$outbound_bucket"
  chown -h "$USERNAME:$USERNAME" "/home/$USERNAME/$inbound_bucket" "/home/$USERNAME/$outbound_bucket"
fi

echo "pasv_enable=YES" >> /etc/vsftpd/vsftpd.conf
echo "pasv_min_port=3000" >> /etc/vsftpd/vsftpd.conf
echo "pasv_max_port=3010" >> /etc/vsftpd/vsftpd.conf

systemctl enable vsftpd.service
systemctl restart vsftpd.service
