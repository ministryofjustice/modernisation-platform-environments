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
- Choose one: Duo Security, Azure MFA, or FreeRADIUS
- Refer to [RADIUS-MFA-SETUP.md](RADIUS-MFA-SETUP.md) for detailed setup

---

## Deployment Process

### Phase 1: Network Infrastructure (workspace-components)

The network infrastructure is deployed **separately** via a dedicated GitHub Actions workflow.

**Location:** `terraform/environments/laa-workspaces/workspace-components/`

**What it creates:**
- VPC for WorkSpaces
- Private subnets across availability zones
- Security groups for WorkSpaces
- Security group rules (WSP, PCoIP, RDP)
- IAM roles and policies for WorkSpaces service
- KMS keys for EBS volume encryption
- VPC endpoints
- S3 buckets for logging/backups

**Deployment:**
1. Changes to files in `workspace-components/` folder trigger a separate GitHub Actions pipeline
2. Pipeline creates network infrastructure first
3. Outputs (VPC ID, subnet IDs) are consumed by main deployment

**GitHub Actions Workflow:** (TBD - add workflow name/path)

**Verification:**
```bash
cd terraform/environments/laa-workspaces/workspace-components
terraform init
terraform workspace select laa-workspaces-development
terraform output
```

Expected outputs:
- `vpc_id` - VPC ID for WorkSpaces
- `vpc_cidr_block` - VPC CIDR block
- `private_subnet_ids` - List of private subnet IDs
- `kms_ebs_key_arn` - KMS key ARN for EBS encryption
- `workspaces_iam_role_arn` - IAM role ARN for WorkSpaces
- `workspaces_iam_role_name` - IAM role name
- `workspaces_security_group_id` - Security group ID for WorkSpaces

---

**Location:** `terraform/environments/laa-workspaces/`

**What it creates:**
- AWS Managed Microsoft AD
- CloudWatch Log Groups for AD logs
- WorkSpaces directory registration with AD
- WorkSpaces IP access control group
- Secrets Manager secret for AD admin password
- Directory Service log subscription
- Individual WorkSpaces for users (when users are defined)

**What is NOT created (Phase 1 creates these):**
- IAM roles and policies ✅ (in workspace-components)
- KMS keys for encryption ✅ (in workspace-components)
- Security groups ✅ (in workspace-components)

**Deployment:**
1. Changes to main Terraform files trigger the primary GitHub Actions pipeline
2. Pipeline references outputs from workspace-components (Phase 1) via remote state
3. Microsoft AD directory is created automatically by Terraform
4. WorkSpaces directory is registered with the AD

**Verification:**
```bash
cd terraform/environments/laa-workspaces
terraform workspace select laa-workspaces-development
terraform plan
```

---

### Phase 3: RADIUS MFA Configuration

After Microsoft AD is deployed, configure RADIUS for multi-factor authentication.

**Solution:** FreeRADIUS with Google Authenticator (TOTP)

**Location:** `terraform/environments/laa-workspaces/workspace-components/new-adds-radius-server.tf`

**What it creates:**
- 2x EC2 instances (t3.small) running FreeRADIUS
- Security group for RADIUS traffic (UDP 1812/1813)
- IAM role with Secrets Manager access
- CloudWatch Logs and alarms
- RADIUS shared secret (stored in Secrets Manager)

**Deployment:**

The RADIUS infrastructure is already configured and will be deployed automatically with workspace-components (Phase 1).

```bash
cd terraform/environments/laa-workspaces/workspace-components
terraform apply
```

**Verification:**
```bash
terraform output radius_server_private_ips
# Should show 2 IP addresses
```

**Next Steps:**
1. SSH to RADIUS servers via SSM Session Manager
2. Configure users with Google Authenticator
3. Test RADIUS authentication
4. See [FREERADIUS-SETUP.md](FREERADIUS-SETUP.md) for detailed instructions

**Expected result:**
- 2 RADIUS servers deployed across AZs
- Shared secret created in Secrets Manager
- Microsoft AD automatically configured with RADIUS settings
- Ready for user MFA enrollment

---

### Phase 4: User Provisioning with MFA

After infrastructure and MFA are configured, provision users and WorkSpaces.

**Steps:**

1. **Create AD Users**
   
   Users must exist in Microsoft AD before creating WorkSpaces.
   
   Options:
   - **Option A:** Create users via AWS Console (Directory Service → Users)
   - **Option B:** Use PowerShell on domain-joined EC2 instance
   - **Option C:** Use AWS Directory Service API

2. **Setup MFA for Users (FreeRADIUS + Google Authenticator)**
   
   Each user needs MFA configured on the RADIUS servers.
   
   **On each RADIUS server:**
   ```bash
   # SSH via Session Manager
   aws ssm start-session --target <instance-id>
   
   # Create user and setup MFA
   sudo useradd -m username
   sudo passwd username
   sudo -u username google-authenticator
   
   # Answer prompts:
   # - Time-based tokens? y
   # - Update .google_authenticator? y
   # - Disallow multiple uses? y
   # - Increase window? n
   # - Rate limiting? y
   
   # Retrieve QR code for user
   sudo cat /home/username/.google_authenticator
   ```
   
   **IMPORTANT:** Run this on **both** RADIUS servers for each user!
   
   See [FREERADIUS-SETUP.md](FREERADIUS-SETUP.md) for detailed user setup instructions.

3. **Test MFA Authentication**
   
   ```bash
   # On RADIUS server, test authentication
   # Password + token must be combined (no space)
   radtest username 'MyPassword123456' localhost 1812 testing123
   # (where 123456 is the 6-digit token from Google Authenticator)
   ```

4. **Define Users in Terraform**
   
   Edit `new-workspace-users.tf`:
   
   ```hcl
   locals {
     workspace_users = {
       "john.doe" = {
         email         = "john.doe@justice.gov.uk"
         instance_type = "standard"
       }
       "jane.smith" = {
         email         = "jane.smith@justice.gov.uk"
         instance_type = "performance"
       }
     }
   }
   ```

5. **Deploy WorkSpaces**
   
   ```bash
   terraform apply
   ```

6. **Distribute to Users**
   
   ```bash
   # Get registration code
   terraform output workspaces_ad_registration_code
   ```
   
   Send to users:
   - Registration code
   - WorkSpaces client download link
   - AD username and initial password
   - Google Authenticator QR code
   - Emergency backup codes
   - Login instructions: password + 6-digit token (combined)

**User Login Process:**
- Username: `john.doe`
- Password in WorkSpaces: `<their-password><6-digit-token>`
- Example: If password is `SecurePass123` and token is `837264`, enter: `SecurePass123837264`

---

## Current Deployment Status (30 April 2026)

### ✅ Phase 1 Completed (workspace-components)
- [x] VPC and private subnets deployed
- [x] Security groups and rules created
- [x] IAM roles and policies deployed
- [x] KMS keys for encryption created
- [x] S3 buckets and VPC endpoints configured
- [x] **FreeRADIUS infrastructure configured (ready to deploy)**

### 📋 Phase 2 Pending
- [ ] Deploy Microsoft AD
- [ ] Register WorkSpaces directory with AD
- [ ] Configure CloudWatch logging

### 📋 Phase 3 Pending - RADIUS MFA (FreeRADIUS)
- [x] RADIUS server EC2 configuration (in workspace-components)
- [x] RADIUS shared secret generation
- [x] Security groups for RADIUS traffic
- [ ] Deploy RADIUS servers (terraform apply in workspace-components)
- [ ] Configure users with Google Authenticator
- [ ] Test MFA authentication flow

### 📋 Phase 4 Pending - User Provisioning
- [ ] Create AD users
- [ ] Setup MFA on RADIUS servers for each user
- [ ] Define users in Terraform (new-workspace-users.tf)
- [ ] Deploy individual WorkSpaces
- [ ] Distribute Google Authenticator QR codes to users
- [ ] Distribute WorkSpaces clients and registration codes

### 🔄 Future Phases
- [ ] Phase 5: Set up monitoring and alerting
- [ ] Phase 6: Configure backup and disaster recovery
- [ ] Phase 7: Implement cost optimization strategies

---

## Configuration Files

| File | Purpose | Location |
|------|---------|----------|
| `application_variables.json` | Environment-specific configuration | Main folder |
| `new-adds.tf` | AWS Managed Microsoft AD | Main folder |
| `new-adds-radius.tf` | RADIUS MFA configuration | Main folder |
| `new-adds-secret.tf` | AD admin password secret | Main folder |
| `new-workspaces.tf` | WorkSpaces directory and workspace definitions | Main folder |
| `new-workspace-users.tf` | User definitions for workspace provisioning | Main folder |
| `new-workspace-type.tf` | WorkSpace bundle/instance type definitions | Main folder |
| `new-kms.tf` | KMS keys for encryption | Main folder |
| `new-workspaces-iam.tf` | IAM roles for WorkSpaces service | Main folder |
| `new-workspace-sg.tf` | Security groups and rules | Main folder |

### Important Configuration Values

**application_variables.json:**
```json
{
  "accounts": {
    "development": {
      "workspace_bundle_id": "wsb-0q8gwp742",
      "ad_directory_name": "laa-workspaces.local",
      "ad_short_name": "LAAWORKSPACES",
      "ad_edition": "Standard"
    }
  }
}
```

---

## Additional Resources

- **[FREERADIUS-SETUP.md](FREERADIUS-SETUP.md)** - Complete FreeRADIUS + Google Authenticator setup guide
- **[RADIUS-MFA-SETUP.md](RADIUS-MFA-SETUP.md)** - General RADIUS MFA overview and alternatives
- [AWS WorkSpaces Documentation](https://docs.aws.amazon.com/workspaces/)
- [AWS Managed Microsoft AD](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/directory_microsoft_ad.html)
- [RADIUS MFA with AWS Directory Service](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_mfa.html)
- [FreeRADIUS Documentation](https://freeradius.org/documentation/)
- [Google Authenticator PAM](https://github.com/google/google-authenticator-libpam)

---

**Document End**
| `application_variables.json` | Environment-specific configuration | Main folder |
| `new-workspaces-identity-center.tf` | WorkSpaces directory and workspace definitions | Main folder |
| `new-workspace-users.tf` | User definitions for workspace provisioning | Main folder |
| `new-workspace-type.tf` | WorkSpace bundle/instance type definitions | Main folder |
| `new-kms.tf` | KMS keys for encryption | workspace-components |
| `new-workspaces-iam.tf` | IAM roles for WorkSpaces service | workspace-components |
| `new-workspace-sg.tf` | Security groups and rules | workspace-componentstions for workspace provisioning |
| `new-workspace-type.tf` | WorkSpace bundle/instance type definitions |
| `new-kms.tf` | KMS keys for encryption |

### Important Configuration Values

From `application_variables.json`:
```json
{
  "development": {
    "identity_center_instance_arn": "arn:aws:sso:::instance/ssoins-7535d9af4f41fb26",
    "workspace_bundle_id": "wsb-0q8gwp742",
    "workspaces_directory_id": "d-9c674d0524"
  }
}
```

---

## Adding Users and WorkSpaces

### Define Users

Edit: `new-workspace-users.tf`

```hcl
locals {
  workspace_users = {
    "user1@example.com" = {
      first_name    = "John"
      last_name     = "Smith"
      email         = "john.smith@justice.gov.uk"
      instance_type = "standard"
    }
    "user2@example.com" = {
      first_name    = "Jane"
      last_name     = "Doe"
      email         = "jane.doe@justice.gov.uk"
      instance_type = "performance"
    }
  }
}
```

### Workspace Types

Defined in `new-workspace-type.tf`:
- **standard**: Basic performance, cost-effective
- **performance**: Higher specifications for demanding workloads

### Deploy WorkSpaces

```bash
# Review changes
terraform plan

# Deploy
terraform apply
```

---

## Troubleshooting

### Issue: BYOL Not Enabled

**Error:** "Your AWS account is not enabled for Bring Your Own License (BYOL)"

**Solution:**
1. Open AWS Support case requesting BYOL enablement
2. Specify account ID and region (eu-west-2)
3. Mention it's for Identity Center integration
4. Usually approved within 24-48 hours

### Issue: Directory Creation Fails

**Symptoms:** Error creating directory in console

**Checks:**
- Verify subnets are in private subnet tier
- Ensure Identity Center is enabled in the account
- Confirm IAM permissions for WorkSpaces service
- Check VPC endpoints are configured

### Issue: Import Fails

**Error:** "Resource not found"

**Solution:**
- Verify directory ID is correct
- Ensure you're in the correct region (eu-west-2)
- Check Terraform workspace matches environment
- Confirm AWS credentials have read access

---

## Next Steps

1. **Update this document** with detailed user provisioning steps
2. **Document Azure AD integration** (if implementing SAML SSO)
3. **Add monitoring configuration** (CloudWatch dashboards, alarms)
4. **Create user onboarding guide** for end users
5. **Document backup and disaster recovery** procedures
6. **Add cost optimization** recommendations
7. **Security hardening** checklist

---

## References

- [AWS WorkSpaces Documentation](https://docs.aws.amazon.com/workspaces/)
- [IAM Identity Center Documentation](https://docs.aws.amazon.com/singlesignon/)
- [Modernisation Platform Standards](https://user-guide.modernisation-platform.service.justice.gov.uk/)

---

**Document Owner:** LAA DevOps Team  
**Last Reviewed:** 27 April 2026  
**Next Review:** TBD

---

**End of Document**
