# LinOTP + FreeRADIUS MFA Implementation Plan

**Based on:** [AWS Blog - Integrating FreeRADIUS MFA with Amazon WorkSpaces](https://aws.amazon.com/blogs/desktop-and-application-streaming/integrating-freeradius-mfa-with-amazon-workspaces/)

**Document Status:** � Ready to Implement  
**Last Updated:** 30 April 2026  
**Current Progress:** Planning Complete - 0% Implementation

---

## Executive Summary

### What We're Building

A self-service MFA solution for AWS WorkSpaces using:
- **LinOTP** - Web portal for user self-enrollment and token management
- **MariaDB** - Database backend for storing user tokens (local on EC2)
- **Apache httpd** - Web server with SSL for user portal
- **FreeRADIUS** - RADIUS authentication server
- **Microsoft AD Integration** - LDAP connection for user validation
- **Application Load Balancer** - Public access with ACM SSL certificate
- **Single EC2 Instance** - Simplified deployment (1 server, not 2)

### Key Benefits Over Current Approach

| Feature | Current (Google Authenticator PAM) | AWS Blog (LinOTP) |
|---------|-----------------------------------|-------------------|
| **User Enrollment** | Admin must SSH and run commands | Users self-enroll via web portal |
| **User Experience** | Complex, requires IT support | Simple, self-service |
| **Token Management** | No reset capability | Users can reset tokens |
| **Admin Portal** | None | Web-based management interface |
| **Scalability** | Poor (manual per-user setup) | Excellent (automated) |
| **AD Integration** | None (local users only) | Full LDAP integration |
| **Policies** | None | Configurable (token limits, etc.) |
| **Web Interface** | ❌ | ✅ (ports 80/443) |

### User Enrollment Flow (New Approach)
workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk
```
1. User navigates to https://[RADIUS-IP]
2. User logs in with AD username/password
3. User clicks "Enroll TOTP Token"
4. User generates random seed (Google Authenticator compliant)
5. QR code appears
6. User scans QR code with authenticator app
7. Done! User can now login to WorkSpace with AD password + MFA token
```

---

## Current State vs Target State

### ✅ What We Have Now

1. **Infrastructure (workspace-components/ - **NEEDS UPDATE** for ports 80/443
   - ✅ IAM role with Secrets Manager access
   - ✅ 2x t3.small EC2 instances - **WILL CHANGE TO** 1x t3.medium (Amazon Linux 2
   - ✅ IAM role with Secrets Manager access
   - ✅ 2x t3.small EC2 instances (Amazon Linux 2023)
   - ✅ RADIUS shared secret in Secrets Manager
   - ✅ CloudWatch Logs and alarms

2. **Installation Script (workspace-components/scripts/install-freeradius.sh):**
   - ✅ FreeRADIUS installation
   - ✅ Google Authenticator PAM module
   - ✅ CloudWatch agent
   - ✅ Basic RADIUS client configuration

3. **Main Infrastructure:**
   - ✅ Microsoft AD (laa-workspaces.local)
   - ✅ RADIUS configuration on AD
   - ✅ WorkSpaces directory

### ❌ What We Need to Change

1. **EC2 Instance Configuration:**
   - ❌ Change count: 2 → **1 instance** (simplified HA approach)
   - ❌ Change AMI: Amazon Linux 2023 → **Amazon Linux 2** (AL2)
   - ❌ Change size: t3.small → **t3.medium** (LinOTP requires more resources)
   - ❌ Deploy in **private subnet** (ALB handles public access)

2. **Security Group:**
   - ❌ Add ingress: **TCP 443** (HTTPS from ALB)
   - ❌ Add ingress: **TCP 80** (HTTP from ALB)
   - ❌ Keep existing: UDP 1812/1813 (RADIUS from VPC)

3. **Application Load Balancer (NEW):**
   - ❌ Create ALB in public subnets
   - ❌ Create target group pointing to RADIUS EC2 instance
   - ❌ Configure HTTPS listener with ACM certificate
   - ❌ Configure HTTP → HTTPS redirect
   - ❌ Health checks on /manage endpoint

4. **ACM Certificate (NEW):**
   - ❌ Create certificate: primary domain + SAN (following OAS pattern)
   - ❌ DNS validation in both Route53 zones
   - ❌ Certificate validation resource

5. **Route 53 DNS (NEW):**
   - ❌ Create A record: `workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk`
   - ❌ Alias to ALB

6. **IAM Permissions:**
   - ✅ Secrets Manager access (already configured)
   - ✅ CloudWatch Logs (already configured)

7. **Installation Script - Complete Replacement:**
   - ❌ Remove: Google Authenticator PAM approach
   - ❌ Add: MariaDB installation and configuration
   - ❌ Add: LinOTP installation and configuration
   - ❌ Add: Apache httpd with SSL setup
   - ❌ Add: FreeRADIUS with LinOTP Perl module integration
   - ❌ Add: Self-signed SSL certificate generation (for ALB → EC2)
   - ❌ Add: LinOTP policy configuration
   - ❌ Add: LDAP configuration for AD integration

6. **Secrets Manager:**
   - ✅ RADIUS shared secret (exists)
   - ❌ Add: LinOTP admin password
   - ❌ Add: MariaDB root password
   - ❌ Add: AD LDAP bind user credentials

---

## Detailed Implementation Plan

### Phase 1: Update Infrastructure Code ⬜ NOT STARTED

**Files to Modify:**
- `workspace-components/new-adds-radius-server.tf`
- `workspace-components/new-adds-security-groups.tf` (or relevant SG file)
- `workspace-components/outputs.tf`

**Tasks:**

- [ ] **1.1 Update AMI Data Source**
  - Change from Amazon Linux 2023 to Amazon Linux 2
  - Location: `workspace-components/new-adds-radius-server.tf`
  ```hcl
  data "aws_ami" "amazon_linux_2Configuration**
  - Change count: `2` → `1` instance
  - Change: `t3.small` → `t3.medium`
  - Reason: LinOTP + MariaDB + Apache requires more resources
  - Deploy in private subnet (ALB handles public access)

- [ ] **1.3 Create Application Load Balancer**
  - Create ALB in public subnets (eu-west-2a and eu-west-2b)
  - Create ALB security group (allow 80/443 from internet, egress to RADIUS)
  - Create target group (HTTPS:443, health check on /manage)
  - Create HCreate ACM Certificate**
  - Primary domain: `modernisation-platform.service.justice.gov.uk`
  - SAN: `*.laa-development.modernisation-platform.service.justice.gov.uk`
  - Validation method: DNS
  - Create validation records in both Route53 zones:
    - Parent zone validation (aws.core-network-services provider)
    - Environment zone validation (aws.core-vpc provider)
  - Certificate validation resource

- [ ] **1.5 Create Route 53 DNS Record**
  - Name: `workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk`
  - Type: A record (Alias to ALB)
  - Provider: aws.core-vpc
  - Zone: laa-development.modernisation-platform.service.justice.gov.uk

- [ ] **1.6 Update RADIUS Security Group**
  - Add ingress rule: TCP 443 from ALB security group
  - Add ingress rule: TCP 80 from ALB security group
  - Keep existing: UDP 1812/1813 from VPC CIDR
  - Remove any public IP/0.0.0.0/0 rules

- [ ] **1.7 LinOTP + MariaDB + Apache requires more resources

- [ ] **1.3 Add Public IP or EIP**
  - **Option A:** Enable public IP on instances (simple, development)
  - **Option B:** Create Elastic IPs (better, static IPs)
  - **Option C:** Use ALB (best, production-ready)
  - **Decision needed:** Which option to implement?

- [ ] **1.4 Update Security Group**
  - Add ingress rule: TCP 443 from allowed IP ranges (e.g., office IPs, VPN)
  - Add in8 Update IAM Role Permissions**
  - Secrets Manager read for new secrets (already has access)
  - No additional permissions needed

- [ ] **1.9 Update Outputs**
  - Add: `radius_alb_dns_name` - ALB DNS name
  - Add: `linotp_portal_url` - Full URL (https://workspace-mfa.laa-development...
  resource "random_password" "linotp_admin_password" { }
  resource "aws_secretsmanager_secret" "linotp_admin_password" { }
  
  # MariaDB root password
  resource "random_password" "mariadb_root_password" { }
  resource "aws_secretsmanager_secret" "mariadb_root_password" { }
  
  # AD LDAP bind user password (if not already in Secrets Manager)
  resource "aws_secretsmanager_secret" "ad_ldap_bind_password" { }
  ```

- [ ] **1.6 Update IAM Role Permissions**
  - Add Secrets Manager read for new secrets
  - Consider: Directory Service read permissions if needed

- [ ] **1.7 Update Outputs**
  - Add: `radius_server_public_ips` (if using public IPs/EIPs)
  - Add: `linotp_portal_url` (https://IP or https://DNS)

**Completion Criteria:**
- ✅ Terraform plan runs successfully
- ✅ All new resources defined
- ✅ Security groups properly configured

---

### Phase 2: Create New Installation Script ⬜ NOT STARTED

**Files to Create/Replace:**
- `workspace-components/scripts/install-linotp-freeradius.sh` (NEW)
- `workspace-components/scripts/install-freeradius.sh` (ARCHIVE/DELETE)

**Script Sections:**

- [ ] **2.1 System Preparation**
  ```bash
  # Update system
  sudo yum -y update
  
  # Enable EPEL repository
  sudo amazon-linux-extras install epel -y
  
  # Install LinOTP repository
  sudo yum localinstall http://dist.linotp.org/rpm/el7/linotp/x86_64/Packages/LinOTP_repos-1.1-1.el7.x86_64.rpm -y
  
  # Fix repository URLs
  sed -i 's,http://linotp.org/rpm/el7/dependencies/x86_64, http://dist.linotp.org/rpm/el7/dependencies/x86_64,g' /etc/yum.repos.d/linotp.repo
  sed -i 's,http://linotp.org/rpm/el7/linotp/x86_64, http://dist.linotp.org/rpm/el7/linotp/x86_64,g' /etc/yum.repos.d/linotp.repo
  ```

- [ ] **2.2 Install and Configure MariaDB**
  ```bash
  # Install MariaDB
  sudo yum install mariadb-server -y
  
  # Enable and start service
  sudo systemctl enable mariadb
  sudo systemctl start mariadb
  
  # Retrieve root password from Secrets Manager
  MARIADB_ROOT_PASSWORD=$(aws secretsmanager get-secret-value \
    --secret-id "${mariadb_root_password_arn}" \
    --region "${region}" \
    --query SecretString --output text)
  
  # Secure installation (automated)
  mysql -e "UPDATE mysql.user SET Password=PASSWORD('$MARIADB_ROOT_PASSWORD') WHERE User='root';"
  mysql -e "DELETE FROM mysql.user WHERE User='';"
  mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
  mysql -e "DROP DATABASE IF EXISTS test;"
  mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
  mysql -e "FLUSH PRIVILEGES;"
  ```

- [ ] **2.3 Install and Configure LinOTP**
  ```bash
  # Install LinOTP and MariaDB connector
  sudo yum install -y LinOTP LinOTP_mariadb
  
  # Fix SELinux contexts
  sudo restorecon -Rv /etc/linotp2/
  sudo restorecon -Rv /var/log/linotp
  
  # Configure LinOTP with MariaDB
  # Note: This creates the database and configures connection
  sudo linotp-create-mariadb
  
  # Lock python-repoze-who version (stability)
  sudo yum install yum-plugin-versionlock -y
  sudo yum versionlock python-repoze-who
  ```

- [ ] **2.4 Install and Configure Apache httpd**
  ```bash
  # Install Apache and LinOTP vhost config
  sudo yum install LinOTP_apache -y
  
  # Enable httpd service
  sudo systemctl enable httpd
  
  # Backup default SSL config
  sudo mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.back
  
  # Activate LinOTP SSL config
  sudo mv /etc/httpd/conf.d/ssl_linotp.conf.template /etc/httpd/conf.d/ssl_linotp.conf
  
  # Generate self-signed SSL certificate
  sudo openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=GB/ST=London/L=London/O=LAA/CN=${instance_hostname}" \
    -keyout /etc/pki/tls/private/server.key \
    -out /etc/pki/tls/certs/server.crt
  
  # Set permissions
  sudo chmod 600 /etc/pki/tls/private/server.key
  
  # Start Apache
  sudo systemctl start httpd
  ```

- [ ] **2.5 Configure LinOTP Admin Access**
  ```bash
  # Retrieve LinOTP admin password from Secrets Manager
  LINOTP_ADMIN_PASSWORD=$(aws secretsmanager get-secret-value \
    --secret-id "${linotp_admin_password_arn}" \
    --region "${region}" \
    --query SecretString --output text)
  
  # Create admin user (password will be prompted)
  # Note: Need to automate this - htdigest requires interactive input
  echo "$LINOTP_ADMIN_PASSWORD" | sudo htdigest /etc/linotp2/admins "LinOTP2 admin area" admin
  
  # Reboot instance to apply all changes
  # NOTE: May want to defer reboot and do it explicitly
  ```

- [ ] **2.6 Configure LinOTP AD Integration**
  
  **This needs to be done via web UI or LinOTP CLI after installation:**
  
  Variables needed:
  - AD DNS IPs (from Microsoft AD)
  - AD BaseDN: `DC=laa-workspaces,DC=local`
  - AD BindDN: `CN=MFAService,OU=ServiceAccounts,DC=laa-workspaces,DC=local`
  - BindDN Password: From Secrets Manager
  
  **Manual steps documented:**
  1. Create service account in AD
  2. Configure via LinOTP web UI at https://[RADIUS-IP]/manage
  3. Create UserIdResolver (LDAP)
  4. Create Realm
  5. Import policy configuration

- [ ] **2.7 Create LinOTP Policy Configuration**
  
  Create `/tmp/samplepolicy.cfg`:
  ```ini
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
  ```
  
  Import via LinOTP CLI or web UI.

- [ ] **2.8 Install and Configure FreeRADIUS**
  ```bash
  # Install FreeRADIUS and dependencies
  sudo yum install -y freeradius freeradius-perl freeradius-utils \
    perl-App-cpanminus perl-LWP-Protocol-https perl-Try-Tiny git
  
  # Install Perl dependencies
  sudo cpanminus Config::File
  
  # Backup default configs
  sudo mv /etc/raddb/clients.conf /etc/raddb/clients.conf.back
  sudo mv /etc/raddb/users /etc/raddb/users.back
  
  # Create FreeRADIUS clients configuration
  # Note: Use RADIUS shared secret from Secrets Manager
  RADIUS_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id "${radius_secret_arn}" \
    --region "${region}" \
    --query SecretString --output text)
  
  cat > /etc/raddb/clients.conf <<EOF
  client localhost {
    ipaddr  = 127.0.0.1
    netmask = 32
    secret  = '$RADIUS_SECRET'
  }
  
  client workspaces_ad {
    ipaddr  = ${vpc_cidr}
    netmask = 16
    secret  = '$RADIUS_SECRET'
  }
  EOF
  ```

- [ ] **2.9 Install LinOTP Perl Module for FreeRADIUS**
  ```bash
  # Clone LinOTP FreeRADIUS integration
  sudo git clone https://github.com/LinOTP/linotp-auth-freeradius-perl.git \
    /usr/share/linotp/linotp-auth-freeradius-perl
  
  # Configure FreeRADIUS Perl module
  cat > /etc/raddb/mods-available/perl <<EOF
  perl {
    filename = /usr/share/linotp/linotp-auth-freeradius-perl/radius_linotp.pm
  }
  EOF
  
  # Activate Perl module
  sudo ln -s /etc/raddb/mods-available/perl /etc/raddb/mods-enabled/perl
  ```

- [ ] **2.10 Configure LinOTP Perl Module**
  ```bash
  # Create LinOTP Perl module config
  cat > /etc/linotp2/rlm_perl.ini <<EOF
  # IP of the LinOTP server
  URL=https://localhost/validate/simplecheck
  
  # LinOTP Realm (created in LinOTP web UI)
  REALM=${linotp_realm}
  
  # Debug mode
  Debug=True
  
  # Skip SSL certificate verification (self-signed)
  SSL_CHECK=False
  EOF
  ```

- [ ] **2.11 Configure FreeRADIUS Sites**
  ```bash
  # Remove default site configs
  sudo rm /etc/raddb/sites-enabled/{inner-tunnel,default}
  sudo rm /etc/raddb/mods-enabled/eap
  
  # Create LinOTP site configuration
  cat > /etc/raddb/sites-available/linotp <<'EOF'
  server default {
    listen {
      type = auth
      ipaddr = *
      port = 0
      limit {
        max_connections = 16
        lifetime = 0
        idle_timeout = 30
      }
    }
    
    listen {
      ipaddr = *
      port = 0
      type = acct
    }
    
    authorize {
      preprocess
      IPASS
      suffix
      ntdomain
      files
      expiration
      logintime
      update control {
        Auth-Type := Perl
      }
      pap
    }
    
    authenticate {
      Auth-Type Perl {
        perl
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
      -sql
      exec
      attr_filter.accounting_response
    }
    
    session { }
    
    post-auth {
      update {
        &reply: += &session-state:
      }
      -sql
      exec
      remove_reply_message_if_eap
    }
    
    pre-proxy { }
    
    post-proxy {
      eap
    }
  }
  EOF
  
  # Activate LinOTP site
  sudo ln -s /etc/raddb/sites-available/linotp /etc/raddb/sites-enabled/linotp
  
  # Enable and start FreeRADIUS
  sudo systemctl enable radiusd
  sudo systemctl start radiusd
  ```

- [ ] **2.12 Configure CloudWatch Logs**
  ```bash
  # Install CloudWatch agent
  wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
  sudo rpm -U ./amazon-cloudwatch-agent.rpm
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
              "log_group_name": "/aws/ec2/laa-workspaces-$${ENVIRONMENT}/radius",
              "log_stream_name": "{instance_id}/freeradius",
              "timezone": "UTC"
            },
            {
              "file_path": "/var/log/httpd/access_log",
              "log_group_name": "/aws/ec2/laa-workspaces-$${ENVIRONMENT}/radius",
              "log_stream_name": "{instance_id}/apache-access",
              "timezone": "UTC"
            },
            {
              "file_path": "/var/log/httpd/error_log",
              "log_group_name": "/aws/ec2/laa-workspaces-$${ENVIRONMENT}/radius",
              "log_stream_name": "{instance_id}/apache-error",
              "timezone": "UTC"
            },
            {
              "file_path": "/var/log/linotp/linotp.log",
              "log_group_name": "/aws/ec2/laa-workspaces-$${ENVIRONMENT}/radius",
              "log_stream_name": "{instance_id}/linotp",
              "timezone": "UTC"
            }
          ]
        }
      }
    }
  }
  EOF
  
  # Start CloudWatch agent
  sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json
  ```

**Completion Criteria:**
- ✅ Script executes without errors
- ✅ All services start successfully
- ✅ LinOTP web UI accessible at https://[IP]/manage
- ✅ User self-service portal accessible at https://[IP]

---

### Phase 3: Manual LinOTP Configuration ⬜ NOT STARTED

**Prerequisites:**
- Phase 1 and 2 completed
- RADIUS instances deployed and running
- AD service account created

**Tasks:**

- [ ] **3.1 Create AD Service Account**
  
  **Via AD Users and Computers or PowerShell:**
  - Username: `MFAService`
  - Password: Store in Secrets Manager
  - OU: `OU=ServiceAccounts,DC=laa-workspaces,DC=local`
  - Permissions: Read access to user OU
  - No login rights needed
  - Password never expires

- [ ] **3.2 Access LinOTP Admin Portal**
  
  1. Navigate to: `https://[RADIUS-PUBLIC-IP]/manage`
  2. Accept self-signed certificate warning
  3. Login with:
     - Username: `admin`
     - Password: From Secrets Manager (`linotp_admin_password`)

- [ ] **3.3 Configure LDAP UserIdResolver**
  
  1. Select **LinOTP Config** → **UserIdResolvers** → **New** → **LDAP**
  2. Populate fields:
     - **Resolver name:** `LAA-AD-Users`
     - **Server-URI:** `ldap://[AD-DNS-IP-1],ldap://[AD-DNS-IP-2]`
       - Get AD DNS IPs from Directory Service console
     - **BaseDN:** `OU=Users,DC=laa-workspaces,DC=local`
       - Or use specific OU where WorkSpace users are
     - **BindDN:** `CN=MFAService,OU=ServiceAccounts,DC=laa-workspaces,DC=local`
     - **Bind Password:** From Secrets Manager
  3. Click **Test LDAP Server connection** (should succeed)
  4. Click **Preset Active Directory**
  5. Click **Save**

- [ ] **3.4 Create Realm**
  
  1. Select **LinOTP Config** → **Realms** → **New**
  2. Enter **Realm name:** `laa-workspaces` (note this for FreeRADIUS config)
  3. Select the UserIdResolver: `LAA-AD-Users`
  4. Click **Save**
  5. Click **Save as default**

- [ ] **3.5 Verify User Import**
  
  1. Select **User View** tab
  2. Should see list of AD users
  3. Verify correct users are visible

- [ ] **3.6 Import Policies**
  
  1. Select **Policies** tab
  2. Click **Import Policies**
  3. Upload `samplepolicy.cfg` (created in installation script)
  4. Verify policies are active:
     - Limit_to_one_token
     - OTP_to_authenticate
     - Require_MFA_at_Self_Service_Portal (disabled)

- [ ] **3.7 Update FreeRADIUS LinOTP Config with Realm**
  
  **On RADIUS instances:**
  ```bash
  # Update realm in LinOTP Perl config
  sudo sed -i 's/REALM=.*/REALM=laa-workspaces/' /etc/linotp2/rlm_perl.ini
  
  # Restart FreeRADIUS
  sudo systemctl restart radiusd
  ```

**Completion Criteria:**
- ✅ LDAP connection successful
- ✅ AD users visible in LinOTP User View
- ✅ Realm configured and set as default
- ✅ Policies imported and active

---

### Phase 4: User Enrollment Testing ⬜ NOT STARTED

**Prerequisites:**
- Phase 3 completed
- Test AD user created in Microsoft AD

**Tasks:**

- [ ] **4.1 Prepare Test User**
  
  Create test user in AD:
  - Username: `test.user`
  - Password: Set and record
  - OU: Same as LinOTP BaseDN
  - Enabled for login

- [ ] **4.2 User Self-Enrollment**
  
  1. Navigate to: `https://[RADIUS-PUBLIC-IP]`
  2. Accept certificate warning
  3. Login with AD credentials:
     - Username: `test.user`
     - Password: AD password
  4. On **Enroll TOTP token** screen:
     - Click **"Generate Random Seed"**
     - Select **"Google Authenticator compliant"**
     - Follow prompts
  5. QR code appears
  6. Scan with Google Authenticator or Microsoft Authenticator app
  7. Verify token appears in app

- [ ] **4.3 Test Token via LinOTP API**
  
  ```bash
  # Test authentication
  curl -k "https://[RADIUS-IP]/validate/check?user=test.user&pass=[6-digit-OTP]"
  ```
  
  Expected response:
  ```json
  {
    "version": "LinOTP 2.11.2",
    "jsonrpc": "2.0",
    "result": {
      "status": true,
      "value": true
    },
    "id": 0
  }
  ```

- [ ] **4.4 Test via FreeRADIUS**
  
  **On RADIUS instance:**
  ```bash
  # Test local authentication
  radtest test.user [6-digit-OTP] localhost:1812 10 [RADIUS-SECRET]
  ```
  
  Expected: `Access-Accept`

- [ ] **4.5 Test from Different Instance in VPC**
  
  ```bash
  # Install radtest on another EC2 instance in same VPC
  sudo yum install freeradius-utils -y
  
  # Test against RADIUS server
  radtest test.user [6-digit-OTP] [RADIUS-PRIVATE-IP]:1812 10 [RADIUS-SECRET]
  ```
  
  Expected: `Access-Accept`

**Completion Criteria:**
- ✅ User successfully enrolls token via web portal
- ✅ LinOTP API validates token correctly
- ✅ FreeRADIUS accepts authentication
- ✅ Token works from remote test

---

### Phase 5: WorkSpaces Integration Testing ⬜ NOT STARTED

**Prerequisites:**
- Phase 4 completed and validated
- Microsoft AD RADIUS settings configured (should already be done via Terraform)

**Tasks:**

- [ ] **5.1 Verify RADIUS Configuration on AD**
  
  **AWS Console:**
  1. Navigate to Directory Service
  2. Select `laa-workspaces.local` directory
  3. **Network & Security** tab → **Multi-factor authentication**
  4. Verify settings:
     - Status: **Enabled**
     - RADIUS servers: Private IPs of both RADIUS instances
     - Port: **1812**
     - Shared secret: Matches Secrets Manager value
     - Protocol: **PAP** (LinOTP uses PAP, not MS-CHAPv2)
     - Timeout: **30** seconds
     - Retries: **3**

- [ ] **5.2 Update RADIUS Protocol (CRITICAL)**
  
  **⚠️ IMPORTANT:** LinOTP requires **PAP** protocol, not MS-CHAPv2
  
  Update `new-adds-radius.tf`:
  ```hcl
  resource "aws_directory_service_radius_settings" "workspaces_ad_radius" {
    # ... existing config ...
    authentication_protocol = "PAP"  # CHANGE FROM MS-CHAPv2
    # ... rest of config ...
  }
  ```
  
  Apply changes:
  ```bash
  terraform apply
  ```

- [ ] **5.3 Create Test WorkSpace**
  
  Update `new-workspace-users.tf`:
  ```hcl
  locals {
    workspace_users = {
      "test.user" = {
        email         = "test.user@justice.gov.uk"
        instance_type = "standard"
      }
    }
  }
  ```
  
  Deploy:
  ```bash
  terraform apply
  ```

- [ ] **5.4 Test WorkSpace Login with MFA**
  
  1. Get registration code:
     ```bash
     terraform output workspaces_ad_registration_code
     ```
  2. Download WorkSpaces client
  3. Register WorkSpace with code
  4. Login with:
     - Username: `test.user`
     - Password: `[AD-password][6-digit-OTP]`
       - Example: If AD password is `SecurePass123` and OTP is `847562`
       - Enter: `SecurePass123847562`
  5. Verify successful login

- [ ] **5.5 Monitor RADIUS Logs During Login**
  
  **CloudWatch Logs:**
  - Log group: `/aws/ec2/laa-workspaces-development/radius`
  - Stream: `[instance-id]/freeradius`
  
  Look for:
  - Access-Request from AD
  - LinOTP validation
  - Access-Accept response

**Completion Criteria:**
- ✅ RADIUS protocol set to PAP
- ✅ Test WorkSpace deployed
- ✅ User successfully logs in with MFA
- ✅ RADIUS logs show successful authentication

---

### Phase 6: High Availability Configuration ⬜ NOT STARTED

**Prerequisites:**
- Phase 5 completed
- Single RADIUS instance working end-to-end

**Tasks:**

- [ ] **6.1 Verify Both RADIUS Instances Running**
  
  Check both instances have:
  - MariaDB running
  - LinOTP configured
  - Apache httpd running
  - FreeRADIUS running
  - Same configuration

- [ ] **6.2 Synchronize LinOTP Databases**
  
  **Problem:** Each LinOTP instance has independent MariaDB database
  
  **Options:**
  
  **Option A: Shared RDS Database (Recommended)**
  - Create RDS MariaDB instance
  - Configure both LinOTP instances to use same RDS
  - Update `/etc/linotp2/linotp.ini` on both instances
  - Restart LinOTP
  
  **Option B: Database Replication**
  - Configure MariaDB master-slave replication
  - One instance is primary, other is replica
  - Failover logic needed
  
  **Option C: Manual Sync (Not Recommended)**
  - Users enroll on both instances separately
  - Administrative overhead

- [ ] **6.3 Test Failover**
  
  1. Stop FreeRADIUS on instance 1:
     ```bash
     sudo systemctl stop radiusd
     ```
  2. Test WorkSpace login (should use instance 2)
  3. Verify successful authentication
  4. Restart instance 1:
     ```bash
     sudo systemctl start radiusd
     ```
  5. Test again

- [ ] **6.4 Configure Health Checks**
  
  Update CloudWatch alarms to check:
  - FreeRADIUS service status
  - Apache httpd status
  - MariaDB status
  - LinOTP API responsiveness

**Completion Criteria:**
- ✅ Both instances fully configured
- ✅ Database synchronization implemented
- ✅ Failover tested and working
- ✅ Health monitoring in place

---

### Phase 7: Production Hardening ⬜ NOT STARTED

**Prerequisites:**
- Phase 6 completed
- HA working correctly

**Tasks:**

- [ ] **7.1 Replace Self-Signed Certificates**
  
  **Option A: ACM + ALB (Recommended)**
  - Create Application Load Balancer
  - Request ACM certificate for domain
  - Configure ALB with HTTPS listener
  - Point ALB to RADIUS instances (port 443)
  - Update security groups
  
  **Option B: Let's Encrypt**
  - Install certbot
  - Generate Let's Encrypt certificates
  - Configure Apache to use valid certificates
  - Set up auto-renewal

- [ ] **7.2 Implement Load Balancer (If ACM Route)**
  
  Create `workspace-components/new-adds-radius-alb.tf`:
  ```hcl
  resource "aws_lb" "radius_portal" {
    name               = "${local.application_name}-${local.environment}-radius-alb"
    internal           = false  # Or true if VPN access only
    load_balancer_type = "application"
    security_groups    = [aws_security_group.radius_alb.id]
    subnets           = [data.aws_subnet.public_a.id, data.aws_subnet.public_b.id]
  }
  
  resource "aws_lb_target_group" "radius_portal" {
    name     = "${local.application_name}-${local.environment}-radius-tg"
    port     = 443
    protocol = "HTTPS"
    vpc_id   = aws_vpc.workspaces[0].id
    
    health_check {
      path                = "/manage"
      protocol            = "HTTPS"
      matcher             = "200,401"  # 401 is OK (auth required)
      interval            = 30
      timeout             = 5
      healthy_threshold   = 2
      unhealthy_threshold = 2
    }
  }
  ```

- [ ] **7.3 Configure Route 53 DNS**
  
  Create DNS record:
  - Name: `mfa.laa-workspaces.local` (or public domain)
  - Type: A record (Alias to ALB)
  - TTL: 300
  
  Update documentation with DNS name instead of IP addresses

- [ ] **7.4 Restrict Security Group Access**
  
  Update RADIUS security group:
  - Remove: 0.0.0.0/0 access (if added during testing)
  - Add: Specific IP ranges (office IPs, VPN CIDR)
  - Keep: VPC CIDR for RADIUS traffic (UDP 1812/1813)

- [ ] **7.5 Enable RDS Encryption (If Using RDS)**
  
  If using shared RDS for LinOTP:
  - Enable encryption at rest
  - Enable automated backups
  - Configure retention period (7-30 days)
  - Enable Multi-AZ for HA

- [ ] **7.6 Implement Backup Strategy**
  
  - **LinOTP Database:** Daily RDS snapshots or MariaDB dumps
  - **Configuration Files:** Store in S3 or backup to S3
  - **Certificates:** Store in Secrets Manager or S3
  - **Policy Files:** Version control in Git
  
  Create backup script:
  ```bash
  # Backup MariaDB
  mysqldump -u root -p linotp > /backup/linotp-$(date +%Y%m%d).sql
  
  # Upload to S3
  aws s3 cp /backup/linotp-$(date +%Y%m%d).sql s3://[BACKUP-BUCKET]/linotp/
  ```

- [ ] **7.7 Security Hardening**
  
  - Disable root SSH access
  - Enforce IMDSv2 (already configured)
  - Configure OS-level firewalls (firewalld)
  - Disable unnecessary services
  - Configure SELinux (if not already in enforcing mode)
  - Regular OS patching schedule
  - Rotate secrets (RADIUS, MariaDB, LinOTP admin)

- [ ] **7.8 Documentation Updates**
  
  - Update DEPLOYMENT-GUIDE.md with production URLs
  - Create runbook for common operations
  - Document backup and restore procedures
  - Create incident response procedures
  - Document user onboarding process

**Completion Criteria:**
- ✅ Valid SSL certificates in use
- ✅ Load balancer configured (if applicable)
- ✅ DNS records configured
- ✅ Security groups properly restricted
- ✅ Backup strategy implemented
- ✅ Security hardening complete
- ✅ Documentation updated

---

## Implementation Timeline

### Estimated Effort

| Phase | Estimated Time | Complexity | Dependencies |
|-------|---------------|------------|--------------|
| Phase 1: Infrastructure Code | 2-4 hours | Medium | None |
| Phase 2: Installation Script | 4-6 hours | High | Phase 1 |
| Phase 3: LinOTP Configuration | 1-2 hours | Medium | Phase 2 |
| Phase 4: User Enrollment Testing | 1-2 hours | Low | Phase 3 |
| Phase 5: WorkSpaces Integration | 1-2 hours | Medium | Phase 4 |
| Phase 6: High Availability | 2-4 hours | High | Phase 5 |
| Phase 7: Production Hardening | 4-8 hours | High | Phase 6 |
| **TOTAL** | **15-28 hours** | - | - |

### Recommended Approach

**Sprint 1 (Week 1):**
- Complete Phase 1 (Infrastructure Code)
- Complete Phase 2 (Installation Script)
- Initial testing of installations

**Sprint 2 (Week 2):**
- Complete Phase 3 (LinOTP Configuration)
- Complete Phase 4 (User Enrollment Testing)
- Complete Phase 5 (WorkSpaces Integration)

**Sprint 3 (Week 3):**
- Complete Phase 6 (High Availability)
- Begin Phase 7 (Production Hardening)

**Sprint 4 (Week 4):**
- Complete Phase 7 (Production Hardening)
- End-to-end testing
- Documentation finalization
- Production deployment

---

## Key Decisions Required

### Decision 1: Public Access Method

**Question:** How should users access the LinOTP portal?

**Options:**

| Option | Pros | Cons | Cost | Recommendation |
|--------|------|------|------|----------------|
| **A. Public IPs on instances** | Simple, easy to implement | Less secure, no SSL cert | Free | ❌ Dev/test only |
| **B. Elastic IPs** | Static IPs, simple | Still less secure, no cert | ~$7/mo (2 EIPs) | ⚠️ OK for dev |
| **C. ALB + ACM** | Professional, valid certs, HA | More complex, higher cost | ~$20/mo | ✅ Recommended for prod |
| **D. VPN-only access** | Most secure | Users need VPN access | VPN cost | ✅ If VPN exists |

**Recommended:** Option C (ALB + ACM) for production, Option B for development

**Your Decision:** ✅ **Option C (ALB + ACM)** - CONFIRMED

---

### Decision 2: Database Strategy for HA

**Question:** How should LinOTP data be synchronized across instances?

**DECISION MADE:** ✅ **Using 1 RADIUS server only** - This decision is no longer applicable

~~**Options:**~~ (Not needed with single server)

**Rationale:** 
- Single server simplifies deployment significantly
- No database synchronization needed
- Can add 2nd server later if HA requirements change
- MariaDB runs locally on the single EC2 instance

**Your Decision:** ✅ **N/A - Single server deployment** - CONFIRMED

---

### Decision 3: SSL Certificate Strategy

**Question:** What SSL certificates should be used?

**Options:**

| Option | Pros | Cons | Cost | Recommendation |
|--------|------|------|------|----------------|
| **A. Self-signed** | Free, simple | Browser warnings, unprofessional | Free | ⚠️ Dev/test only |
| **B. ACM (with ALB)** | Free, auto-renewal, trusted | Requires ALB, public DNS | ALB cost | ✅ Best for AWS |
| **C. Let's Encrypt** | Free, trusted | Manual setup, renewal cron | Free | ✅ If no ALB |
| **D. Commercial cert** | Trusted, any use | Costs money | ~$50-200/yr | ❌ Unnecessary |

**Recommended:** Option B (ACM with ALB) if using ALB, otherwise Option C (Let's Encrypt)

**Your Decision:** ✅ **Development environment with domain: workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk** - CONFIRMED

**Certificate Strategy:** ✅ Same structure as OAS (primary domain + SAN wildcard) - CONFIRMED

---

### Decision 4: Environment Deployment

**Question:** Deploy to development first or go straight to production?

**Recommended Approach:**
1. ✅ Deploy to **development** environment first
2. ✅ Complete all testing in development
3. ✅ Document any issues and solutions
4. ✅ Only then deploy to production

**Your Decision:** ✅ **Development only (Phase 1 approach)** - CONFIRMED

---

## Risk Assessment

### High Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **LinOTP repo unavailable** | Blocker | Medium | Cache RPMs in S3, document URLs |
| **AD integration fails** | Blocker | Low | Test LDAP connectivity early, validate BindDN |
| **Database sync issues** | Major | Medium | Use RDS for shared database |
| **Certificate problems** | Moderate | Low | Use ACM or Let's Encrypt, test early |
| **User confusion** | Moderate | Medium | Clear documentation, training sessions |

### Medium Risks
 (APPROVED DESIGN)

| Resource | Quantity | Unit Cost | Monthly Cost |
|----------|----------|-----------|--------------|
| EC2 t3.medium | **1** | ~$30 | **~$30** |
| EBS (20GB gp3) | **1** | ~$2 | **~$2** |
| ALB | 1 | ~$16 + data | ~$20 |
| ACM Certificate | 1 | Free | $0 |
| Route 53 (queries) | - | ~$0.40/million | ~$1 |
| CloudWatch Logs | - | ~$0.50/GB | ~$5 |
| Secrets Manager | 3 secrets | ~$0.40 each | ~$1.20 |
| **TOTAL** | - | - | **~$59/month
| Resource | Quantity | Unit Cost | Monthly Cost |
|----------|----------|-----------|--------------|
| EC2 t3.medium | 2 | ~$30 | ~$60 |
| EBS (20GB gp3) | 2 | ~$2 | ~$4 |
| RDS db.t3.micro (optional) | 1 | ~$15 | ~$15 |
| Elastic IPs (optional) | 2 | ~$3.60 | ~$7 |
| ALB (optional) | 1 | ~$16 + data | ~$20 |
| CloudWatch Logs | - | ~$0.50/GB | ~$5 |
| Secrets Manager | 4 secrets | ~$0.40 each | ~$2 |
| **TOTAL (without ALB/RDS)** | - | - | **~$78** |
| **TOTAL (with ALB + RDS)** | - | - | **~$113** |

### Production Environment (Recommended)

| Resource | Quantity | Unit Cost | Monthly Cost |
|----------|----------|-----------|--------------|
| EC2 t3.medium | 2 | ~$30 | ~$60 |
| EBS (20GB gp3) | 2 | ~$2 | ~$4 |
| RDS db.t3.small (Multi-AZ) | 1 | ~$58 | ~$58 |
| ALB | 1 | ~$16 + data | ~$25 |
| Route 53 hosted zone | 1 | ~$0.50 | ~$0.50 |
| CloudWatch Logs | - | ~$0.50/GB | ~$10 |
| Secrets Manager | 4 secrets | ~$0.40 each | ~$2 |
| **TOTAL** | - | - | **~$160** |

*Plus per-user WorkSpace costs*

---

## Success Criteria

### Phase Completion

- [ ] All 7 phases completed
- [ ] All tasks marked as done
- [ ] All tests passed
- [ ] Documentation updated

### Functional Requirements

- [ ] Users can self-enroll via web portal
- [ ] Users can login to WorkSpaces with MFA
- [ ] Admin can manage tokens via LinOTP portal
- [ ] RADIUS authentication works consistently
- [ ] High availability confirmed (failover works)

### Non-Functional Requirements

- [ ] Response time < 2 seconds for RADIUS auth
- [ ] 99.9% availability (HA configuration)
- [ ] SSL certificates valid and trusted
- [ ] Security groups properly restricted
- [ ] CloudWatch monitoring in place
- [ ] Backup and restore tested

### User Acceptance

- [ ] Test users successfully enrolled
- [ ] Login process documented
- [ ] Support team trained
- [ ] User feedback collected and addressed

---

## Next Steps

1. **Review this plan** with team/stakeholders
2. **Make decisions** on the 4 key questions above
3. **Update application_variables.json** if needed (instance types, etc.)
4. **Begin Phase 1** - Update infrastructure code
5. **Create tracking board** (Jira, Trello, etc.) with these tasks

---

## Document Updates

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 30 Apr 2026 | 1.0 | Initial plan created | AI Assistant |
| | | | |

---

## References

- [AWS Blog: Integrating FreeRADIUS MFA with Amazon WorkSpaces](https://aws.amazon.com/blogs/desktop-and-application-streaming/integrating-freeradius-mfa-with-amazon-workspaces/)
- [LinOTP Documentation](https://www.linotp.org/documentation)
- [FreeRADIUS Documentation](https://freeradius.org/documentation/)
- [AWS Directory Service RADIUS Documentation](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_mfa.html)

---

**END OF DOCUMENT**
