#!/bin/bash
##############################################
### FreeRADIUS Installation with Google Authenticator
###
### This script installs and configures FreeRADIUS
### on Amazon Linux 2023 for TOTP-based MFA.
###
### Users will use Google Authenticator app
### for MFA tokens.
##############################################

set -e  # Exit on error

# Variables (passed from Terraform)
REGION="${region}"
RADIUS_SECRET_ARN="${radius_secret_arn}"
ENVIRONMENT="${environment}"

# Log output
exec > >(tee /var/log/radius-setup.log)
exec 2>&1

echo "========================================="
echo "FreeRADIUS Installation"
echo "Started at: $(date)"
echo "========================================="

# Update system
echo "Updating system packages..."
dnf update -y

# Install FreeRADIUS and dependencies
echo "Installing FreeRADIUS..."
dnf install -y \
    freeradius \
    freeradius-utils \
    google-authenticator \
    qrencode \
    python3 \
    python3-pip \
    pam-devel

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

# Get RADIUS shared secret from AWS Secrets Manager
echo "Retrieving RADIUS shared secret from Secrets Manager..."
RADIUS_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id "$RADIUS_SECRET_ARN" \
    --region "$REGION" \
    --query SecretString \
    --output text)

# Configure FreeRADIUS clients
echo "Configuring RADIUS clients..."
cat > /etc/raddb/clients.conf <<EOF
# Microsoft AD / WorkSpaces Directory
client workspaces_ad {
    ipaddr = 10.200.0.0/16
    secret = $RADIUS_SECRET
    shortname = workspaces-ad
    nas_type = other
}

# Localhost for testing
client localhost {
    ipaddr = 127.0.0.1
    secret = testing123
    shortname = localhost
}
EOF

# Configure PAM authentication with Google Authenticator
echo "Configuring PAM for Google Authenticator..."
cat > /etc/pam.d/radiusd <<EOF
#%PAM-1.0
auth       required     pam_google_authenticator.so forward_pass
auth       required     pam_unix.so use_first_pass
account    required     pam_unix.so
password   required     pam_unix.so
session    required     pam_unix.so
EOF

# Enable PAM in FreeRADIUS
echo "Enabling PAM module in FreeRADIUS..."
sed -i 's/^#.*pam$/\tpam/' /etc/raddb/sites-enabled/default

# Configure default site
cat > /etc/raddb/sites-available/default <<EOF
server default {
    listen {
        type = auth
        ipaddr = *
        port = 1812
    }

    listen {
        type = acct
        ipaddr = *
        port = 1813
    }

    authorize {
        preprocess
        chap
        mschap
        suffix
        files
        pap
    }

    authenticate {
        Auth-Type PAP {
            pam
        }
        Auth-Type MS-CHAP {
            mschap
        }
    }

    preacct {
        preprocess
        acct_unique
        suffix
        files
    }

    accounting {
        detail
        unix
        radutmp
    }

    session {
        radutmp
    }

    post-auth {
        update {
            &reply: += &session-state:
        }
        exec
        remove_reply_message_if_eap
    }

    pre-proxy {
    }

    post-proxy {
        eap
    }
}
EOF

# Set permissions
chown -R radiusd:radiusd /etc/raddb
chmod 640 /etc/raddb/clients.conf

# Configure CloudWatch Logs
echo "Configuring CloudWatch Logs..."
cat > /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/radius/radius.log",
            "log_group_name": "/aws/ec2/laa-workspaces-$${ENVIRONMENT}/radius",
            "log_stream_name": "{instance_id}/freeradius",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/radius-setup.log",
            "log_group_name": "/aws/ec2/laa-workspaces-$${ENVIRONMENT}/radius",
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

# Enable and start FreeRADIUS
echo "Starting FreeRADIUS..."
systemctl enable radiusd
systemctl start radiusd

# Verify service is running
sleep 3
if systemctl is-active --quiet radiusd; then
    echo "✓ FreeRADIUS is running"
else
    echo "✗ FreeRADIUS failed to start"
    systemctl status radiusd
    journalctl -u radiusd -n 50
    exit 1
fi

# Test RADIUS server
echo "Testing RADIUS server..."
radtest testuser password localhost 1812 testing123 || echo "Test failed (expected - no test user configured)"

echo "========================================="
echo "Installation completed at: $(date)"
echo "========================================="
echo ""
echo "NEXT STEPS:"
echo "1. Create test user: useradd testuser && passwd testuser"
echo "2. Setup Google Authenticator for user: su - testuser -c 'google-authenticator'"
echo "3. Test RADIUS authentication:"
echo "   radtest testuser 'password+token' localhost 1812 testing123"
echo "   (where 'password+token' is user's password followed by 6-digit token)"
echo "4. Update new-adds-radius.tf with this server's IP"
echo "5. Configure users in Active Directory with matching usernames"
echo "========================================="
