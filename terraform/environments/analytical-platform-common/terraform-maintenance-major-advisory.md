# Terraform Maintenance Major Advisory

## Metadata
- Date of analysis: 2026-02-18
- Agent mode: Advisory + refactor (recommended changes only)
- Target environment: `terraform/environments/analytical-platform-common`
- Analysis status: Refactor Complete

## Modules analysed

| Module block(s) | Source | Current version | Latest available version | Major upgrade available | Status |
|---|---|---:|---:|---|---|
| `ecr_access_iam_role`, `analytical_platform_github_actions_iam_role`, `analytical_platform_terraform_iam_role`, `data_engineering_datalake_access_github_actions_iam_role`, `data_engineering_datalake_access_terraform_iam_role`, `ecr_access_iam_policy`, `analytical_platform_terraform_iam_policy`, `analytical_platform_github_actions_iam_policy`, `data_engineering_datalake_access_github_actions_iam_policy`, `data_engineering_datalake_access_terraform_iam_policy` | `terraform-aws-modules/iam/aws` (submodules) | 5.60.0 | 6.4.0 | Yes (5.x -> 6.x) | Complete |
| `observability_platform_tenant` | `ministryofjustice/observability-platform-tenant/aws` | 2.0.0 | 9.9.9 | Yes (2.x -> 9.x) | Pending (hold) |
| `analytical_platform_airflow_auto_approval_dynamodb_table` | `terraform-aws-modules/dynamodb-table/aws` | 5.5.0 | 5.5.0 | No | N/A |
| `terraform_bucket` | `terraform-aws-modules/s3-bucket/aws` | 5.10.0 | 5.10.0 | No | N/A |
| `analytical_platform_compute_cluster_data_secret`, `airflow_github_app_secret` | `terraform-aws-modules/secrets-manager/aws` | 2.1.0 | 2.1.0 | No | N/A |
| `ecr_kms`, `terraform_s3_kms`, `secrets_manager_common_kms` | `terraform-aws-modules/kms/aws` | 4.2.0 | 4.2.0 | No | N/A |
| `analytical_platform_observability` | `github.com/ministryofjustice/terraform-aws-analytical-platform-observability` (pinned commit; comment indicates 4.2.0) | 4.2.0 | 4.2.0 (latest tag) | No | N/A |

## Detailed migration plans

### 1) IAM module family (`terraform-aws-modules/iam/aws`)

- Version summary: `5.60.0 -> 6.4.0` (major `5.x -> 6.x`)
- Upgrade complexity: High (structural module consolidation and variable refactor)

#### Breaking changes summary
- Upstream `UPGRADE-6.0.md` reports:
  - Minimum Terraform is now `>= 1.5.7`.
  - Minimum AWS provider is now `>= 6.0`.
  - `iam-assumable-role` renamed/merged into `iam-role`.
  - `iam-github-oidc-role` merged into `iam-role`.
  - Trust policy model changed; several legacy role variables removed.

#### Refactoring requirements (current usage in this environment)
- Module source updates required:
  - `//modules/iam-github-oidc-role` -> `//modules/iam-role`
  - `//modules/iam-assumable-role` -> `//modules/iam-role`
- Argument updates required:
  - `create_role` -> `create`
  - `role_name` -> `name`
  - `custom_role_policy_arns` -> `policies` (map)
- Removed arguments currently in use:
  - `trusted_role_arns` (replace with `trust_policy_permissions` blocks)
  - `role_requires_mfa` (removed in v6 `iam-role`)
- IAM policy submodule (`iam-policy`) can be version-bumped with minimal argument changes:
  - `create_policy` renamed to `create` in v6 (not used in current files)

#### Impact considerations
- Trust policy behaviour is the main risk area.
- Incorrect conversion of role trust configuration could break role assumption by GitHub Actions or Terraform roles.
- Human review of IAM trust/policy diff in plan output is mandatory.

### 2) Observability tenant module (`ministryofjustice/observability-platform-tenant/aws`)

- Version summary: `2.0.0 -> 9.9.9` (major `2.x -> 9.x`)
- Upgrade complexity: Medium/uncertain (latest tags appear test-only)

#### Breaking changes summary
- Release `2.0.0` introduced AWS provider constraint update to `~> 6.0` (already met by environment).
- Latest tags `9.9.8` and `9.9.9` release names include test/do-not-use wording.

#### Refactoring requirements
- Current used inputs (`observability_platform_account_id`, `tags`) are still present.
- v9 adds optional health signal inputs:
  - `enable_health_signal_reader_role`
  - `observability_platform_health_signal_assumer_arns`
  - `health_signal_reader_role_name`
- No mandatory input rename identified for current configuration.

#### Impact considerations
- Advisory recommendation: hold upgrade until a production-ready, non-test major release is published upstream.

## Pre-flight validation findings

### Workspace consistency scan
- Provider constraints found in `versions.tf`:
  - `aws ~> 6.0`
  - `http ~> 3.0`
  - `terraform ~> 1.10`
- No provider constraint conflicts detected within the scanned environment files.

### Module schema comparison findings
- IAM (`5.60.0` vs `6.4.0`): breaking schema and module-path changes confirmed; code refactor required.
- Observability tenant (`2.0.0` vs `9.9.9`): used variables still present; added optional variables in newer major.

### Validation requirements
- If refactor is approved, use incremental validation:
  1. Apply provider/module source/version updates in logical groups.
  2. Run `terraform init -upgrade`.
  3. Run `terraform validate`.
  4. Run `terraform plan` and inspect IAM trust and policy deltas carefully.
- Explicitly verify GitHub OIDC role assumption and Terraform role assumption paths post-change.

## Proposed diffs (advisory only)

### File: `iam-policies.tf`
```diff
# All iam-policy module blocks
-  version = "5.60.0"
+  version = "6.4.0"
```

### File: `iam-roles.tf` (OIDC role modules)
```diff
-  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
-  version = "5.60.0"
+  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
+  version = "6.4.0"

+  create             = true
+  enable_github_oidc = true
-  subjects = ["ministryofjustice/analytical-platform-airflow:*"]
+  oidc_subjects = ["ministryofjustice/analytical-platform-airflow:*"]
```

### File: `iam-roles.tf` (assumable role modules)
```diff
-  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
-  version = "5.60.0"
+  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
+  version = "6.4.0"

-  create_role = true
+  create = true

-  role_name = "analytical-platform-terraform"
+  name = "analytical-platform-terraform"

-  trusted_role_arns = [module.analytical_platform_github_actions_iam_role.arn]
+  trust_policy_permissions = {
+    github_actions_assume = {
+      actions = ["sts:AssumeRole"]
+      principals = [{
+        type        = "AWS"
+        identifiers = [module.analytical_platform_github_actions_iam_role.arn]
+      }]
+    }
+  }

-  custom_role_policy_arns = [module.analytical_platform_terraform_iam_policy.arn]
+  policies = {
+    terraform = module.analytical_platform_terraform_iam_policy.arn
+  }
```

### File: `observability.tf` (not recommended at this time)
```diff
-  version = "2.0.0"
+  version = "9.9.9"
```

## Recommendation summary
- Proceed candidate: IAM module family (`5.x -> 6.x`) with careful staged refactor and validation.
- Defer candidate: Observability tenant (`2.x -> 9.x`) until upstream non-test major release is available.

## Phase summary (implementation and stabilisation)
- Applied recommended IAM v6 refactor in `iam-roles.tf` and `iam-policies.tf`.
- Added `use_name_prefix = false` to migrated IAM role modules to prevent role replacement and resolve IAM name prefix length validation failure.
- Added `description = "IAM Policy"` to each IAM policy module block to preserve previous effective defaults and avoid policy replacement caused by v5 -> v6 default change (`"IAM Policy"` -> `null`).
- Re-ran local validation and planning after each fix to confirm impact.
- Left provider warning unchanged by request (`role_arn` warning in `platform_providers.tf`).

## Validation results (refactor run)
- `terraform validate`: Passed in all post-change runs.
- `member-local-plan.sh -r platform-engineer-admin -s production`:
  - Initial post-refactor run failed on IAM role `name_prefix` length.
  - After `use_name_prefix = false`, plan succeeded and reduced to `10 to add, 2 to change, 10 to destroy`.
  - After setting policy `description = "IAM Policy"`, plan reduced further to `2 to add, 2 to change, 2 to destroy`.
- Remaining planned actions are expected module-internal attachment/trust-policy transitions for two Terraform IAM roles:
  - Add: `aws_iam_role_policy_attachment.this[...]` x2
  - Destroy: `aws_iam_role_policy_attachment.custom[0]` x2
  - Change in-place: `aws_iam_role.this[0]` x2 (trust policy + `force_detach_policies` behaviour)
- Current non-blocking warning:
  - Provider warning for missing `role_arn` in `platform_providers.tf` (unchanged by request).

## History log
- 2026-02-18  Advisory run completed for `analytical-platform-common`.
  - No `.tf` files modified.
  - Advisory document created.
- 2026-02-18  Refactor run completed for recommended IAM major upgrade.
  - Updated IAM module family from `5.60.0` to `6.4.0` in `iam-roles.tf` and `iam-policies.tf`.
  - Updated role output references from `iam_role_arn` to `arn` where required.
  - Kept `observability_platform_tenant` unchanged.
  - `terraform validate` passed; initial plan surfaced expected migration deltas and one blocking `name_prefix` issue.
- 2026-02-18  Stabilisation follow-up completed.
  - Added `use_name_prefix = false` to migrated IAM role modules to resolve prefix-length failure and avoid role replacements.
  - Added `description = "IAM Policy"` to IAM policy module blocks to avoid replacement from default drift.
  - Final local plan state reached `2 to add, 2 to change, 2 to destroy` with expected IAM v6 attachment/trust-policy transitions only.

## Ready for PR checklist
- [ ] Re-run `bash /workspaces/modernisation-platform-environments/scripts/member-local-plan.sh -r platform-engineer-admin -s production` and confirm plan remains at `2 to add, 2 to change, 2 to destroy`.
- [ ] Confirm planned IAM role trust policy updates are expected for:
  - `analytical-platform-terraform`
  - `data-engineering-datalake-access-terraform`
- [ ] Confirm attachment transition is expected (`custom[0]` destroy -> `this[...]` create) for both Terraform IAM roles.
- [ ] Confirm no changes are proposed for `observability_platform_tenant`.
- [ ] Confirm provider warning in `platform_providers.tf` is acknowledged and intentionally deferred for this change set.
- [ ] Include this advisory file in the PR so reviewers can trace rationale, validation, and residual deltas.
