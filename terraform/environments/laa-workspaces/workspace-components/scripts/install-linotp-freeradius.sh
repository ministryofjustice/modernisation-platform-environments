#!/bin/bash
##############################################
### LinOTP + FreeRADIUS Installation Script
###
### Based on: https://aws.amazon.com/blogs/desktop-and-application-streaming/integrating-freeradius-mfa-with-amazon-workspaces/
###
### This script installs and configures:
### - MariaDB (local database)
### - LinOTP 2.11.2 (MFA enrollment portal)
### - Apache httpd (web server with SSL)
### - FreeRADIUS (RADIUS authentication)
###
### Note: LDAP configuration must be done manually
### after Microsoft AD is deployed (Phase 3)
##############################################

set -e  # Exit on any error
set -x  # Print commands for debugging

# Variables from Terraform templatefile
REGION="${region}"
RADIUS_SECRET_ARN="${radius_secret_arn}"
LINOTP_ADMIN_PASSWORD_ARN="${linotp_admin_password_arn}"
MARIADB_ROOT_PASSWORD_ARN="${mariadb_root_password_arn}"
ENVIRONMENT="${environment}"
VPC_CIDR="${vpc_cidr}"
INSTANCE_HOSTNAME="radius-$${ENVIRONMENT}"

# Log to file and console
exec > >(tee -a /var/log/radius-install.log)
exec 2>&1

echo "========================================="
echo "Starting LinOTP + FreeRADIUS Installation"
echo "Environment: $${ENVIRONMENT}"
echo "Region: $${REGION}"
echo "========================================="

##############################################
### 1. System Preparation
##############################################

echo "[1/12] Updating system and installing prerequisites..."

# Update system
yum -y update

# Install AWS CLI and jq (for secrets retrieval)
yum -y install awscli jq

# Install EPEL repository
amazon-linux-extras install epel -y

##############################################
### 2. Install LinOTP Repository
##############################################

echo "[2/12] Installing LinOTP repository..."

# Download and install LinOTP repository package
yum localinstall -y http://dist.linotp.org/rpm/el7/linotp/x86_64/Packages/LinOTP_repos-1.1-1.el7.x86_64.rpm

# Fix repository URLs (they moved from linotp.org to dist.linotp.org)
sed -i 's,http://linotp.org/rpm/el7/dependencies/x86_64,http://dist.linotp.org/rpm/el7/dependencies/x86_64,g' /etc/yum.repos.d/linotp.repo
sed -i 's,http://linotp.org/rpm/el7/linotp/x86_64,http://dist.linotp.org/rpm/el7/linotp/x86_64,g' /etc/yum.repos.d/linotp.repo

##############################################
### 3. Retrieve Secrets from Secrets Manager
##############################################

echo "[3/12] Retrieving secrets from AWS Secrets Manager..."

# Wait for instance to have IAM role attached
sleep 10

# Retrieve MariaDB root password
MARIADB_ROOT_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "$${MARIADB_ROOT_PASSWORD_ARN}" \
  --region "$${REGION}" \
  --query SecretString \
  --output text)

# Retrieve LinOTP admin password
LINOTP_ADMIN_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "$${LINOTP_ADMIN_PASSWORD_ARN}" \
  --region "$${REGION}" \
  --query SecretString \
  --output text)

# Retrieve RADIUS shared secret
RADIUS_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "$${RADIUS_SECRET_ARN}" \
  --region "$${REGION}" \
  --query SecretString \
  --output text)

echo "✓ Secrets retrieved successfully"

##############################################
### 4. Install and Configure MariaDB
##############################################

echo "[4/12] Installing and configuring MariaDB..."

# Install MariaDB
yum install -y mariadb-server

# Enable and start MariaDB
systemctl enable mariadb
systemctl start mariadb

# Wait for MariaDB to start
sleep 5

# Secure MariaDB installation (automated)
mysql -e "UPDATE mysql.user SET Password=PASSWORD('$${MARIADB_ROOT_PASSWORD}') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

echo "✓ MariaDB installed and secured"

##############################################
### 5. Install and Configure LinOTP
##############################################

echo "[5/12] Installing LinOTP..."

# Install LinOTP and MariaDB connector
yum install -y LinOTP LinOTP_mariadb

# Fix SELinux contexts
restorecon -Rv /etc/linotp2/ || true
restorecon -Rv /var/log/linotp || true

# Configure LinOTP with MariaDB
# This creates the database and tables
echo "$${MARIADB_ROOT_PASSWORD}" | linotp-create-mariadb

# Lock python-repoze-who version for stability
yum install -y yum-plugin-versionlock
yum versionlock python-repoze-who

echo "✓ LinOTP installed and database created"

##############################################
### 6. Install and Configure Apache httpd
##############################################

echo "[6/12] Installing and configuring Apache httpd..."

# Install Apache and LinOTP vhost configuration
yum install -y LinOTP_apache

# Enable httpd service
systemctl enable httpd

# Backup default SSL config
mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.back || true

# Activate LinOTP SSL config
mv /etc/httpd/conf.d/ssl_linotp.conf.template /etc/httpd/conf.d/ssl_linotp.conf

# Generate self-signed SSL certificate
# Note: ALB terminates SSL, but this is needed for ALB -> EC2 connection
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
  -subj "/C=GB/ST=London/L=London/O=LAA/CN=$${INSTANCE_HOSTNAME}" \
  -keyout /etc/pki/tls/private/server.key \
  -out /etc/pki/tls/certs/server.crt

# Set permissions
chmod 600 /etc/pki/tls/private/server.key

# Start Apache
systemctl start httpd

echo "✓ Apache httpd installed and started"

##############################################
### 7. Configure LinOTP Admin Access
##############################################

echo "[7/12] Configuring LinOTP admin access..."

# Create admin user with password from Secrets Manager
# htdigest requires password on stdin
echo "$${LINOTP_ADMIN_PASSWORD}" | htdigest -c /etc/linotp2/admins "LinOTP2 admin area" admin

echo "✓ LinOTP admin user created"

##############################################
### 8. Create LinOTP Policy Configuration File
##############################################

echo "[8/12] Creating LinOTP policy configuration..."

cat > /tmp/samplepolicy.cfg <<'EOFPOLICY'
[Limit_to_one_token]
realm = *
name = Limit_to_one_token
action = maxtoken=1
client = *
user = *
time = * * * * * *;
active = True
scope = enrollment

[OTP_to_authenticate]
realm = *
name = OTP_to_authenticate
action = otppin = token_pin
client = *
user = *
time = * * * * * *;
active = True
scope = authentication

[Require_MFA_at_Self_Service_Portal]
realm = *
name = Require_MFA_at_Self_Service_Portal
active = False
client = *
user = *
time = * * * * * *;
action = mfa_login
scope = selfservice
EOFPOLICY

echo "✓ Policy file created at /tmp/samplepolicy.cfg"
echo "  Import this via LinOTP web UI after LDAP configuration"

##############################################
### 9. Install and Configure FreeRADIUS
##############################################

echo "[9/12] Installing FreeRADIUS..."

# Install FreeRADIUS and dependencies
yum install -y freeradius freeradius-perl freeradius-utils \
  perl-App-cpanminus perl-LWP-Protocol-https perl-Try-Tiny git

# Install Perl dependencies for LinOTP module
cpanm --notest Config::File

echo "✓ FreeRADIUS installed"

##############################################
### 10. Install LinOTP Perl Module for FreeRADIUS
##############################################

echo "[10/12] Installing LinOTP Perl module for FreeRADIUS..."

# Clone LinOTP FreeRADIUS integration
git clone https://github.com/LinOTP/linotp-auth-freeradius-perl.git \
  /usr/share/linotp/linotp-auth-freeradius-perl

# Backup default FreeRADIUS configs
mv /etc/raddb/clients.conf /etc/raddb/clients.conf.back
mv /etc/raddb/users /etc/raddb/users.back

# Create FreeRADIUS clients configuration
cat > /etc/raddb/clients.conf <<EOF
client localhost {
  ipaddr  = 127.0.0.1
  secret  = '$${RADIUS_SECRET}'
}

client workspaces_ad {
  ipaddr  = $${VPC_CIDR}
  secret  = '$${RADIUS_SECRET}'
}
EOF

# Configure FreeRADIUS Perl module
cat > /etc/raddb/mods-available/perl <<'EOF'
perl {
  filename = /usr/share/linotp/linotp-auth-freeradius-perl/radius_linotp.pm
}
EOF

# Activate Perl module
ln -s /etc/raddb/mods-available/perl /etc/raddb/mods-enabled/perl

# Create LinOTP Perl module config
cat > /etc/linotp2/rlm_perl.ini <<EOF
# IP of the LinOTP server
URL=https://localhost/validate/simplecheck

# LinOTP Realm (will be configured in LinOTP web UI)
REALM=laa-workspaces

# Debug mode
Debug=True

# Skip SSL certificate verification (self-signed)
SSL_CHECK=False
EOF

echo "✓ LinOTP Perl module installed and configured"

##############################################
### 11. Configure FreeRADIUS Sites
##############################################

echo "[11/12] Configuring FreeRADIUS sites..."

# Remove default site configs
rm -f /etc/raddb/sites-enabled/{inner-tunnel,default}
rm -f /etc/raddb/mods-enabled/eap

# Create LinOTP site configuration
cat > /etc/raddb/sites-available/linotp <<'EOF'
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
    perl
  }

  authenticate {
    Auth-Type Perl {
      perl
    }
  }

  preacct {
    preprocess
  }

  accounting {
  }

  session {
  }

  post-auth {
  }

  pre-proxy {
  }

  post-proxy {
  }
}
EOF

# Activate LinOTP site
ln -s /etc/raddb/sites-available/linotp /etc/raddb/sites-enabled/linotp

# Enable and start FreeRADIUS
systemctl enable radiusd
systemctl start radiusd

echo "✓ FreeRADIUS configured and started"

##############################################
### 12. Install and Configure CloudWatch Agent
##############################################

echo "[12/12] Installing CloudWatch agent..."

# Download and install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
rm -f amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/radius/radius.log",
            "log_group_name": "/aws/ec2/laa-workspaces/$${ENVIRONMENT}/radius",
            "log_stream_name": "{instance_id}/radius",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/linotp/linotp.log",
            "log_group_name": "/aws/ec2/laa-workspaces/$${ENVIRONMENT}/linotp",
            "log_stream_name": "{instance_id}/linotp",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "/aws/ec2/laa-workspaces/$${ENVIRONMENT}/apache",
            "log_stream_name": "{instance_id}/error",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/radius-install.log",
            "log_group_name": "/aws/ec2/laa-workspaces/$${ENVIRONMENT}/install",
            "log_stream_name": "{instance_id}/install",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json

echo "✓ CloudWatch agent installed and started"

##############################################
### Installation Complete
##############################################

echo "========================================="
echo "LinOTP + FreeRADIUS Installation Complete!"
echo "========================================="
echo ""
echo "Next Steps (Manual Configuration Required):"
echo ""
echo "1. Wait for Microsoft AD to be deployed (main folder deployment)"
echo ""
echo "2. Create AD service account for LDAP binding:"
echo "   - Username: MFAService"
echo "   - OU: OU=ServiceAccounts,DC=laa-workspaces,DC=local"
echo "   - Password: Store in Secrets Manager"
echo ""
echo "3. Access LinOTP Admin Portal:"
echo "   URL: https://workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk/manage"
echo "   Username: admin"
echo "   Password: (from Secrets Manager: $${LINOTP_ADMIN_PASSWORD_ARN})"
echo ""
echo "4. Configure LDAP UserIdResolver:"
echo "   - Get AD DNS IPs from Directory Service console"
echo "   - Resolver name: LAA-AD-Users"
echo "   - BaseDN: DC=laa-workspaces,DC=local"
echo "   - BindDN: CN=MFAService,OU=ServiceAccounts,DC=laa-workspaces,DC=local"
echo "   - BindDN Password: From Secrets Manager"
echo ""
echo "5. Create Realm and import policies"
echo ""
echo "6. Test user enrollment at:"
echo "   https://workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk"
echo ""
echo "========================================="
echo "Installation log: /var/log/radius-install.log"
echo "========================================="
