#!/bin/bash
##############################################
### Duo Authentication Proxy Installation
###
### This script installs and configures the
### Duo Authentication Proxy on Amazon Linux 2023
### for RADIUS-based MFA with WorkSpaces.
###
### Prerequisites:
### - Duo account and application created
### - Integration key, secret key, and API hostname
##############################################

set -e  # Exit on error

# Variables (passed from Terraform)
REGION="${region}"
RADIUS_SECRET_ARN="${radius_secret_arn}"
ENVIRONMENT="${environment}"
# DUO_IKEY="${duo_integration_key}"
# DUO_SKEY="${duo_secret_key}"
# DUO_HOST="${duo_api_hostname}"

# Log output
exec > >(tee /var/log/radius-setup.log)
exec 2>&1

echo "========================================="
echo "Duo Authentication Proxy Installation"
echo "Started at: $(date)"
echo "========================================="

# Update system
echo "Updating system packages..."
dnf update -y

# Install dependencies
echo "Installing dependencies..."
dnf install -y \
    python3 \
    python3-pip \
    gcc \
    python3-devel \
    openssl-devel \
    libffi-devel \
    wget

# Install AWS CLI v2
echo "Installing AWS CLI..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf awscliv2.zip aws/
fi

# Install CloudWatch agent
echo "Installing CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
rm -f amazon-cloudwatch-agent.rpm

# Download and install Duo Authentication Proxy
echo "Downloading Duo Authentication Proxy..."
DUO_VERSION="6.3.1"  # Update to latest version
cd /opt
wget "https://dl.duosecurity.com/duoauthproxy-$DUO_VERSION-src.tgz"
tar xzf "duoauthproxy-$DUO_VERSION-src.tgz"
cd "duoauthproxy-$DUO_VERSION-src"

echo "Installing Duo Authentication Proxy..."
make
cd duoauthproxy-build
./install --install-dir=/opt/duoauthproxy --service-user=duo_authproxy_svc --create-init-script=yes

# Create Duo service user
if ! id duo_authproxy_svc &>/dev/null; then
    useradd --system --shell /sbin/nologin duo_authproxy_svc
fi

# Get RADIUS shared secret from AWS Secrets Manager
echo "Retrieving RADIUS shared secret from Secrets Manager..."
RADIUS_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id "$RADIUS_SECRET_ARN" \
    --region "$REGION" \
    --query SecretString \
    --output text)

# Configure Duo Authentication Proxy
echo "Configuring Duo Authentication Proxy..."
cat > /opt/duoauthproxy/conf/authproxy.cfg <<EOF
[main]
debug=false

[ad_client]
host=laa-workspaces.local
service_account_username=Admin
service_account_password_protected=false
# service_account_password=GET_FROM_SECRETS_MANAGER
search_dn=DC=laa-workspaces,DC=local
security_group_dn=

[radius_server_auto]
ikey=${DUO_IKEY:-REPLACE_WITH_DUO_INTEGRATION_KEY}
skey=${DUO_SKEY:-REPLACE_WITH_DUO_SECRET_KEY}
api_host=${DUO_HOST:-REPLACE_WITH_DUO_API_HOSTNAME}
radius_ip_1=10.200.0.0/16
radius_secret_1=$RADIUS_SECRET
failmode=safe
client=ad_client
port=1812

[radius_server_accounting]
port=1813
EOF

chown -R duo_authproxy_svc:duo_authproxy_svc /opt/duoauthproxy

# Configure CloudWatch Logs
echo "Configuring CloudWatch Logs..."
cat > /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/duoauthproxy/log/authproxy.log",
            "log_group_name": "/aws/ec2/laa-workspaces-${ENVIRONMENT}/radius",
            "log_stream_name": "{instance_id}/duo-proxy",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/radius-setup.log",
            "log_group_name": "/aws/ec2/laa-workspaces-${ENVIRONMENT}/radius",
            "log_stream_name": "{instance_id}/setup",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "LAA/WorkSpaces/RADIUS",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          }
        ],
        "totalcpu": false
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
echo "Starting CloudWatch agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json

# Enable and start Duo proxy service
echo "Starting Duo Authentication Proxy..."
systemctl enable duoauthproxy
systemctl start duoauthproxy

# Verify service is running
sleep 5
if systemctl is-active --quiet duoauthproxy; then
    echo "✓ Duo Authentication Proxy is running"
else
    echo "✗ Duo Authentication Proxy failed to start"
    systemctl status duoauthproxy
    exit 1
fi

echo "========================================="
echo "Installation completed at: $(date)"
echo "========================================="
echo ""
echo "NEXT STEPS:"
echo "1. Update /opt/duoauthproxy/conf/authproxy.cfg with:"
echo "   - Duo integration key (ikey)"
echo "   - Duo secret key (skey)"
echo "   - Duo API hostname (api_host)"
echo "   - AD service account password"
echo "2. Restart the proxy: systemctl restart duoauthproxy"
echo "3. Test RADIUS: radtest username password localhost:1812 1 '$RADIUS_SECRET'"
echo "4. Update new-adds-radius.tf with this server's IP"
echo "========================================="
