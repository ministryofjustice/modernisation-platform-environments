#!/bin/bash

exec > /tmp/userdata.log 2>&1

amazon-linux-extras install -y epel
yum install -y wget unzip vsftpd jq s3fs-fuse
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

wget https://s3.amazonaws.com/amazoncloudwatch-agent/oracle_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:cloud-watch-config

systemctl stop amazon-ssm-agent
rm -rf /var/lib/amazon/ssm/ipc/
systemctl start amazon-ssm-agent

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

# --- Fetch secret securely ---
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region "$REGION" \
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
fi

# --- Set password securely using heredoc ---
chpasswd <<EOF
$USERNAME:$PASSWORD
EOF

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


U=\$(id -u $USERNAME)
G=\$(id -g $USERNAME)

# B=(${inbound_bucket} ${outbound_bucket})

if [[ -d "${USERNAME}/S3/${inbound_bucket}" ]]; then
  echo " the path ${USERNAME}/S3/${inbound_bucket} exists"
else
  mkdir -p "${USERNAME}/S3/${inbound_bucket}"
fi

if [[ -d "${USERNAME}/S3/${outbound_bucket}" ]]; then
  echo " the path ${USERNAME}/S3/${inbound_bucket} exists"
else
  mkdir -p "${USERNAME}/S3/${outbound_bucket}"
fi

chown -R "${USERNAME}:users" "${USERNAME}/S3/${inbound_bucket}"
chown -R "${USERNAME}:users" "${USERNAME}/S3/${outbound_bucket}"
chmod 755 "${USERNAME}/S3/${inbound_bucket}"
chmod 755 "${USERNAME}/S3/${outbound_bucket}"
