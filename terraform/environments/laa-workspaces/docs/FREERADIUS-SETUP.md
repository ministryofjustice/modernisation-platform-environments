# FreeRADIUS MFA Setup Guide

## Overview

This guide covers deploying and configuring FreeRADIUS with Google Authenticator for MFA on AWS WorkSpaces.

## Architecture

```
User Login
    ↓
WorkSpaces Client
    ↓
AWS WorkSpaces
    ↓
Microsoft AD (validates username/password)
    ↓
FreeRADIUS Servers (2x t3.small in private subnets)
    ↓
Google Authenticator PAM (validates TOTP token)
    ↓
Success/Failure → User granted/denied access
```

## What's Deployed

### Phase 1: workspace-components (Already Configured)
- ✅ 2x EC2 instances (t3.small) running FreeRADIUS
- ✅ Security group allowing UDP 1812/1813 from VPC
- ✅ IAM role with Secrets Manager access
- ✅ CloudWatch logging and alarms
- ✅ RADIUS shared secret in Secrets Manager

### Phase 2: main (Automatically Configured)
- ✅ Microsoft AD configured with RADIUS settings
- ✅ References RADIUS server IPs from workspace-components outputs
- ✅ Uses shared secret from Secrets Manager

## Deployment Steps

### Step 1: Deploy Infrastructure

The infrastructure is already configured to use FreeRADIUS. Just deploy:

```bash
# Deploy Phase 1 (workspace-components)
cd terraform/environments/laa-workspaces/workspace-components
terraform init
terraform workspace select laa-workspaces-development
terraform plan
terraform apply

# Note the RADIUS server IPs from outputs:
terraform output radius_server_private_ips
```

**Expected outputs:**
```
radius_server_private_ips = [
  "10.200.1.xxx",
  "10.200.2.xxx"
]
```

### Step 2: Deploy Main Infrastructure

```bash
# Deploy Phase 2 (main)
cd ../  # Back to laa-workspaces
terraform init
terraform workspace select laa-workspaces-development
terraform plan
terraform apply
```

This will:
- Create Microsoft AD
- Configure RADIUS settings automatically
- Link AD to FreeRADIUS servers

### Step 3: Configure Users for MFA

Each user needs to be set up with Google Authenticator. You have two options:

#### Option A: Automated User Provisioning (Recommended)

Create a user setup script that can be run for each new user.

**On RADIUS Server:**

```bash
# SSH via Session Manager
aws ssm start-session --target i-xxxxxxxxx

# Run for each user
sudo /usr/local/bin/setup-mfa-user.sh username
```

Create this script on the RADIUS servers:

```bash
#!/bin/bash
# /usr/local/bin/setup-mfa-user.sh

USERNAME=$1

if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

# Create user if doesn't exist
if ! id "$USERNAME" &>/dev/null; then
    useradd -m -s /bin/bash "$USERNAME"
    echo "Created user: $USERNAME"
fi

# Generate initial password
INITIAL_PASSWORD=$(openssl rand -base64 12)
echo "$USERNAME:$INITIAL_PASSWORD" | chpasswd

# Setup Google Authenticator
sudo -u "$USERNAME" google-authenticator -t -d -f -r 3 -R 30 -w 3

# Display QR code
echo ""
echo "========================================="
echo "MFA Setup for: $USERNAME"
echo "========================================="
echo "Initial Password: $INITIAL_PASSWORD"
echo ""
echo "QR Code and backup codes saved to:"
echo "/home/$USERNAME/.google_authenticator"
echo ""
echo "Retrieve QR code with:"
echo "sudo cat /home/$USERNAME/.google_authenticator"
echo "========================================="
```

#### Option B: Manual User Setup

**For each user:**

1. SSH to RADIUS server via Session Manager:
   ```bash
   aws ssm start-session --target i-xxxxxxxxx
   ```

2. Create user:
   ```bash
   sudo useradd -m username
   sudo passwd username  # Set initial password
   ```

3. Setup Google Authenticator:
   ```bash
   sudo su - username
   google-authenticator
   ```

4. Answer the prompts:
   - **Time-based tokens?** `y` (yes)
   - **Update .google_authenticator?** `y` (yes)
   - **Disallow multiple uses?** `y` (yes)
   - **Increase window?** `n` (no)
   - **Rate limiting?** `y` (yes)

5. **IMPORTANT:** Save the emergency scratch codes and QR code
   - QR code will be displayed in terminal
   - Emergency codes are backup codes if phone is lost

6. Share with user:
   - Send QR code (securely) or secret key
   - Send emergency scratch codes (securely, separate from QR)
   - Send initial password
   - Instructions to download Google Authenticator app

### Step 4: Test RADIUS Authentication

**From RADIUS server:**

```bash
# Test with password + token
# Format: password followed immediately by 6-digit token
radtest username 'MyPassword123456' localhost 1812 testing123

# If successful:
Received Access-Accept Id 123 from 127.0.0.1:1812 to 0.0.0.0:0 length 20
```

**From another instance in same VPC:**

```bash
# Get RADIUS shared secret
SECRET=$(aws secretsmanager get-secret-value \
    --secret-id <secret-arn> \
    --region eu-west-2 \
    --query SecretString \
    --output text)

# Test against RADIUS server
radtest username "MyPassword123456" 10.200.1.xxx 1812 "$SECRET"
```

### Step 5: Test WorkSpace Login

1. Create AD user (must match RADIUS username)
2. Create WorkSpace for user
3. User logs in with:
   - Username: `username`
   - Password: `password` + `6-digit-token` (combined, no space)

Example:
- Password: `MySecurePass`
- Google Authenticator shows: `837264`
- User enters in WorkSpaces: `MySecurePass837264`

## User Onboarding Process

### For Each New User:

1. **Create user in Microsoft AD:**
   ```bash
   # Via AWS Console or API
   ```

2. **Setup MFA on RADIUS servers (on BOTH servers):**
   ```bash
   # On radius-1
   aws ssm start-session --target <instance-id-1>
   sudo /usr/local/bin/setup-mfa-user.sh john.doe

   # On radius-2
   aws ssm start-session --target <instance-id-2>
   sudo /usr/local/bin/setup-mfa-user.sh john.doe
   ```

3. **Retrieve QR code:**
   ```bash
   sudo cat /home/john.doe/.google_authenticator
   ```

4. **Send to user (via secure channel):**
   - QR code (for scanning with Google Authenticator app)
   - Emergency scratch codes
   - Initial password
   - Instructions document

5. **Define user in Terraform:**
   ```hcl
   # new-workspace-users.tf
   locals {
     workspace_users = {
       "john.doe" = {
         email         = "john.doe@justice.gov.uk"
         instance_type = "standard"
       }
     }
   }
   ```

6. **Deploy WorkSpace:**
   ```bash
   terraform apply
   ```

7. **Send registration code:**
   ```bash
   terraform output workspaces_ad_registration_code
   ```

## User Instructions

Send this to users:

---

**LAA WorkSpaces MFA Setup**

1. **Download Google Authenticator:**
   - iOS: https://apps.apple.com/app/google-authenticator/id388497605
   - Android: https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2

2. **Add your account:**
   - Open Google Authenticator
   - Tap "+" to add account
   - Scan the QR code provided
   - Save your emergency codes in a safe place

3. **Download WorkSpaces Client:**
   - https://clients.amazonworkspaces.com/

4. **Connect to WorkSpace:**
   - Open WorkSpaces client
   - Enter registration code: `<CODE>`
   - Username: `<your.username>`
   - Password: Your password + 6-digit code from Google Authenticator
     - Example: If password is `MyPass123` and token is `837264`, enter: `MyPass123837264`

5. **First Login:**
   - You'll be prompted to change your password
   - New password will also need token appended for future logins

6. **If You Lose Your Phone:**
   - Use one of your emergency scratch codes instead of the 6-digit token
   - Contact IT to reset your MFA

---

## Troubleshooting

### Authentication Always Fails

1. **Check user exists on both RADIUS servers:**
   ```bash
   # On each server
   id username
   cat /home/username/.google_authenticator
   ```

2. **Verify time sync:**
   ```bash
   # TOTP requires accurate time
   timedatectl status
   # Should show "System clock synchronized: yes"
   ```

3. **Check RADIUS logs:**
   ```bash
   # On RADIUS server
   sudo tail -f /var/log/radius/radius.log
   
   # In CloudWatch Logs
   # Log group: /aws/ec2/laa-workspaces-development/radius
   ```

4. **Test locally first:**
   ```bash
   radtest username 'password123456' localhost 1812 testing123
   ```

### User Not Found Errors

- User must exist on **both** RADIUS servers
- Username must match exactly (case-sensitive)
- Run setup script on both servers

### Token Always Invalid

- Check time synchronization on RADIUS servers
- Verify user is using correct secret (QR code)
- Try using emergency scratch code
- Check token isn't expired (30-second window)

### Microsoft AD Not Reaching RADIUS

1. **Check security group:**
   ```bash
   # Security group must allow UDP 1812 from VPC CIDR
   aws ec2 describe-security-groups --group-ids <sg-id>
   ```

2. **Verify RADIUS servers are running:**
   ```bash
   aws ssm start-session --target i-xxxxxxxxx
   sudo systemctl status radiusd
   ```

3. **Check Microsoft AD RADIUS settings:**
   ```bash
   aws ds describe-radius-settings --directory-id d-xxxxxxxxxx
   ```

### Emergency Access (MFA Bypass)

If RADIUS servers are down and users need immediate access:

```bash
# Temporarily disable RADIUS on Microsoft AD
aws ds disable-radius --directory-id d-xxxxxxxxxx

# Users can now login with just AD password (no MFA)

# Re-enable when RADIUS is fixed
# (This will reconfigure with existing settings)
```

## Monitoring

### CloudWatch Metrics

Monitor these metrics:
- **EC2/StatusCheckFailed** - RADIUS server health
- **EC2/CPUUtilization** - RADIUS server load
- Custom metrics in `LAA/WorkSpaces/RADIUS` namespace

### CloudWatch Logs

Log groups:
- `/aws/ec2/laa-workspaces-development/radius/*/freeradius` - RADIUS auth logs
- `/aws/ec2/laa-workspaces-development/radius/*/setup` - Installation logs

### Alarms

Alarms created:
- `laa-workspaces-development-radius-1-unhealthy`
- `laa-workspaces-development-radius-2-unhealthy`

## Maintenance

### Adding New Users

Run setup script on both RADIUS servers.

### Removing Users

```bash
# On both RADIUS servers
sudo userdel -r username
```

### Rotating RADIUS Shared Secret

```bash
# 1. Generate new secret in Secrets Manager
aws secretsmanager put-secret-value \
    --secret-id <secret-arn> \
    --secret-string "$(openssl rand -base64 32)"

# 2. Restart RADIUS servers (will pick up new secret on next auth)
# 3. Update Microsoft AD RADIUS settings
terraform apply
```

### Updating FreeRADIUS

```bash
# On each RADIUS server
sudo dnf update freeradius -y
sudo systemctl restart radiusd
```

## Security Best Practices

1. **User Management:**
   - Regular audits of enrolled users
   - Disable users when they leave
   - Enforce password changes every 90 days

2. **Emergency Codes:**
   - Store securely (password manager)
   - Regenerate after use
   - Limit to 5 codes per user

3. **RADIUS Servers:**
   - Keep updated with security patches
   - Monitor CloudWatch alarms
   - Regular backups of user configs

4. **Network Security:**
   - RADIUS servers in private subnets only
   - No direct internet access
   - VPC flow logs enabled

## Cost Estimate

**Monthly costs:**
- 2x t3.small EC2 instances: ~$30
- CloudWatch Logs (30-day retention): ~$5
- Secrets Manager: ~$0.40
- **Total: ~$35/month**

(Plus per-user WorkSpace costs)

## References

- [FreeRADIUS Documentation](https://freeradius.org/documentation/)
- [Google Authenticator PAM](https://github.com/google/google-authenticator-libpam)
- [AWS Directory Service RADIUS](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_mfa.html)
- [Installation Script](../workspace-components/scripts/install-freeradius.sh)

---

**Last Updated:** 30 April 2026  
**Solution:** FreeRADIUS with Google Authenticator TOTP
