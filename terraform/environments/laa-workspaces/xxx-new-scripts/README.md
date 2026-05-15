# User Creation Automation - EC2 + Lambda Method

## Overview

This automation creates AD users and WorkSpaces using the proven EC2+Lambda method that enables the WorkSpaces Console "Invite user" functionality to work properly.

## Architecture

```
User invokes Lambda (AWS CLI)
    ↓
Lambda Function (Python)
    ↓
    ├─> SSM Send Command → EC2 (PowerShell) → Create AD User with full details
    └─> AWS WorkSpaces API → Create WorkSpace
    ↓
WorkSpaces Console: "Invite user" button WORKS ✅
```

## Components

### 1. EC2 Instance (`xxx-new-ec2.tf`)
- **Instance Type:** t3.medium
- **OS:** Windows Server 2022
- **Domain:** Joined to laa-workspaces.local AD
- **Purpose:** Runs PowerShell scripts to create AD users using native AD cmdlets
- **Location:** Private subnet (no public IP)
- **Script:** `C:\Windows\system32\user-creation.ps1`

### 2. Lambda Function (`xxx-new-lambda.tf`)
- **Runtime:** Python 3.11
- **Timeout:** 15 minutes
- **Function:** Orchestrates user and WorkSpace creation
- **Triggers:** Manual invocation via AWS CLI

### 3. PowerShell Script (`xxx-new-scripts/user-creation.ps1`)
- Creates AD user with: SamAccountName, Email, GivenName, Surname
- Generates random 14-character password
- Stores password in SSM Parameter Store
- Uses service account: `LAAWORKSPACES\lambda.workspace`

### 4. IAM Roles (`xxx-new-iam.tf`)
- **EC2 Role:** SSM Managed Instance Core + Directory Service Access
- **Lambda Role:** SSM, WorkSpaces, Secrets Manager permissions

### 5. Security Groups (`xxx-new-security-groups.tf`)
- Allows RDP from VPC (for troubleshooting)
- Allows AD communication
- Egress to all

## Prerequisites

### What Terraform Does Automatically:

1. **Creates AD Service Account** (`lambda.workspace`)
   - Generated via `xxx-new-service-account.tf`
   - Password auto-generated (32 chars)
   - Stored in SSM Parameter Store: `/laa-workspaces/development/ad-service-account-password`
   - User created in `OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local`
   - **Automatically added to AWS Delegated Administrators group** ✅

### No Manual Steps Required! 🎉

Everything is fully automated via Terraform. Just run `terraform apply` and wait for completion.

## Deployment

### Step 1: Terraform Apply

```bash
cd terraform/environments/laa-workspaces
terraform init
terraform plan
terraform apply
```

This creates:
- Service account `lambda.workspace` in AD
- Password stored in SSM Parameter Store
- **Service account added to AWS Delegated Administrators group** ✅
- EC2 instance (auto-joins domain, installs AD tools, deploys PowerShell script)
- Lambda function
- IAM roles and policies
- Security groups

### Step 2: Verify Setup

1. **Wait for EC2 to fully boot and join domain** (~5-10 minutes)

2. **Verify domain join:**
   ```bash
   aws ssm start-session --target <instance-id> --region eu-west-2
   ```
   Then in PowerShell:
   ```powershell
   Get-ComputerInfo | Select-Object CsDomain
   # Should show: laa-workspaces.local
   ```

3. **Verify PowerShell script deployed:**
   ```powershell
   Test-Path C:\Windows\system32\user-creation.ps1
   # Should return: True
   
   Get-Content C:\Windows\system32\user-creation.ps1 | Select-Object -First 10
   # Should show the script content
   ```

4. **Verify AD tools installed:**
   ```powershell
   Get-WindowsFeature -Name RSAT-AD-PowerShell
   # Should show: Installed
   ```

## Usage

### Create a User and WorkSpace

Run from your local terminal:

```bash
aws lambda invoke \
  --function-name laa-workspaces-development-user-creation \
  --payload '{"Firstname":"John","Lastname":"Doe","Email":"john.doe@justice.gov.uk"}' \
  --region eu-west-2 \
  output.txt \
  --cli-binary-format raw-in-base64-out

cat output.txt
```

### What Happens:

1. Lambda validates input
2. Lambda sends PowerShell command to EC2 via SSM
3. EC2 runs `user-creation.ps1`:
   - Creates AD user: `John.Doe`
   - Generates 14-char password
   - Sets email, first name, last name in AD
   - Stores password in SSM: `/laa-workspaces/development/user-passwords/John.Doe`
4. Lambda creates WorkSpace for `John.Doe`
5. Lambda returns success message

### Send Invitation to User:

1. Go to AWS Console → WorkSpaces
2. Find the workspace for `John.Doe`
3. Click **"Invite user"** button ✅ (THIS WORKS!)
4. AWS sends email to `john.doe@justice.gov.uk` with:
   - Registration code
   - Temporary password (from AD)
   - WorkSpaces client download link

## Verification

### Check if "Invite user" works:

1. AWS Console → WorkSpaces → Select workspace
2. User details should show:
   - ✅ First name: John
   - ✅ Last name: Doe
   - ✅ Email: john.doe@justice.gov.uk
3. Click "Invite user" button → Should open email template

### Troubleshooting

**EC2 not domain-joined:**
```powershell
# Connect via SSM
aws ssm start-session --target <instance-id>

# Check domain status
Get-ComputerInfo | Select-Object CsDomain, CsDomainRole

# Manually join if needed
Add-Computer -DomainName laa-workspaces.local -Restart
```

**PowerShell script fails:**
```bash
# Check SSM command output
aws ssm list-command-invocations \
  --instance-id <instance-id> \
  --region eu-west-2 \
  --max-items 5

# Get specific command output
aws ssm get-command-invocation \
  --command-id <command-id> \
  --instance-id <instance-id> \
  --region eu-west-2
```

**Lambda timeout:**
- Increase timeout in `xxx-new-lambda.tf` (currently 900 seconds)
- Check CloudWatch Logs: `/aws/lambda/laa-workspaces-development-user-creation`

**User already exists:**
- Lambda skips AD user creation
- Still creates WorkSpace
- Check AD: `Get-ADUser -Identity "John.Doe"`

## Cost Estimate

- **EC2 t3.medium:** ~$35/month (on-demand, 24/7)
- **Lambda:** ~$0.01/invocation (mostly SSM wait time)
- **Total:** ~$35-40/month

## Clean Up

To remove the automation (keep existing users/workspaces):

```bash
cd terraform/environments/laa-workspaces
terraform destroy -target=aws_lambda_function.user_creation
terraform destroy -target=aws_instance.user_creation_ec2
terraform destroy -target=aws_security_group.user_creation_ec2_sg
terraform destroy -target=aws_iam_role.user_creation_lambda_role
terraform destroy -target=aws_iam_role.user_creation_ec2_role
```

## Comparison: ds-data vs EC2+PowerShell

| Feature | ds-data API | EC2+PowerShell |
|---------|-------------|----------------|
| AD user created | ✅ | ✅ |
| AD has email/name | ✅ | ✅ |
| WorkSpaces metadata | ❌ Empty | ✅ Populated |
| "Invite user" works | ❌ 400 error | ✅ Yes |
| Can edit user | ❌ No | ✅ Yes |
| Manual password reset | ✅ Required | ❌ Not needed |
| Infrastructure cost | $0 | ~$35/month |
| Complexity | Low | Medium |

## Recommendation

Use EC2+PowerShell method for production where "Invite user" functionality is required. The ~$35/month cost is justified by the improved user experience and elimination of manual password reset steps.
