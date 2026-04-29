# LAA WorkSpaces with IAM Identity Center - Deployment Guide

**Document Version:** 1.0  
**Last Updated:** 27 April 2026  
**Environment:** AWS Modernisation Platform  
**Status:** Initial deployment completed - to be expanded

---

## Overview

This guide documents the deployment process for AWS WorkSpaces integrated with IAM Identity Center for Single Sign-On (SSO) and Multi-Factor Authentication (MFA).

### Architecture

```
IAM Identity Center (existing instance)
    ↓
AWS WorkSpaces Directory (Identity Center-backed)
    ↓
Individual WorkSpaces (per user)
```

---

## Prerequisites

### AWS Account Requirements
- ✅ IAM Identity Center enabled
- ✅ Identity Center instance ARN: `arn:aws:sso:::instance/ssoins-7535d9af4f41fb26`
- ✅ BYOL (Bring Your Own License) enabled for WorkSpaces
- ✅ Appropriate IAM permissions for Terraform deployment

### Repository Access
- ✅ Access to `modernisation-platform-environments` repository
- ✅ GitHub Actions permissions for deployment workflows

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

### Phase 2: Main Infrastructure Deployment

After network components are deployed, the main infrastructure is created via the primary GitHub Actions workflow.
WorkSpaces directory registration (imported from manual creation)
- WorkSpaces IP access control group (imported from manual creation)
- Individual WorkSpaces for users (when users are defined)

**What is NOT created (Phase 1 creates these):**
- IAM roles and policies ✅ (in workspace-components)
- KMS keys for encryption ✅ (in workspace-components)
- Security groups ✅ (in workspace-components)

**Deployment:**
1. Changes to main Terraform files trigger the primary GitHub Actions pipeline
2. Pipeline references outputs from workspace-components (Phase 1) via remote state
3. At this stage, **WorkSpaces directory is NOT created** (manual step required in Phase 3
**Deployment:**
1. Changes to main Terraform files trigger the primary GitHub Actions pipeline
2. Pipeline runs `terraform apply` for all resources
3. At this stage, **WorkSpaces directory is NOT created** (manual step required)

**GitHub Actions Workflow:** (TBD - add workflow name/path)

---

### Phase 3: Manual WorkSpaces Directory Creation

⚠️ **IMPORTANT:** The WorkSpaces directory with Identity Center **cannot be created via Terraform or CloudFormation**. This is a limitation of current AWS APIs.

**Steps:**

1. **Navigate to AWS WorkSpaces Console**
   - Login to AWS Console
   - Region: `eu-west-2` (London)
   - Go to WorkSpaces service

2. **Create Directory**
   - Click "Directories" in left navigation
   - Click "Set up Directory"
   - Select **"AWS IAM Identity Center"** as directory type
   - Configure:
     - **Identity Center instance:** Select the existing instance
     - **Subnets:** Select private subnets from Phase 1 (from VPC created by workspace-components)
     - **IP Access Control:** Create new or select existing
   - Complete the setup wizard

3. **Enable BYOL (if prompted)**
   - If you get error: "Your AWS account is not enabled for Bring Your Own License (BYOL)"
   - Contact AWS Support to enable BYOL for your account
   - This is required for Identity Center integration
   - BYOL enablement is free and doesn't force you to bring licenses

4. **Note the Directory ID**
   - After creation, note the directory ID (format: `d-xxxxxxxxxx`)
   - Example: `d-9c674d0524`

5. **Note the IP Group ID**
   - WorkSpaces automatically creates an IP group
   - Note the IP group ID (format: `wsipg-xxxxxxxx`)
   - Example: `wsipg-67x66y79w`

**Expected result:**
- WorkSpaces directory created and in "Active" state
- Directory backed by IAM Identity Center
- Ready for WorkSpaces provisioning

---

### Phase 4: Import Directory into Terraform

After manual creation, we need to bring the directory under Terraform management.

**Steps:**

1. **Create Terraform Resource File**
   
   File: `new-workspaces-identity-center.tf`
   
   This file should contain:
   - `aws_workspaces_directory` resource with the directory ID
   - `aws_workspaces_ip_group` resource
   - `aws_workspaces_workspace` resources for individual WorkSpaces
   
   ✅ **Status:** File created

2. **Import the WorkSpaces Directory**
   
   ```bash
   cd terraform/environments/laa-workspaces
   terraform workspace select laa-workspaces-development
   
   # Import directory (replace with actual directory ID)
   terraform import 'aws_workspaces_directory.workspaces_identity_center[0]' d-9c674d0524
   ```

3. **Import the IP Group**
   
   ```bash
   # Import IP group (replace with actual IP group ID)
   terraform import 'aws_workspaces_ip_group.workspaces_identity_center[0]' wsipg-67x66y79w
   ```

4. **Verify Import**
   
   ```bash
   # Check imported resources
   terraform state list | grep workspaces_identity_center
   
   # Verify configuration matches
   terraform plan
   ```
   
   Expected plan output:
   - Tag updates (adding standard MP tags)
   - Minimal or no other changes

5. **Apply Tag Updates**
   
   ```bash
   terraform apply
   ```

**Verification:**
```bash
# Confirm resources are in state
terraform state show 'aws_workspaces_directory.workspaces_identity_center[0]'
terraform state show 'aws_workspaces_ip_group.workspaces_identity_center[0]'
```

---

## Current Deployment Status (29 April 2026)

### ✅ Phase 1 Completed (workspace-components)
- [x] VPC and private subnets deployed
- [x] Security groups and rules created
- [x] IAM roles and policies deployed
- [x] KMS keys for encryption created
- [x] S3 buckets and VPC endpoints configured

### 🔄 Phase 2 In Progress
- [ ] Deploy main infrastructure (after Phase 1)
- [ ] WorkSpaces directory needs manual creation (Phase 3)

### 📋 Phase 3 Pending
- [ ] Manually create WorkSpaces directory with Identity Center
- [ ] Note directory ID and IP group ID for import

### 📋 Phase 4 Pending
- [ ] Import directory into Terraform
- [ ] Import IP group into Terraform

### 🔄 Future Phases
- [ ] Phase 5: Configure Identity Center users/groups
- [ ] Phase 6: Create individual WorkSpaces for users
- [ ] Phase 7: Configure Azure AD SAML integration (if required)
- [ ] Phase 8: Set up monitoring and alerting
- [ ] Phase 9: Document user onboarding process

---

## Configuration Files

### Key Files Location |
|------|---------|----------|
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
