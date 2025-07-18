#!/bin/bash
set -e

exec > /tmp/userdata.log 2>&1

# amazon-linux-extras install -y epel
# yum install -y wget unzip vsftpd jq s3fs-fuse amazon-cloudwatch-agent telnet
yum install -y wget unzip vsftpd jq amazon-cloudwatch-agent telnet
dnf install -y git gcc libstdc++-devel automake libtool fuse fuse-devel curl-devel openssl-devel make libxml2-devel gcc-c++

cd /usr/local/src
git clone https://github.com/s3fs-fuse/s3fs-fuse.git
cd s3fs-fuse
./autogen.sh
./configure
make
make install

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

echo "pasv_enable=YES" >> /etc/vsftpd/vsftpd.conf
echo "pasv_min_port=3000" >> /etc/vsftpd/vsftpd.conf
echo "pasv_max_port=3010" >> /etc/vsftpd/vsftpd.conf
systemctl enable vsftpd.service
systemctl restart vsftpd.service

# cat > /etc/mount_s3_new.sh <<- EOM
# #!/bin/bash
ENV="${environment}"
inbound_bucket="${ftp_inbound_bucket}"
outbound_bucket="${ftp_outbound_bucket}"

SSHD_CONFIG="/etc/ssh/sshd_config"

# Backup original config
cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak_$(date +%F_%T)"

# Add port 22 if not already present
if ! grep -q '^Port 22' "$SSHD_CONFIG"; then
    echo "Port 22" | sudo tee -a "$SSHD_CONFIG" > /dev/null
fi

# Add port 8022 if not already present
if ! grep -q '^Port 8022' "$SSHD_CONFIG"; then
    echo "Port 8022" | sudo tee -a "$SSHD_CONFIG" > /dev/null
fi

SECRET_NAME="ftp-s3-$ENV-aws-key"

echo "the secret name is $SECRET_NAME"

# --- Fetch secret securely ---
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region eu-west-2 \
  --query SecretString \
  --output text)

# --- Extract credentials ---
USERNAME=$(echo "$SECRET_JSON" | jq -r '.USER')
PASSWORD=$(echo "$SECRET_JSON" | jq -r '.PASSWORD')

# --- Validate inputs ---
if [[ -z "$USERNAME" || -z "$PASSWORD" || "$USERNAME" == "null" || "$PASSWORD" == "null" ]]; then
  echo "USER or PASSWORD key is missing or null in the secret!"
  exit 1
fi

# --- Create user if not exists ---
if id "$USERNAME" &>/dev/null; then
  echo "User $USERNAME already exists."
else

useradd -m "$USERNAME"
# --- Set password securely using heredoc ---
chpasswd <<EOF
$USERNAME:$PASSWORD
EOF
echo "user created with password"
fi

# Check if PasswordAuthentication is disabled
if grep -qE "^#?PasswordAuthentication\s+no" "$SSHD_CONFIG"; then
  echo "Enabling PasswordAuthentication..."
  sed -i 's/^#\?PasswordAuthentication\s\+no/PasswordAuthentication yes/' "$SSHD_CONFIG"
else
  echo "PasswordAuthentication is already enabled or not explicitly set."
fi

# Ensure ChallengeResponseAuthentication is disabled (for passwords to work reliably)
if grep -qE "^#?ChallengeResponseAuthentication\s+yes" "$SSHD_CONFIG"; then
  echo "Disabling ChallengeResponseAuthentication..."
  sed -i 's/^#\?ChallengeResponseAuthentication\s\+yes/ChallengeResponseAuthentication no/' "$SSHD_CONFIG"
fi

# Restart sshd service
echo "Restarting sshd..."
systemctl restart sshd


U=$(id -u $USERNAME)
G=$(id -g $USERNAME)


if [[ -d "$USERNAME/S3/$inbound_bucket" ]]; then
  echo " the path $USERNAME/S3/$inbound_bucket exists"
else
  mkdir -p "$USERNAME/S3/$inbound_bucket"
fi

if [[ -d "$USERNAME/S3/$outbound_bucket" ]]; then
  echo " the path $USERNAME/S3/$inbound_bucket exists"
else
  mkdir -p "$USERNAME/S3/$outbound_bucket"
fi

chown -R "$USERNAME:users" "$USERNAME/S3/$inbound_bucket"
chown -R "$USERNAME:users" "$USERNAME/S3/$outbound_bucket"
chmod 755 "$USERNAME/S3/$inbound_bucket"
chmod 755 "$USERNAME/S3/$outbound_bucket"

# create mount directories
mkdir -p /$USERNAME/S3/laa-ccms-inbound-$ENV-mp /$USERNAME/S3/laa-ccms-outbound-$ENV-mp
# Backup fstab first
cp /etc/fstab /etc/fstab.bak.$(date +%F-%H%M%S)

# Define mount entries
LINE1="s3fs#$inbound_bucket /$USERNAME/S3/$inbound_bucket fuse _netdev,iam_role=auto,uid=$U,gid=$G,mp_umask=0022,allow_other,nonempty 0 0"
LINE2="s3fs#$outbound_bucket /$USERNAME/S3/$outbound_bucket fuse _netdev,iam_role=auto,uid=$U,gid=$G,mp_umask=0022,allow_other,nonempty 0 0"

# Append to fstab if not already present
grep -qxF "$LINE1" /etc/fstab || echo "$LINE1" >> /etc/fstab
grep -qxF "$LINE2" /etc/fstab || echo "$LINE2" >> /etc/fstab

echo "fstab updated."
# Test mounting all entries and capture errors
echo "Testing mounts with: mount -a"
if ! sudo mount -a 2>&1 | tee /etc/mount_errors.log; then
  echo "[ERROR] One or more mounts failed. See /tmp/mount_errors.log:"
  cat /etc/mount_errors.log
  exit 1
else
  echo "[SUCCESS] All mounts applied successfully."
  # if [[ "$ENV" != "production" ]]; then
  #   ln -s /$USERNAME/S3/$inbound_bucket/inbound-lambda-runs /home/$USERNAME/inbound-lambda-runs
  #   ln -s /$USERNAME/S3/$outbound_bucket/outbound-lambda-runs /home/$USERNAME/outbound-lambda-runs
  #   chown -h $USERNAME:$USERNAME /home/$USERNAME/inbound-lambda-runs
  #   chown -h $USERNAME:$USERNAME /home/$USERNAME/outbound-lambda-runs
  # fi
  ln -s /$USERNAME/S3/$inbound_bucket /home/$USERNAME/$inbound_bucket
  ln -s /$USERNAME/S3/$outbound_bucket /home/$USERNAME/$outbound_bucket
  chown -h $USERNAME:$USERNAME /home/$USERNAME/$inbound_bucket
  chown -h $USERNAME:$USERNAME /home/$USERNAME/$outbound_bucket

fi
# EOM

# chmod +x /etc/mount_s3_new.sh

# chmod +x /etc/rc.d/rc.local
# echo "/etc/mount_s3_new.sh" >> /etc/rc.local
# systemctl start rc-local.service
