gpra
# LAA WorkSpaces with RADIUS MFA - Deployment Guide

**Document Version:** 2.3  
**Last Updated:** 13 May 2026  
**Environment:** AWS Modernisation Platform  
**Status:** Active - LinOTP + FreeRADIUS Implementation

---

## Important Notes

⚠️ **LDAP Binding Account:** This deployment uses the default **Admin** account for LDAP queries instead of a dedicated service account. This simplifies setup but should be reconsidered for production (create dedicated MFAService account with limited permissions).

⚠️ **BindDN Format:** AWS Managed Microsoft AD uses Organizational Units (OUs). The correct BindDN format is:
```
CN=Admin,OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local
```
NOT: `CN=Admin,CN=Users,DC=laa-workspaces,DC=local`

⚠️ **FreeRADIUS Auth-Type:** The installation script includes a critical fix for FreeRADIUS authentication. The site configuration sets `Auth-Type := Perl` in the authorize section to ensure LinOTP is called for authentication. Without this, RADIUS will return Access-Reject with "No Auth-Type found" error.

⚠️ **LinOTP Policies Required:** Before users can enroll tokens, three policies must be created in LinOTP:
- `selfservice_enrollment` (scope: selfservice, action: enrollTOTP, webprovisionGOOGLE)
- `limit_one_token` (scope: enrollment, action: maxtoken=1)
- `otp_authentication` (scope: authentication, action: otppin=1)

⚠️ **Automatic User Creation:** WorkSpaces automatically creates AD users during workspace provisioning. This enables the AWS Console "Invite user" feature and automatic welcome email delivery. Users will receive an email with their temporary password and WorkSpaces setup instructions.

⚠️ **ALB Access:** If the Application Load Balancer returns 504 errors, use SSM port forwarding to access LinOTP admin portal directly.

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

### Step 3.1: Retrieve AD Admin Password

**IMPORTANT:** For this deployment, we're using the default **Admin** account for LDAP binding instead of creating a dedicated service account. This simplifies initial setup and requires no additional permissions.

**Get the Admin password from Secrets Manager:**

1. Go to **AWS Secrets Manager** console
2. Find secret: `laa-workspaces-development-ad-admin-password-*`
3. Click on the secret
4. Scroll to **Secret value** section
5. Click **Retrieve secret value**
6. **Copy the password** - you'll need it for LDAP configuration

**Alternative - Via AWS CLI (if you can run commands):**

```bash
# Get AD admin password
aws secretsmanager get-secret-value \
  --secret-id <admin-password-secret-arn> \
  --region eu-west-2 \
  --query SecretString \
  --output text
```

**Note for Production:** Consider creating a dedicated service account (MFAService) with limited permissions for better security.

### Step 3.2: Retrieve LinOTP Admin Password

**Via AWS Console:**

1. Go to **AWS Secrets Manager** console
2. Find secret: `laa-workspaces-development-linotp-admin-password-*`
3. Click on the secret
4. Scroll to **Secret value** section
5. Click **Retrieve secret value**
6. **Copy the password**

**Alternative - Via AWS CLI (if you can run commands):**

```bash
# From workspace-components folder
cd workspace-components
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

**Method 1: Via SSM Port Forwarding (Recommended if ALB not accessible)**

If the ALB is not accessible due to security group or whitelist issues, use SSM port forwarding:

```bash
# Start SSM port forwarding session
aws ssm start-session \
  --target <radius-instance-id> \
  --region eu-west-2 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["443"],"localPortNumber":["8443"]}'
```

**Example with actual instance ID:**
```bash
aws ssm start-session \
  --target i-0d8eea56f3d64d97a \
  --region eu-west-2 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["443"],"localPortNumber":["8443"]}'
```

Keep this terminal running, then open browser to: `https://localhost:8443/manage`

**Method 2: Via ALB (If accessible)**

Open browser: `https://workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk/manage`

**Login Credentials:**
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
| **Server-URI** | `ldap://10.200.1.245, ldap://10.200.2.11` ⭐ Use AD DNS IPs from Step 2.7 |
| **BaseDN** | `OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local` |
| **BindDN** | `CN=Admin,OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local` |
| **Bind Password** | (Admin password from Step 3.1) |
| **Timeout** | `5` |
| **Network timeout** | `10` |

**IMPORTANT:** AWS Managed Microsoft AD uses Organizational Units (OUs), not Container Names (CNs). The BindDN format must include `OU=Users,OU=LAAWORKSPACES` where LAAWORKSPACES is your AD short name.

4. Click **Test LDAP Server connection**
   - **Expected:** Green checkmark ✅ "Connection successful"
   - **If fails:** See troubleshooting below

5. Click **Preset Active Directory**
   - This auto-fills user attribute mappings

6. Click **Save**

**Troubleshooting LDAP Connection Failures:**

If the connection test fails:

1. **Check Security Groups:**
   ```bash
   # Verify RADIUS EC2 can reach AD on port 389
   # From RADIUS instance via SSM:
   telnet 10.200.1.245 389
   telnet 10.200.2.11 389
   ```

2. **Verify BindDN Format:**
   - Must use OUs: `CN=Admin,OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local`
   - NOT CNs: `CN=Admin,CN=Users,DC=laa-workspaces,DC=local` ❌

3. **Check Password:**
   - Re-retrieve from Secrets Manager
   - Ensure no extra spaces or newlines

4. **Test LDAP from Command Line:**
   ```bash
   # SSH to RADIUS server
   aws ssm start-session --target <instance-id>
   
   # Install ldapsearch
   sudo yum install -y openldap-clients
   
   # Test LDAP bind
   ldapsearch -x -H ldap://10.200.1.245 \
     -D "CN=Admin,OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local" \
     -W \
     -b "OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local" \
     "(objectClass=user)"
   ```

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

### Step 3.7: Create Policies for Self-Service Enrollment

**IMPORTANT:** Policies must be created before users can enroll tokens via the self-service portal.

**In LinOTP Admin Portal (`/manage`):**

#### Policy 1: Enable Self-Service Enrollment

1. Click **Policies** tab
2. Click **New**
3. Fill in:
   - **Name:** `selfservice_enrollment`
   - **Scope:** Select `selfservice`
   - **Action:** `enrollTOTP, webprovisionGOOGLE`
   - **User:** `*` (all users)
   - **Realm:** `laa-workspaces`
   - **Client:** Leave empty or `*`
   - **Active:** ✅ Check the box
4. Click **Save**

#### Policy 2: Limit to One Token

1. Click **New**
2. Fill in:
   - **Name:** `limit_one_token`
   - **Scope:** Select `enrollment`
   - **Action:** `maxtoken=1`
   - **User:** `*`
   - **Realm:** `laa-workspaces`
   - **Active:** ✅
3. Click **Save**

#### Policy 3: Authentication Policy

1. Click **New**
2. Fill in:
   - **Name:** `otp_authentication`
   - **Scope:** Select `authentication`
   - **Action:** `otppin=1`
   - **User:** `*`
   - **Realm:** `laa-workspaces`
   - **Active:** ✅
3. Click **Save**

**Verify Policies:**
- All three policies should show as **Active**
- If you try to access the self-service portal now, you should see enrollment options

**Alternative - Import from Template File:**

The installation script created a template at `/tmp/samplepolicy.cfg`. To import:

1. SSH to RADIUS server: `aws ssm start-session --target <instance-id>`
2. View policy: `sudo cat /tmp/samplepolicy.cfg`
3. Copy content
4. In LinOTP UI **Policies** tab, click **Import Policy**
5. Paste content and click **Import**

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

### Step 3.9: Verify Complete LinOTP Setup

Run these tests to verify all components are working correctly before proceeding to user enrollment.

**Test 1: Verify All Services Running**

```bash
# SSH to RADIUS server
aws ssm start-session --target <instance-id> --region eu-west-2

# Check all services
sudo systemctl status mariadb httpd radiusd

# All should show "active (running)"
```

**Test 2: Verify Network Ports**

```bash
# Check services listening on expected ports
sudo netstat -tulpn | grep -E '(mysqld|httpd|radiusd)'

# Expected output:
# tcp 0.0.0.0:3306 - mysqld (MariaDB)
# tcp :::80 - httpd (HTTP)
# tcp :::443 - httpd (HTTPS)
# udp 0.0.0.0:1812 - radiusd (RADIUS auth)
# udp 0.0.0.0:1813 - radiusd (RADIUS accounting)
```

**Test 3: Test LinOTP Web Application**

```bash
# Test root endpoint (should redirect to /selfservice/)
curl -k -I https://localhost/

# Expected: HTTP/1.1 302 Found, Location: /selfservice/

# Test self-service portal
curl -k https://localhost/selfservice/login 2>/dev/null | grep -i "linotp\|login\|<title>"

# Expected: Should show LinOTP login page HTML

# Test admin portal (should require authentication)
curl -k -I https://localhost/manage

# Expected: HTTP/1.1 401 Unauthorized
```

**Test 4: Check LinOTP Logs**

```bash
# View LinOTP application logs
sudo tail -20 /var/log/linotp/linotp.log

# Should NOT show errors (warnings about missing optional modules are OK)

# Check for successful LDAP configuration
sudo grep -i "ldap\|realm" /var/log/linotp/linotp.log | tail -20
```

**Test 5: Check Apache Logs**

```bash
# Check Apache error log
sudo tail -20 /var/log/httpd/error_log

# Should NOT show 500 errors or Python exceptions
```

**Test 6: Verify FreeRADIUS Configuration**

```bash
# Check FreeRADIUS is listening
sudo systemctl status radiusd

# Check FreeRADIUS can reach LinOTP
curl -k https://localhost/validate/simplecheck 2>/dev/null

# Test FreeRADIUS in debug mode (optional)
sudo radiusd -X
# Press Ctrl+C to stop after checking no errors
```

**Test 7: Test Public ALB Access** (if ALB is accessible)

From your local machine:

```bash
# Test ALB DNS resolution
nslookup workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk

# Test ALB accessibility
curl -I https://workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk/

# Expected: HTTP/2 302 or HTTP/2 200 (not 504 Gateway Timeout)
```

**Test 8: Verify Realm Configuration in LinOTP**

In LinOTP admin portal (`https://localhost:8443/manage`):

1. Go to **LinOTP Config** → **Realms**
2. Verify `laa-workspaces` realm exists
3. Verify it's marked as **default** (should have ⭐ or checkmark)
4. Go to **User View** tab
5. Verify you can see AD users in the list

**Expected Results:**
- ✅ All services running
- ✅ All ports listening
- ✅ LinOTP web app accessible and responding
- ✅ No errors in logs (warnings OK)
- ✅ Users visible in LinOTP User View
- ✅ Realm configured and set as default

**If any test fails, see Troubleshooting section below.**

---

## PHASE 4: Test MFA Enrollment & Authentication

### Step 4.1: Create Test User & WorkSpace via Terraform

WorkSpaces and AD users are created automatically via Terraform.

**Edit:** `terraform/environments/laa-workspaces/new-workspace-users.tf`

```hcl
locals {
  workspace_users = {
    # Test user for MFA enrollment
    "test.user" = {
      first_name    = "Test"
      last_name     = "User"
      email         = "test.user@justice.gov.uk"
      instance_type = "standard"
    }
  }
}
```

**Deploy via GitHub Actions:**

1. Commit and push changes to a branch
2. Create Pull Request
3. Merge PR to trigger deployment
4. Terraform will automatically create the WorkSpace
5. **WorkSpaces automatically creates the AD user** and stores user metadata (email, first name, last name)

**Post-Deployment - Send User Invite:**

1. Go to **AWS Console** → **WorkSpaces** → Select the workspace
2. Click **Actions** → **Invite user** (or use the "Invite user" button on the workspace details page)
3. AWS will automatically send a welcome email to the user's email address with:
   - Registration code
   - Temporary password  
   - WorkSpaces client download link
   - Setup instructions

**Why this works:**
- WorkSpaces creates the AD user during workspace provisioning
- WorkSpaces stores user metadata (email, name) in its database
- Console "Invite user" button has access to email address
- Welcome email is sent automatically with all necessary credentials

**Note:** Users must register their WorkSpace using the registration code from the email before they can login.

### Step 4.2: User Receives Welcome Email & Registers WorkSpace

After you click "Invite user" in the console, the user will receive an email with:
- **Registration code** (e.g., WSpdx+ABC123)
- **Temporary password**
- **WorkSpaces client download links** (Windows, macOS, iOS, Android, Web)

**User registration steps:**

1. Download and install WorkSpaces client
2. Launch client and enter registration code
3. Login with temporary password
4. Set new permanent password (if prompted)
5. Complete WorkSpaces setup

**Note:** User must complete registration before enrolling in MFA.

### Step 4.3: User Self-Enrollment in MFA

**Method 1: Via SSM Port Forwarding (If ALB not accessible)**

```bash
# Start SSM port forwarding to access LinOTP portal
aws ssm start-session \
  --target i-0d8eea56f3d64d97a \
  --region eu-west-2 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["443"],"localPortNumber":["8444"]}'
```

Keep this terminal running, then open browser to: `https://localhost:8444/selfservice/`

**Method 2: Via ALB (If accessible)**

Open browser: `https://workspace-mfa.laa-development.modernisation-platform.service.justice.gov.uk/selfservice/`

**Enrollment Steps:**

1. Login with:
   - Username: `test.user`
   - Password: (use the password from the welcome email or your new password after registration)
2. Click **Enroll TOTP token**
3. Click **Generate Random Seed**
4. Click **Enroll Token**
5. **QR code appears**
6. Open Google Authenticator or Microsoft Authenticator app
7. Scan QR code
8. Token appears in app showing 6-digit code

**Expected:** Token successfully enrolled

### Step 4.4: Test RADIUS Authentication

SSH to RADIUS server and test locally:

```bash
# Connect to RADIUS server
aws ssm start-session --target i-0d8eea56f3d64d97a --region eu-west-2

# Get RADIUS shared secret
RADIUS_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id arn:aws:secretsmanager:eu-west-2:945484575162:secret:laa-workspaces-development-radius-shared-secret-* \
  --region eu-west-2 \
  --query SecretString \
  --output text)

# Get current 6-digit token from authenticator app (e.g., 914091)
# Test authentication (replace 914091 with actual token from your authenticator app)
# NOTE: Quote the secret with single quotes to handle special characters
radtest test.user 914091 localhost:1812 10 "$RADIUS_SECRET"
```

**Expected output:**
```
Sending Access-Request Id 123 from 0.0.0.0:xxxxx to 127.0.0.1:1812
        User-Name = 'test.user'
        User-Password = '914091'
        NAS-IP-Address = 127.0.0.1
        NAS-Port = 10
Received Access-Accept Id 123 from 127.0.0.1:1812 to 127.0.0.1:xxxxx length 53
        Reply-Message = 'LinOTP access granted'
```

**If Access-Reject:**
- Verify the 6-digit code is current (tokens change every 30 seconds)
- Try again with a fresh token
- Check FreeRADIUS logs for errors:
  ```bash
  sudo tail -20 /var/log/radius/radius.log
  ```
- If you see "ERROR: No Auth-Type found", check FreeRADIUS configuration (see Troubleshooting section)
- Verify policies are created and active in LinOTP admin portal

### Step 4.5: Test from Microsoft AD

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
      first_name    = "John"
      last_name     = "Doe"
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

**Post-Deployment - Send User Invites:**

After Terraform creates the WorkSpaces:

1. Go to **AWS Console** → **WorkSpaces** → Select workspace
2. Click **Invite user** button
3. AWS automatically sends welcome email with registration code and temporary password

See Step 4.1 for complete user invitation workflow.

### Step 5.3: User Login Process

**WorkSpaces login is a two-step process:**

**Step 1 - Initial Login:**
- **Username:** `john.doe`
- **Password:** Your AD password only (e.g., `MySecurePass123`)

**Step 2 - Verification Password Prompt:**
- WorkSpaces will prompt for "Verification password"
- **Enter your 6-digit OTP code** from your authenticator app (e.g., `837264`)
- Do NOT enter your password again, only the OTP code

**Example Flow:**
1. WorkSpaces prompts: "Enter your username and password"
   - Username: `john.doe`
   - Password: `MySecurePass123`
2. WorkSpaces prompts: "Enter verification password"
   - Verification password: `837264` (current OTP code from authenticator app)

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
- Verify BaseDN uses OU format: `OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local`
- Verify BindDN uses OU format: `CN=Admin,OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local`
- Check Admin account password is correct (retrieve from Secrets Manager)
- Test LDAP manually:
  ```bash
  sudo yum install -y openldap-clients
  ldapsearch -x -H ldap://<AD-IP> \
    -D "CN=Admin,OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local" \
    -W \
    -b "OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local" \
    "(objectClass=user)"
  ```

**IMPORTANT:** AWS Managed Microsoft AD uses Organizational Units (OUs), not Container Names (CNs) for the Users container.

### RADIUS Authentication Issues

#### Access-Reject from RADIUS Server

**Error:** "ERROR: No Auth-Type found: rejecting the user via Post-Auth-Type = Reject"

**Solution:** Verify FreeRADIUS site configuration includes Auth-Type setting:

```bash
# Check /etc/raddb/sites-enabled/linotp contains:
sudo cat /etc/raddb/sites-enabled/linotp | grep -A 10 "authorize {"
```

Should show:
```
authorize {
  preprocess
  perl
  if (ok) {
    update control {
      Auth-Type := Perl
    }
  }
}
```

**If missing:** The installation script should have added this. If deploying manually or script version is outdated, update as follows:

```bash
sudo nano /etc/raddb/sites-available/linotp
# Add the Auth-Type block after "perl" line in authorize section
sudo systemctl restart radiusd
```

#### Other Access-Reject Causes

**Check logs:**
```bash
sudo tail -f /var/log/radius/radius.log
```

**Common causes:**
- Incorrect shared secret (must be quoted if contains special chars: `radtest user token ip port '$secret'`)
- User not enrolled in LinOTP
- Token expired (30-second window)
- Wrong realm configured in `/etc/linotp2/rlm_perl.ini`
- Policies not created/active in LinOTP

**Verify LinOTP policies exist:**
1. Login to LinOTP admin portal: `https://localhost/manage`
2. Go to **Policies** tab
3. Confirm these policies exist and are **Active**:
   - `selfservice_enrollment` (scope: selfservice)
   - `limit_one_token` (scope: enrollment)
   - `otp_authentication` (scope: authentication)

#### WorkSpaces Login Fails with MFA

**Verify:**
1. RADIUS protocol is PAP (not MS-CHAPv2)
2. User has enrolled token in LinOTP
3. Token code is current
4. Password + token are combined (no space)

**Test RADIUS manually:**
```bash
# Note: Quote the secret if it contains special characters
radtest username <token> <radius-ip>:1812 10 '$secret'
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
