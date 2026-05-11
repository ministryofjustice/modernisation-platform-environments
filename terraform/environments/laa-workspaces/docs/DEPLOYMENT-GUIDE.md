gpra
# LAA WorkSpaces with RADIUS MFA - Deployment Guide

**Document Version:** 2.0  
**Last Updated:** 29 April 2026  
**Environment:** AWS Modernisation Platform  
**Status:** Switched to Microsoft AD with RADIUS MFA

---

## Overview

This guide documents the deployment process for AWS WorkSpaces integrated with AWS Managed Microsoft AD and RADIUS-based Multi-Factor Authentication (MFA).

### Architecture

```
User Login Attempt
    ↓
AWS WorkSpaces
    ↓
AWS Managed Microsoft AD
    ↓
RADIUS Server (MFA Validation)
    ↓
MFA Provider (Duo/Azure MFA/etc.)
```

### Why RADIUS MFA?

After exploring IAM Identity Center integration, we've chosen RADIUS-based MFA because:
- ✅ Full Terraform support (no manual directory creation)
- ✅ Proven solution with mature tooling
- ✅ Flexible MFA provider options (Duo, Azure MFA, FreeRADIUS)
- ✅ Better enterprise integration capabilities
- ✅ Comprehensive logging and monitoring

---

## Prerequisites

### AWS Account Requirements
- ✅ AWS Managed Microsoft AD support in region
- ✅ Appropriate IAM permissions for Terraform deployment
- ✅ RADIUS server infrastructure (Duo/Azure MFA/FreeRADIUS)
- ✅ VPC with private subnets across multiple AZs

### Repository Access
- ✅ Access to `modernisation-platform-environments` repository
- ✅ GitHub Actions permissions for deployment workflows

### MFA Provider
- Using: **LinOTP + FreeRADIUS** with self-service enrollment
- Refer to [LINOTP-FREERADIUS-IMPLEMENTATION-PLAN.md](LINOTP-FREERADIUS-IMPLEMENTATION-PLAN.md) for detailed setup

---

## Deployment Process - Step by Step

This deployment follows a **two-phase approach** with automated LinOTP installation:

1. **Phase 1**: Deploy workspace-components (VPC, ALB, RADIUS EC2 with auto-install)
2. **Phase 2**: Deploy main folder (Microsoft AD, WorkSpaces)
3. **Phase 3**: Manual LDAP configuration in LinOTP web UI

---

## PHASE 1: Deploy Network Infrastructure & RADIUS Server

### Overview

This phase deploys all foundational infrastructure including the RADIUS server with **automated LinOTP installation**.

**Location:** `terraform/environments/laa-workspaces/workspace-components/`

### What Gets Created

#### Network Infrastructure
- ✅ VPC (`10.200.0.0/16`)
- ✅ Private subnets (2 AZs): `10.200.1.0/24`, `10.200.2.0/24`
- ✅ Public subnets (2 AZs): `10.200.10.0/24`, `10.200.11.0/24`
- ✅ Internet Gateway
- ✅ Route tables (public with internet route, private isolated)

#### RADIUS Server Components
- ✅ EC2 instance (1x t3.medium, Amazon Linux 2)
- ✅ Security group (allows UDP 1812/1813 from VPC, HTTPS from ALB)
- ✅ IAM role with Secrets Manager and CloudWatch access
- ✅ **Automated installation of:**
  - MariaDB (local database)
  - LinOTP 2.11.2 (MFA enrollment portal)
  - Apache httpd with SSL
  - FreeRADIUS with LinOTP integration
  - CloudWatch agent

#### Load Balancer & SSL
- ✅ Application Load Balancer (public, 2 AZs)
- ✅ ACM certificate (DNS validated)
- ✅ Route 53 DNS record: `workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk`
- ✅ Target group pointing to RADIUS EC2 (HTTPS/443)
- ✅ Listeners (HTTPS/443 with ACM cert, HTTP/80 redirects to HTTPS)

#### Secrets & Credentials
- ✅ RADIUS shared secret (random, 32 chars)
- ✅ LinOTP admin password (random, 32 chars)
- ✅ MariaDB root password (random, 32 chars)

### Step-by-Step Deployment

#### Step 1.1: Navigate to workspace-components Directory

```bash
cd /Users/vladimirs.kovalovs/Desktop/Repos/modernisation-platform-environments/terraform/environments/laa-workspaces/workspace-components
```

#### Step 1.2: Initialize Terraform

```bash
terraform init
```

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

#### Step 1.3: Select Workspace

```bash
terraform workspace select laa-workspaces-development
```

Or create if it doesn't exist:
```bash
terraform workspace new laa-workspaces-development
```

#### Step 1.4: Review the Plan

```bash
terraform plan
```

**Review for these resources:**
- `aws_vpc.workspaces[0]`
- `aws_subnet.private_a[0]`, `aws_subnet.private_b[0]`
- `aws_subnet.public_a[0]`, `aws_subnet.public_b[0]`
- `aws_internet_gateway.main[0]`
- `aws_lb.radius_portal[0]` (Application Load Balancer)
- `aws_acm_certificate.radius_portal[0]`
- `aws_route53_record.radius_portal[0]`
- `aws_instance.radius_server[0]` ⭐ **This will auto-install LinOTP**
- `random_password` resources (3x for secrets)
- `aws_secretsmanager_secret` resources (3x)

**Count the resources:**
- Should be approximately 40-50 resources to create

#### Step 1.5: Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted.

**Deployment time:** ~15-20 minutes

**What happens during deployment:**
1. VPC and subnets created (~2 mins)
2. Security groups created (~1 min)
3. ACM certificate requested and DNS validation records created (~3 mins)
4. Certificate validation completes (~5 mins)
5. ALB created (~3 mins)
6. Route 53 DNS record created (~1 min)
7. **EC2 instance launched and user_data script runs** (~10-15 mins)
   - MariaDB installed
   - LinOTP installed and database created
   - Apache httpd configured with SSL
   - FreeRADIUS installed with LinOTP integration
   - CloudWatch agent configured

#### Step 1.6: Verify Deployment

```bash
terraform output
```

**Expected outputs:**
```hcl
radius_alb_dns_name = "laa-workspaces-development-radius-alb-1234567890.eu-west-2.elb.amazonaws.com"
radius_portal_url = "https://workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk"
radius_server_private_ips = ["10.200.1.123"]
vpc_id = "vpc-0123456789abcdef"
# ... more outputs
```

#### Step 1.7: Monitor Installation Progress

The EC2 user_data script runs automatically. Monitor progress:

```bash
# Get instance ID from outputs
INSTANCE_ID=$(terraform output -json radius_server_ids | jq -r '.[0]')

# Connect via Session Manager
aws ssm start-session --target $INSTANCE_ID --region eu-west-2

# Inside the instance, tail the installation log
sudo tail -f /var/log/radius-install.log
```

**Expected log output:**
```
[1/12] Updating system and installing prerequisites...
[2/12] Installing LinOTP repository...
[3/12] Retrieving secrets from AWS Secrets Manager...
✓ Secrets retrieved successfully
[4/12] Installing and configuring MariaDB...
✓ MariaDB installed and secured
[5/12] Installing LinOTP...
✓ LinOTP installed and database created
[6/12] Installing and configuring Apache httpd...
✓ Apache httpd installed and started
[7/12] Configuring LinOTP admin access...
✓ LinOTP admin user created
[8/12] Creating LinOTP policy configuration...
✓ Policy file created at /tmp/samplepolicy.cfg
[9/12] Installing FreeRADIUS...
✓ FreeRADIUS installed
[10/12] Installing LinOTP Perl module for FreeRADIUS...
✓ LinOTP Perl module installed and configured
[11/12] Configuring FreeRADIUS sites...
✓ FreeRADIUS configured and started
[12/12] Installing CloudWatch agent...
✓ CloudWatch agent installed and started
========================================
LinOTP + FreeRADIUS Installation Complete!
========================================
```

**Installation is complete when you see "Installation Complete!" message.**

#### Step 1.8: Verify Services are Running

```bash
# Still in SSM session
sudo systemctl status mariadb
sudo systemctl status httpd
sudo systemctl status radiusd
```

All services should show `active (running)`.

#### Step 1.9: Test LinOTP Portal Accessibility

Open browser and navigate to:
```
https://workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk
```

**Expected result:**
- LinOTP user self-service portal loads
- Shows login form

**If you see an error:**
- Wait 2-3 minutes for DNS propagation
- Check ALB target health in AWS Console
- Verify EC2 instance passed health checks

---

## PHASE 2: Deploy Microsoft AD & WorkSpaces

### Overview

This phase deploys AWS Managed Microsoft AD and configures RADIUS integration pointing to the servers created in Phase 1.

**Location:** `terraform/environments/laa-workspaces/` (main folder)

### What Gets Created

- ✅ AWS Managed Microsoft AD
  - Domain: `laa-workspaces.local`
  - Short name: `LAAWORKSPACES`
  - Edition: Standard
  - 2 domain controllers (deployed by AWS)
- ✅ RADIUS configuration on AD
  - Points to RADIUS server IP from Phase 1
  - Uses shared secret from Phase 1
  - Protocol: PAP (required for LinOTP)
- ✅ WorkSpaces directory registration
- ✅ CloudWatch log groups for AD logs
- ✅ Secrets Manager secret for AD admin password

### Prerequisites

- ✅ Phase 1 completed successfully
- ✅ workspace-components outputs available via remote state

### Step-by-Step Deployment

#### Step 2.1: Navigate to Main Directory

```bash
cd /Users/vladimirs.kovalovs/Desktop/Repos/modernisation-platform-environments/terraform/environments/laa-workspaces
```

#### Step 2.2: Initialize Terraform

```bash
terraform init
```

#### Step 2.3: Select Workspace

```bash
terraform workspace select laa-workspaces-development
```

#### Step 2.4: Review the Plan

```bash
terraform plan
```

**Review for these resources:**
- `aws_directory_service_directory.workspaces_ad` (Microsoft AD)
- `aws_directory_service_radius_settings.workspaces_ad_radius` ⭐ **RADIUS integration**
- `aws_workspaces_directory.workspaces_directory`
- `aws_secretsmanager_secret.ad_admin_password`

**Verify RADIUS configuration references:**
```hcl
radius_servers = ["10.200.1.123"]  # From Phase 1 outputs
authentication_protocol = "PAP"     # Required for LinOTP
```

#### Step 2.5: Deploy Microsoft AD

```bash
terraform apply
```

Type `yes` when prompted.

**Deployment time:** ~30-40 minutes (Microsoft AD takes time to provision)

**What happens:**
1. AD admin password secret created (~1 min)
2. Microsoft AD creation starts (~30-35 mins)
3. RADIUS settings applied to AD (~2 mins)
4. WorkSpaces directory registered (~3 mins)

**Note:** Microsoft AD deployment is the longest step. AWS is creating 2 domain controllers.

#### Step 2.6: Verify AD Deployment

```bash
terraform output
```

**Expected outputs:**
```hcl
ad_directory_id = "d-abc1234567"
ad_dns_ip_addresses = ["10.200.1.10", "10.200.2.10"]
workspaces_registration_code = "WSpdx+ABC123"
```

**In AWS Console:**
1. Navigate to **Directory Service** → **Directories**
2. Verify `laa-workspaces-development` shows status **Active**
3. Click on the directory
4. Go to **Networking & security** tab
5. Verify **RADIUS server** section shows:
   - Server IP addresses: Your RADIUS server IP
   - Authentication protocol: **PAP**
   - Status: **Enabled**

#### Step 2.7: Note AD DNS Servers

You'll need these for LinOTP LDAP configuration:

```bash
terraform output ad_dns_ip_addresses
```

**Save these IPs** - you'll use them in Phase 3.

---

## PHASE 3: Configure LinOTP LDAP Integration

### Overview

Now that Microsoft AD is deployed, configure LinOTP to authenticate users against AD via LDAP.

**This step is MANUAL** - LinOTP web UI configuration required.

### Prerequisites

- ✅ Phase 1 completed (LinOTP installed)
- ✅ Phase 2 completed (Microsoft AD deployed)
- ✅ AD DNS IP addresses from Phase 2

### Step 3.1: Create AD Service Account

The LinOTP server needs credentials to query AD users via LDAP.

**Option A: Via AWS Console**

1. Navigate to **Directory Service** → **Directories**
2. Click your directory: `laa-workspaces-development`
3. Go to **User management** → **Users**
4. Click **Create user**
5. Fill in:
   - **Username:** `MFAService`
   - **First name:** `MFA`
   - **Last name:** `Service`
   - **Email:** `mfa-service@laa-workspaces.local`
   - **Password:** Generate strong password
   - ✅ **Uncheck:** User must change password at next login
   - ✅ **Check:** Password never expires
6. Click **Create user**

**Option B: Via PowerShell (if you have domain-joined EC2)**

```powershell
New-ADUser -Name "MFAService" `
  -GivenName "MFA" `
  -Surname "Service" `
  -UserPrincipalName "MFAService@laa-workspaces.local" `
  -SamAccountName "MFAService" `
  -Path "CN=Users,DC=laa-workspaces,DC=local" `
  -AccountPassword (ConvertTo-SecureString "YourStrongPassword" -AsPlainText -Force) `
  -Enabled $true `
  -PasswordNeverExpires $true
```

**Step 3.1.1: Store Service Account Password**

Store the password in Secrets Manager for documentation:

```bash
aws secretsmanager create-secret \
  --name laa-workspaces-development-ad-mfa-service-password \
  --description "AD LDAP bind user password for LinOTP" \
  --secret-string "YourStrongPassword" \
  --region eu-west-2
```

### Step 3.2: Retrieve LinOTP Admin Password

```bash
# Get LinOTP admin password ARN
cd /Users/vladimirs.kovalovs/Desktop/Repos/modernisation-platform-environments/terraform/environments/laa-workspaces/workspace-components

LINOTP_ADMIN_ARN=$(terraform output -raw linotp_admin_password_arn)

# Retrieve password
aws secretsmanager get-secret-value \
  --secret-id "$LINOTP_ADMIN_ARN" \
  --region eu-west-2 \
  --query SecretString \
  --output text
```

**Save this password** - you'll use it to login to LinOTP.

### Step 3.3: Access LinOTP Admin Portal

1. Open browser: `https://workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk/manage`
2. Login with:
   - **Username:** `admin`
   - **Password:** (from Step 3.2)

**Expected:** LinOTP Management Interface loads

### Step 3.4: Configure LDAP UserIdResolver

1. Click **LinOTP Config** → **UserIdResolvers**
2. Click **New** → Select **LDAP**
3. Fill in the form:

| Field | Value |
|-------|-------|
| **Resolver name** | `LAA-AD-Users` |
| **Server-URI** | `ldap://10.200.1.10, ldap://10.200.2.10` ⭐ Use AD DNS IPs from Phase 2 |
| **BaseDN** | `CN=Users,DC=laa-workspaces,DC=local` |
| **BindDN** | `CN=MFAService,CN=Users,DC=laa-workspaces,DC=local` |
| **Bind Password** | (password from Step 3.1) |
| **Timeout** | `5` |
| **Network timeout** | `10` |

4. Click **Test LDAP Server connection**
   - **Expected:** Green checkmark "Connection successful"
   - **If fails:** Check security groups allow RADIUS EC2 → AD on port 389

5. Click **Preset Active Directory**
   - This auto-fills user attribute mappings

6. Click **Save**

### Step 3.5: Create Realm

1. Click **LinOTP Config** → **Realms**
2. Click **New**
3. Fill in:
   - **Realm name:** `laa-workspaces`
   - **Resolver:** Check `LAA-AD-Users`
4. Click **Save**
5. Click **Set as default** (important!)

### Step 3.6: Verify User Import

1. Click **User View** tab at the top
2. You should see list of AD users

**If you see users:** ✅ LDAP integration working!
**If no users:** 
- Check LDAP configuration
- Verify AD service account has read permissions
- Check BaseDN is correct

### Step 3.7: Import Policies

1. Click **Policies** tab
2. Click **Import Policy**
3. On the RADIUS server, the policy file was created at `/tmp/samplepolicy.cfg`

**To import:**

Option A: Copy policy content manually
1. SSH to RADIUS server: `aws ssm start-session --target <instance-id>`
2. View policy: `sudo cat /tmp/samplepolicy.cfg`
3. Copy content
4. In LinOTP UI, paste into import box
5. Click **Import**

Option B: Create policies manually via UI
- Create policy: **Limit_to_one_token**
  - Scope: enrollment
  - Action: maxtoken=1
- Create policy: **OTP_to_authenticate**
  - Scope: authentication
  - Action: otppin=token_pin

### Step 3.8: Update FreeRADIUS Realm Configuration

Since the realm is now created, verify FreeRADIUS knows about it:

```bash
# SSH to RADIUS server
aws ssm start-session --target <instance-id>

# Check FreeRADIUS LinOTP config
sudo cat /etc/linotp2/rlm_perl.ini
```

Should show:
```ini
REALM=laa-workspaces
```

If different, update:
```bash
sudo sed -i 's/REALM=.*/REALM=laa-workspaces/' /etc/linotp2/rlm_perl.ini
sudo systemctl restart radiusd
```

---

## PHASE 4: Test MFA Enrollment & Authentication

### Step 4.1: Create Test AD User

In Directory Service console:
1. Go to your AD directory → **Users**
2. Click **Create user**
3. Fill in:
   - Username: `test.user`
   - Password: Set a password
   - Uncheck "User must change password"
4. Click **Create user**

### Step 4.2: User Self-Enrollment

1. Open browser: `https://workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk`
2. Login with:
   - Username: `test.user`
   - Password: (AD password you set)
3. Click **Enroll TOTP token**
4. Click **Generate Random Seed**
5. Click **Enroll Token**
6. **QR code appears**
7. Open Google Authenticator or Microsoft Authenticator app
8. Scan QR code
9. Token appears in app showing 6-digit code

**Expected:** Token successfully enrolled

### Step 4.3: Test RADIUS Authentication

SSH to RADIUS server and test locally:

```bash
# Get current 6-digit token from authenticator app
# Let's say it shows: 123456

# Test authentication (replace with actual token)
radtest test.user 123456 localhost:1812 10 testing123
```

**Expected output:**
```
Received Access-Accept
```

**If Access-Reject:**
- Wait for token to refresh (tokens change every 30 seconds)
- Try again with new token
- Check `/var/log/radius/radius.log` for errors

### Step 4.4: Test from Microsoft AD

The AD RADIUS configuration should send test authentications:

1. In AWS Console: Directory Service → Your directory
2. Go to **Networking & security** tab
3. Click **Edit** in RADIUS server section
4. Click **Test RADIUS server**
5. Enter:
   - Username: `test.user`
   - Password: `<6-digit-token>`
6. Click **Test**

**Expected:** "RADIUS server test successful"

---

## PHASE 5: Deploy WorkSpaces (When Ready)

### Prerequisites

- ✅ All previous phases completed
- ✅ MFA tested and working
- ✅ Real users created in AD
- ✅ Users enrolled in LinOTP

### Step 5.1: Define Users in Terraform

Edit: `terraform/environments/laa-workspaces/new-workspace-users.tf`

```hcl
locals {
  workspace_users = {
    "john.doe" = {
      email         = "john.doe@justice.gov.uk"
      instance_type = "standard"
    }
  }
}
```

### Step 5.2: Deploy WorkSpaces

```bash
cd /Users/vladimirs.kovalovs/Desktop/Repos/modernisation-platform-environments/terraform/environments/laa-workspaces

terraform apply
```

### Step 5.3: User Login Process

Users will login to WorkSpaces with:
- **Username:** `john.doe`
- **Password:** `<AD-password><6-digit-MFA-token>` (combined, no space)

**Example:**
- AD password: `MySecurePass123`
- MFA token from app: `837264`
- **Enter in WorkSpaces:** `MySecurePass123837264`

---

## Troubleshooting

### Installation Issues

#### LinOTP Installation Script Fails

**Check installation log:**
```bash
aws ssm start-session --target <instance-id>
sudo cat /var/log/radius-install.log
```

**Common issues:**
- LinOTP repository unavailable: Check internet connectivity from instance
- Secrets Manager access denied: Verify IAM role has correct permissions
- MariaDB fails to start: Check disk space (`df -h`)

#### ALB Health Check Failing

**Check target health:**
1. AWS Console → EC2 → Target Groups
2. Click on radius target group
3. Check "Health status" tab

**If unhealthy:**
- Verify Apache httpd is running: `sudo systemctl status httpd`
- Check security group allows 443 from ALB
- Test health check endpoint: `curl -k https://localhost/manage`

#### Cannot Access LinOTP Portal

**DNS propagation:**
- Wait 2-3 minutes after terraform apply
- Test with ALB DNS name directly

**Certificate issues:**
- Verify ACM certificate is validated
- Check Route 53 validation records created

### LDAP Configuration Issues

#### Cannot Connect to AD

**Error:** "LDAP connection failed"

**Checks:**
1. Verify AD DNS IP addresses are correct
2. Check security group allows RADIUS EC2 → AD on port 389
3. Test connectivity:
   ```bash
   telnet <AD-IP> 389
   ```

#### No Users Visible in LinOTP

**Checks:**
- Verify BaseDN is correct: `CN=Users,DC=laa-workspaces,DC=local`
- Check service account has read permissions
- Verify BindDN format: `CN=MFAService,CN=Users,DC=laa-workspaces,DC=local`

### RADIUS Authentication Issues

#### Access-Reject from RADIUS Server

**Check logs:**
```bash
sudo tail -f /var/log/radius/radius.log
```

**Common causes:**
- Incorrect shared secret
- User not enrolled in LinOTP
- Token expired (30-second window)
- Wrong realm configured

#### WorkSpaces Login Fails with MFA

**Verify:**
1. RADIUS protocol is PAP (not MS-CHAPv2)
2. User has enrolled token in LinOTP
3. Token code is current
4. Password + token are combined (no space)

**Test RADIUS manually:**
```bash
radtest username <token> <radius-ip>:1812 10 <secret>
```

---

## Deployment Status Checklist

Use this checklist to track your deployment progress:

### Phase 1: Infrastructure (workspace-components)
- [ ] Terraform init completed
- [ ] Terraform workspace selected: laa-workspaces-development
- [ ] Terraform plan reviewed
- [ ] Terraform apply successful
- [ ] VPC created
- [ ] Public and private subnets created
- [ ] ALB deployed
- [ ] ACM certificate validated
- [ ] Route 53 DNS record created
- [ ] RADIUS EC2 instance launched
- [ ] Installation script completed (check `/var/log/radius-install.log`)
- [ ] All services running (mariadb, httpd, radiusd)
- [ ] LinOTP portal accessible via browser

### Phase 2: Microsoft AD (main folder)
- [ ] Terraform init completed
- [ ] Terraform plan reviewed (verify RADIUS settings)
- [ ] Terraform apply successful (~40 minutes)
- [ ] Microsoft AD status: Active
- [ ] RADIUS configuration shows: Protocol PAP, Enabled
- [ ] AD DNS IP addresses noted
- [ ] WorkSpaces directory registered

### Phase 3: LDAP Configuration (manual)
- [ ] AD service account created (MFAService)
- [ ] Service account password stored in Secrets Manager
- [ ] LinOTP admin password retrieved
- [ ] LinOTP admin portal accessible
- [ ] LDAP UserIdResolver configured
- [ ] LDAP connection test successful
- [ ] Realm created (laa-workspaces)
- [ ] Realm set as default
- [ ] Users visible in User View
- [ ] Policies imported

### Phase 4: Testing
- [ ] Test AD user created
- [ ] User self-enrolled via web portal
- [ ] QR code scanned in authenticator app
- [ ] Local RADIUS test passed (radtest)
- [ ] AD RADIUS test passed (AWS Console)
- [ ] CloudWatch logs showing authentication events

### Phase 5: WorkSpaces (when ready)
- [ ] Real users created in AD
- [ ] Users enrolled tokens via portal
- [ ] WorkSpaces defined in Terraform
- [ ] WorkSpaces deployed
- [ ] Users able to login with MFA

---

## Configuration Reference

### Files Modified in This Implementation

#### workspace-components/
- ✅ `platform_data.tf` - Uncommented Route53 data sources
- ✅ `new-vpc-subnets.tf` - Added public subnets, IGW, route tables
- ✅ `new-acm-radius.tf` - **NEW** - ACM certificate with DNS validation
- ✅ `new-alb-radius.tf` - **NEW** - Application Load Balancer
- ✅ `new-route53-radius.tf` - **NEW** - DNS record for portal
- ✅ `new-adds-radius-server.tf` - Updated to 1x t3.medium AL2, user_data added
- ✅ `scripts/install-linotp-freeradius.sh` - **NEW** - Auto-installation script
- ✅ `outputs.tf` - Added ALB DNS, portal URL, password ARNs
- ✅ `application_variables.json` - Added public subnet CIDRs

#### Main folder/
- ⚠️ `new-adds-radius.tf` - **Needs update**: Change protocol to PAP

### Important Configuration Values

**From application_variables.json:**
```json
{
  "development": {
    "workspace_bundle_id": "wsb-0q8gwp742",
    "region": "eu-west-2",
    "vpc_cidr": "10.200.0.0/16",
    "private_subnet_a_cidr": "10.200.1.0/24",
    "private_subnet_b_cidr": "10.200.2.0/24",
    "public_subnet_a_cidr": "10.200.10.0/24",
    "public_subnet_b_cidr": "10.200.11.0/24",
    "ad_directory_name": "laa-workspaces.local",
    "ad_short_name": "LAAWORKSPACES",
    "ad_edition": "Standard"
  }
}
```

### Key Secrets in Secrets Manager

1. **RADIUS shared secret** - Used by AD to authenticate to RADIUS server
2. **LinOTP admin password** - Login to `/manage` portal
3. **MariaDB root password** - Database access
4. **AD admin password** - Microsoft AD administrator
5. **AD MFA service password** - LDAP bind user for LinOTP

### DNS Records

| Record | Type | Value |
|--------|------|-------|
| workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk | A (Alias) | ALB DNS name |
| _validation.workspace-mfa.laa-development... | CNAME | ACM validation |

### Network Ports

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Internet | ALB | 80 | TCP | HTTP (redirects to HTTPS) |
| Internet | ALB | 443 | TCP | HTTPS (user portal) |
| ALB | RADIUS EC2 | 443 | TCP | Backend HTTPS |
| Microsoft AD | RADIUS EC2 | 1812 | UDP | RADIUS authentication |
| Microsoft AD | RADIUS EC2 | 1813 | UDP | RADIUS accounting |
| RADIUS EC2 | Microsoft AD | 389 | TCP | LDAP queries |

---

## Cost Estimation (Development Environment)

| Resource | Specification | Monthly Cost |
|----------|--------------|--------------|
| EC2 (RADIUS) | 1x t3.medium | ~$30 |
| EBS | 30GB gp3 | ~$2.40 |
| ALB | Standard | ~$20 |
| ACM | Certificate | Free |
| Route 53 | 1M queries | ~$0.40 |
| Microsoft AD | Standard Edition | ~$120 |
| CloudWatch Logs | ~5GB/month | ~$2.50 |
| Secrets Manager | 5 secrets | ~$2.00 |
| **TOTAL (Infrastructure)** | | **~$177/month** |

**Plus per-user WorkSpace costs:**
- Standard bundle: ~$25/month per user
- Performance bundle: ~$57/month per user

---

## Additional Resources

- **[LINOTP-FREERADIUS-IMPLEMENTATION-PLAN.md](LINOTP-FREERADIUS-IMPLEMENTATION-PLAN.md)** - Detailed implementation plan with all phases
- [AWS WorkSpaces Documentation](https://docs.aws.amazon.com/workspaces/)
- [AWS Managed Microsoft AD](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html)
- [RADIUS MFA with AWS Directory Service](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_mfa.html)
- [LinOTP Documentation](https://www.linotp.org/documentation)
- [FreeRADIUS Documentation](https://freeradius.org/documentation/)
- [AWS Blog: Integrating FreeRADIUS MFA with Amazon WorkSpaces](https://aws.amazon.com/blogs/desktop-and-application-streaming/integrating-freeradius-mfa-with-amazon-workspaces/)

---

**Document Owner:** LAA DevOps Team  
**Last Updated:** 1 May 2026  
**Document Version:** 3.0 - Automated LinOTP Installation  
**Status:** Ready for Deployment

---

**End of Document**
