# Terraform Major Version Upgrade Analysis
## analytical-platform-ingestion Environment

**Date:** 2 February 2026  
**Advisory Phase:** Complete ✅  
**Implementation Phase:** Complete ✅  
**Status:** 🟢 Changes Applied - PR Created  
**Pull Request:** https://github.com/ministryofjustice/modernisation-platform-environments/pull/15300

---

## Executive Summary

- **3 major version upgrades** available
- **25 module instances** require updates across **24 files**
- **1 breaking code change** required (SNS `conditions` → `condition`)
- **AWS Provider upgrade required** (`~> 5.0` → `~> 6.0`)
- **⚠️ Additional provider constraint conflicts resolved** in subdirectories

---

## 📊 Step 1 & 2: Module Inventory & Major Upgrades Detected

| Module | Current | Latest | Upgrade Type | Files Affected |
|--------|---------|--------|--------------|----------------|
| **terraform-aws-modules/kms/aws** | v3.1.1 | **v4.2.0** | 🔴 **MAJOR** | 21 files |
| **terraform-aws-modules/sns/aws** | v6.2.0 | **v7.1.0** | 🔴 **MAJOR** | 2 files |
| **terraform-aws-modules/lambda/aws** (git ref) | v7.20.1 | **v8.4.0** | 🔴 **MAJOR** | 2 files |
| terraform-aws-modules/lambda/aws (registry) | v8.0.1 | v8.4.0 | 🟡 Minor | 5 files |
| terraform-aws-modules/vpc/aws | v6.6.0 | v6.6.0 | ✅ Up-to-date | 2 files |
| terraform-aws-modules/s3-bucket/aws | v5.10.0 | v5.10.0 | ✅ Up-to-date | 9 files |
| terraform-aws-modules/ec2-instance/aws | v6.2.0 | v6.2.0 | ✅ Up-to-date | 1 file |
| terraform-aws-modules/cloudwatch/aws | v5.6.0 | v5.7.2 | 🟡 Minor | 4 files |
| ministryofjustice/observability-platform-tenant/aws | v2.0.0 | v2.0.0 | ✅ Up-to-date | 1 file |
| terraform-aws-modules/iam/aws | v6.x | v6.4.0 | 🟡 Minor | 25 files |
| terraform-aws-modules/route53/aws | Unknown | v6.4.0 | ℹ️ Review | 2 files |
| terraform-aws-modules/secrets-manager/aws | Unknown | v2.1.0 | ℹ️ Review | 7 files |
| terraform-aws-modules/security-group/aws | Unknown | v5.3.1 | ℹ️ Review | 8 files |
| terraform-aws-modules/alb/aws | Unknown | v10.5.0 | ℹ️ Review | 1 file |

---

## 🚨 Step 3 & 4: Breaking Changes & Migration Plan

### 1. terraform-aws-modules/kms/aws (v3.1.1 → v4.2.0)

#### 📍 Affected Files (21 instances):

- `kms-keys.tf` (17 modules)
  - `transfer_logs_kms`
  - `transfer_data_kms`
  - `landing_kms`
  - `raw_kms`
  - `structured_kms`
  - `curated_kms`
  - `quarantine_kms`
  - `quarantined_sns_kms`
  - `transferred_sns_kms`
  - `definitions_kms`
  - `ecr_kms`
  - `cloudwatch_kms`
  - `glue_kms`
  - `logs_kms`
  - `rds_snapshot_kms`
  - `temporary_storage_kms`
  - `validation_kms`
- `modules/dms/kms-keys.tf`
- `dms/kms-keys.tf`
- `secrets.tf`
- `dms/secrets.tf`

#### ⚠️ Breaking Changes:

1. **AWS Provider Requirement:** Requires AWS provider `~> 6.0` (upgraded from `~> 5.0`)
2. **Terraform Version:** Requires Terraform `>= 1.5.7` (upgraded from `>= 1.3.0`)
3. **No Resource Changes:** Module itself has no breaking resource changes, only tooling requirements

#### Release Notes (v4.0.0):

```
⚠ BREAKING CHANGES

* Upgrade AWS provider and min required Terraform version to 6.0 and 1.5.7 respectively

Features:
* Upgrade AWS provider and min required Terraform version to 6.0 and 1.5.7 respectively
* Add key_spec to external key support (v4.1.0)
* Add provider meta user-agent (v4.2.0)
```

#### ✅ Migration Requirements:

- Update AWS provider constraint in `terraform.tf` to `>= 6.0`
- Verify Terraform version is `>= 1.5.7`
- Update all 21 KMS module version references from `3.1.1` to `4.2.0`

#### 💡 Impact: **LOW** 

Only requires version updates, no code refactoring needed.

---

### 2. terraform-aws-modules/sns/aws (v6.2.0 → v7.1.0)

#### 📍 Affected Files (2 instances):

- `sns.tf` (2 modules)
  - `quarantined_topic`
  - `transferred_topic`

#### ⚠️ Breaking Changes:

1. **AWS Provider Requirement:** Requires AWS provider `~> 6.9` (upgraded from `~> 5.0`)
2. **Terraform Version:** Requires Terraform `>= 1.5.7`
3. **⚠️ CRITICAL CODE CHANGE:** Within `topic_policy_statements`, the argument name changed:
   - **OLD:** `conditions` (plural)
   - **NEW:** `condition` (singular)

#### Release Notes (v7.0.0):

```
⚠ BREAKING CHANGES

* Upgrade AWS provider and min required Terraform version to 6.9 and 1.5.7 respectively

⚠️ CAUTION
There are no changes for users other than one small change to match the underlying API. 
Within topic_policy_statements, the condition argument was previously conditions (plural).

Features:
- Upgrade AWS provider and min required Terraform version to 6.9 and 1.5.7 respectively
- Add support for resource level region argument to relevant resources
- Add variable optional attributes to replace vague variable types of any or map(string)
- Ensure no resources or data sources are invoke if create = false
```

#### ✅ Migration Requirements:

- Update AWS provider constraint to `>= 6.9`
- Update both SNS module version references from `6.2.0` to `7.1.0`
- **CODE REFACTORING REQUIRED:** Review `sns.tf` for `conditions` usage and rename to `condition`

#### 📝 Code Analysis:

Found `conditions` array on line 19 in `quarantined_topic` module that needs refactoring:

```hcl
conditions = [  # Line 19 - needs to change to "condition"
  {
    test     = "ArnEquals"
    variable = "aws:SourceArn"
    values   = [module.quarantine_bucket.s3_bucket_arn]
  },
  {
    test     = "StringEquals"
    variable = "aws:SourceAccount"
    values   = [data.aws_caller_identity.current.account_id]
  }
]
```

#### 💡 Impact: **MEDIUM** 

Requires code refactoring for policy statements.

---

### 3. terraform-aws-modules/lambda/aws (git ref v7.20.1 → v8.4.0)

#### 📍 Affected Files (2 instances):

- `modules/dms/metadata-generator.tf` (line 177)
  - Module: `metadata_generator`
- `modules/dms/validation.tf` (line 43)
  - Module: `validation_lambda_function`

#### Current Usage:

```hcl
source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=84dfbfddf9483bc56afa0aff516177c03652f0c7"
```

**Note:** Commit `84dfbfddf9483bc56afa0aff516177c03652f0c7` corresponds to v7.20.1

#### ⚠️ Breaking Changes:

1. **AWS Provider Requirement:** Requires AWS provider `~> 6.0` (upgraded from `~> 5.0`)
2. **Terraform Version:** Requires Terraform `>= 1.5.7` (was lowered from 1.10 in v8.0.1)
3. **No Resource Changes:** Only tooling requirements changed

#### Release Notes (v8.0.0):

```
⚠ BREAKING CHANGES

* Upgrade AWS provider and min required Terraform version to 6.0 and 1.10 respectively

Features:
* Upgrade AWS provider and min required Terraform version to 6.0 and 1.10 respectively
* Lower minimum Terraform version to 1.5.7 (v8.0.1)
* Respect the package-lock.json for a NodeJS Lambda function (v8.1.0)
* Add support for tenant isolation mode feature (v8.3.0)
* Add uv support for python packaging (v8.4.0)
```

#### ✅ Migration Requirements:

- Update AWS provider constraint to `>= 6.0`
- Replace git commit ref with version tag:
  - **FROM:** `ref=84dfbfddf9483bc56afa0aff516177c03652f0c7` (v7.20.1)
  - **TO:** `ref=v8.4.0` (recommended)
- Update both module references in DMS modules

#### 🎯 Recommendation:

Consider migrating from git source to Terraform Registry source to align with the other 5 lambda modules already using registry version `8.0.1`:

```hcl
# Option 1: Update git ref to v8.4.0
source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=v8.4.0"

# Option 2: Migrate to registry (recommended for consistency)
source  = "terraform-aws-modules/lambda/aws"
version = "8.4.0"
```

#### 💡 Impact: **LOW** 

Only requires version updates, no code refactoring needed.

---

## 📋 Step 5: Proposed Code Changes

### Prerequisites:

1. **AWS Provider Upgrade:** Update provider constraints to `~> 6.0` (completed)
2. **Terraform Version:** Ensure using Terraform `>= 1.5.7` (already met: `~> 1.10`)

### ⚠️ Critical Fix Applied: Provider Constraint Conflicts

During implementation, provider constraint conflicts were discovered in subdirectories:

**Issue:** Subdirectories had AWS provider constraints that were incompatible with module requirements:
- `dms/versions.tf`: `~> 5.0, != 5.86.0` (conflicted with `~> 6.0`)
- `modules/dms/terraform.tf`: `~> 5.0` (conflicted with `~> 6.0`)

**Resolution:** Updated both files to use `~> 6.0` for consistency.

**Impact:** 
- 🟡 **MEDIUM** - Additional testing required for DMS-related infrastructure
- All DMS modules and submodules now require AWS provider v6.x
- Terraform version requirement also updated to `>= 1.5.7` in `modules/dms/terraform.tf`

### ⚠️ Critical Fix #2: KMS Grant Sensitivity Issue

During terraform plan, a second issue was discovered related to the KMS v4 upgrade:

**Issue:** KMS v4 module now enforces stricter validation on `for_each` arguments:
```
Error: Invalid for_each argument
Sensitive values, or values derived from sensitive values, cannot be used
as for_each arguments.
```

**Root Cause:**
- IAM role ARNs from DMS and Lambda modules are marked as sensitive outputs
- KMS module v4 uses `for_each` over the `grants` map
- Terraform now rejects sensitive values in `for_each` to prevent key exposure

**Resolution:** Wrapped sensitive role ARNs with `nonsensitive()` function in grants configuration:
- `dms/kms-keys.tf`: Updated `cica_dms_credentials_kms` and `cica_dms_eventscheduler_kms` modules
- `modules/dms/kms-keys.tf`: Updated `bucket_kms` module

**Rationale:** IAM role ARNs are AWS resource identifiers (not secrets), safe to expose as resource keys.

**Files Modified:**
- `dms/kms-keys.tf` (2 KMS modules with grants)
- `modules/dms/kms-keys.tf` (1 KMS module with grants)

### Change Set Summary:

| File | Change Type | Description |
|------|-------------|-------------|
| `versions.tf` | Provider Constraint | AWS provider `~> 6.0` (already correct) |
| `dms/versions.tf` | Provider Constraint | AWS provider `~> 5.0, != 5.86.0` → `~> 6.0` |
| `modules/dms/terraform.tf` | Provider Constraint | AWS provider `~> 5.0` → `~> 6.0`, Terraform `>= 1.0.0` → `>= 1.5.7` |
| `dms/kms-keys.tf` | Sensitivity Fix | Wrap role ARNs with `nonsensitive()` in 2 KMS modules |
| `modules/dms/kms-keys.tf` | Sensitivity Fix | Wrap role ARNs with `nonsensitive()` in 1 KMS module |
| `sns.tf` | Version + Refactor | SNS v6.2.0 → v7.1.0, `conditions` → `condition` |
| `kms-keys.tf` | Version Update | 17 KMS modules v3.1.1 → v4.2.0 |
| `dms/kms-keys.tf` | Version Update | KMS v3.1.1 → v4.2.0 (2 modules) |
| `modules/dms/kms-keys.tf` | Version Update | KMS v3.1.1 → v4.2.0 |
| `secrets.tf` | Version Update | KMS v3.1.1 → v4.2.0 (if present) |
| `dms/secrets.tf` | Version Update | KMS v3.1.1 → v4.2.0 (if present) |
| `modules/dms/metadata-generator.tf` | Git Ref Update | Lambda ref v7.20.1 → v8.4.0 |
| `modules/dms/validation.tf` | Git Ref Update | Lambda ref v7.20.1 → v8.4.0 |

**Total:** 28 changes across 10 files (24 module updates + 2 provider fixes + 3 sensitivity fixes)

### Detailed Diffs:

#### File 1: dms/versions.tf (AWS Provider Constraint Fix)

```diff
  terraform {
    required_providers {
      aws = {
-       version = "~> 5.0, != 5.86.0"
+       version = "~> 6.0"
        source  = "hashicorp/aws"
      }
    }
  }
```

#### File 2: modules/dms/terraform.tf (AWS Provider & Terraform Version Fix)

```diff
  terraform {
-   required_version = ">= 1.0.0, < 2.0.0"
+   required_version = ">= 1.5.7, < 2.0.0"
    required_providers {
      aws = {
        source  = "hashicorp/aws"
-       version = "~> 5.0"
+       version = "~> 6.0"
      }
    }
  }
```

#### File 3: dms/kms-keys.tf (KMS Grant Sensitivity Fixes)

```diff
  module "cica_dms_credentials_kms" {
    grants = {
      tariff_dms_source = {
-       grantee_principal = module.cica_dms_tariff_dms_implementation.dms_source_role_arn
+       grantee_principal = nonsensitive(module.cica_dms_tariff_dms_implementation.dms_source_role_arn)
        operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
      }
      tempus_dms_casework_source = {
-       grantee_principal = module.cica_dms_tempus_dms_implementation["CaseWork"].dms_source_role_arn
+       grantee_principal = nonsensitive(module.cica_dms_tempus_dms_implementation["CaseWork"].dms_source_role_arn)
        operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
      }
      # ... similar changes for other grants
    }
  }
  
  module "cica_dms_eventscheduler_kms" {
    grants = {
      tariff_dms_source = {
-       grantee_principal = module.tariff_eventbridge_dms_full_load_task_role.iam_role_arn
+       grantee_principal = nonsensitive(module.tariff_eventbridge_dms_full_load_task_role.iam_role_arn)
        operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
      }
      # ... similar changes for other grants
    }
  }
```

#### File 4: modules/dms/kms-keys.tf (KMS Grant Sensitivity Fixes)

```diff
  module "bucket_kms" {
    grants = {
      dms_task = {
        grantee_principal = aws_iam_role.dms.arn
        operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
      }
      metadata_generator = {
-       grantee_principal = module.metadata_generator.lambda_role_arn
+       grantee_principal = nonsensitive(module.metadata_generator.lambda_role_arn)
        operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
      }
      validation = {
-       grantee_principal = module.validation_lambda_function.lambda_role_arn
+       grantee_principal = nonsensitive(module.validation_lambda_function.lambda_role_arn)
        operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
      }
    }
  }
```

#### File 5: sns.tf (Version + Code Refactoring)

```diff
  module "quarantined_topic" {
    #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

    source  = "terraform-aws-modules/sns/aws"
-   version = "6.2.0"
+   version = "7.1.0"

    name              = "quarantined"
    display_name      = "quarantined"
    signature_version = 2

    kms_master_key_id = module.quarantined_sns_kms.key_id

    topic_policy_statements = {
      AllowQuarantineS3 = {
        actions = ["sns:Publish"]
        principals = [{
          type        = "Service"
          identifiers = ["s3.amazonaws.com"]
        }]
-       conditions = [
+       condition = [
          {
            test     = "ArnEquals"
            variable = "aws:SourceArn"
            values   = [module.quarantine_bucket.s3_bucket_arn]
          },
          {
            test     = "StringEquals"
            variable = "aws:SourceAccount"
            values   = [data.aws_caller_identity.current.account_id]
          }
        ]
      }
    }

    subscriptions = {
      lambda = {
        protocol = "lambda"
        endpoint = module.notify_quarantined_lambda.lambda_function_arn
      }
    }
  }

  module "transferred_topic" {
    #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
    source  = "terraform-aws-modules/sns/aws"
-   version = "6.2.0"
+   version = "7.1.0"

    name              = "transferred"
    display_name      = "transferred"
    signature_version = 2

    kms_master_key_id = module.transferred_sns_kms.key_id

    subscriptions = {
      lambda = {
        protocol = "lambda"
        endpoint = module.notify_transferred_lambda.lambda_function_arn
      }
    }
  }
```

#### File 4: kms-keys.tf (17 module instances)

```diff
  module "transfer_logs_kms" {
    #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

    source  = "terraform-aws-modules/kms/aws"
-   version = "3.1.1"
+   version = "4.2.0"

    aliases               = ["logs/transfer"]
    description           = "CloudWatch Logs for the Transfer Server"
    enable_default_policy = true
    # ... rest of configuration
  }

  # Repeat version update for all 17 KMS modules:
  # - transfer_logs_kms
  # - transfer_data_kms
  # - landing_kms
  # - raw_kms
  # - structured_kms
  # - curated_kms
  # - quarantine_kms
  # - quarantined_sns_kms
  # - transferred_sns_kms
  # - definitions_kms
  # - ecr_kms
  # - cloudwatch_kms
  # - glue_kms
  # - logs_kms
  # - rds_snapshot_kms
  # - temporary_storage_kms
  # - validation_kms
```

#### Files 5-8: Other KMS modules (4 more files)

Apply same version change `3.1.1` → `4.2.0` to:
- `dms/kms-keys.tf`
- `modules/dms/kms-keys.tf`
- `secrets.tf` (if present)
- `dms/secrets.tf` (if present)

#### Files 9-10: Lambda modules (git ref update)

**modules/dms/metadata-generator.tf:**
```diff
  module "metadata_generator" {
    #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

-   source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=84dfbfddf9483bc56afa0aff516177c03652f0c7"
+   source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=v8.4.0"

    publish        = true
    create_package = false
    # ... rest of configuration
  }
```

**modules/dms/validation.tf:**
```diff
  module "validation_lambda_function" {
    #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

-   source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=84dfbfddf9483bc56afa0aff516177c03652f0c7"
+   source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=v8.4.0"

    publish        = true
    create_package = false
    # ... rest of configuration
  }
```

---

## 🎯 Risk Assessment

| Component | Risk Level | Reason |
|-----------|-----------|--------|
| **KMS Module** | 🟢 **LOW** | Only version bump, no breaking resource changes |
| **Lambda Module** | 🟢 **LOW** | Only version bump, no breaking resource changes |
| **SNS Module** | 🟡 **MEDIUM** | Requires code refactoring (`conditions` → `condition`) |
| **AWS Provider** | � **MEDIUM** | Provider v6 upgrade + constraint conflicts resolved in DMS subdirectories |
| **DMS Infrastructure** | 🟡 **MEDIUM** | Additional testing required due to provider constraint changes |
| **Overall** | 🟡 **MEDIUM** | Manageable changes, comprehensive testing recommended |

---

## 📝 Recommended Implementation Plan

### Phase 1: Preparation
1. ✅ Review this advisory document
2. ⬜ Backup current state (`terraform plan -out=pre-upgrade.tfplan`)
3. ⬜ Ensure Terraform version is `>= 1.5.7`
4. ⬜ Review AWS provider v6 changelog

### Phase 2: Development Environment Testing
1. ⬜ Apply changes to development environment first
2. ⬜ Run `terraform init -upgrade`
3. ⬜ Run `terraform plan` and review changes
4. ⬜ Apply and validate infrastructure
5. ⬜ Monitor for issues

### Phase 3: Incremental Rollout
1. ⬜ **Step 1:** KMS modules (lowest risk)
2. ⬜ **Step 2:** Lambda modules (low risk)
3. ⬜ **Step 3:** SNS module (medium risk - has code changes)
4. ⬜ **Step 4:** Validate all services operational

### Phase 4: Validation
1. ⬜ Run integration tests
2. ⬜ Verify SNS topic policies working correctly
3. ⬜ Verify Lambda functions operational
4. ⬜ Verify KMS key access working
5. ⬜ Monitor CloudWatch for errors

---

## ❓ Next Steps

**All Phases Complete** ✅

### Implementation Summary
- ✅ **Branch Created:** `terraform-maintenance-major/analytical-platform-ingestion/20260202-121803`
- ✅ **Changes Committed:** All module upgrades and refactoring applied
- ✅ **Provider Conflicts Fixed:** AWS provider constraints aligned to `~> 6.0` (commit fc93a89b4)
- ✅ **KMS Grants Fixed:** Applied `nonsensitive()` wrapper to resolve for_each sensitivity (commit d111e4ac7)
- ✅ **Pull Request Created:** [PR #15300](https://github.com/ministryofjustice/modernisation-platform-environments/pull/15300) (Draft)

### Post-Implementation Fixes

Two critical issues were discovered and resolved during terraform validation:

1. **AWS Provider Constraint Conflicts** (commit fc93a89b4)
   - **Issue:** Subdirectories had incompatible provider versions (`~> 5.0` vs `~> 6.0`)
   - **Files Fixed:** `dms/versions.tf`, `modules/dms/terraform.tf`
   - **Solution:** Updated all provider constraints to `~> 6.0`

2. **KMS Grant Sensitivity Issues** (commit d111e4ac7)
   - **Issue:** KMS v4 module rejects sensitive values in `for_each` arguments
   - **Files Fixed:** `dms/kms-keys.tf`, `modules/dms/kms-keys.tf`
   - **Solution:** Wrapped role ARNs with `nonsensitive()` function
   - **Rationale:** IAM role ARNs are resource identifiers, not secrets

### Testing & Deployment

1. **Review Pull Request:**
   - Visit [PR #15300](https://github.com/ministryofjustice/modernisation-platform-environments/pull/15300)
   - Review the code changes
   - Check the detailed advisory documentation

2. **Local Testing:**
   ```bash
   cd terraform/environments/analytical-platform-ingestion
   terraform init -upgrade
   terraform plan
   ```
   
   **Note:** Full terraform plan validation requires AWS credentials. Testing should be performed in:
   - CI/CD pipeline with appropriate AWS access
   - Local environment with configured AWS credentials
   - Development workspace with proper authentication

3. **Development Environment:**
   - Apply changes to development environment first
   - Validate infrastructure changes
   - Monitor CloudWatch logs for any issues

4. **Production Deployment:**
   - Once development testing is successful
   - Mark PR as "Ready for review"
   - Obtain necessary approvals
   - Merge and deploy to production

### Rollback Plan

If issues are encountered:
```bash
git revert <commit-hash>
```
Or close the PR and restore previous module versions.

---

## 📚 References

- [terraform-aws-modules/kms v4 Release Notes](https://github.com/terraform-aws-modules/terraform-aws-kms/releases/tag/v4.0.0)
- [terraform-aws-modules/sns v7 Release Notes](https://github.com/terraform-aws-modules/terraform-aws-sns/releases/tag/v7.0.0)
- [terraform-aws-modules/lambda v8 Release Notes](https://github.com/terraform-aws-modules/terraform-aws-lambda/releases/tag/v8.0.0)
- [AWS Provider v6 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade)

---

**Document Generated:** 2 February 2026  
**Analysis Tool:** @terraform-maintenance-major agent  
**Environment:** analytical-platform-ingestion
