# Major Version Upgrade Plan: observability-platform

**Status**: DRAFT - For Review & Planning Only  
**Date**: 1 June 2026  
**Strategy**: Option B - Provider-First Approach  

## Executive Summary

This document outlines a phased approach to upgrade major versions of Terraform modules in the `observability-platform` environment. The AWS provider constraint (currently ~> 5.8) is the primary blocker for other upgrades, so Phase 1 upgrades the AWS provider to 6.x, which unlocks Phases 2 and 3.

**Total Timeline**: ~1-2 weeks for full migration  
**Risk Level**: MEDIUM - Requires careful testing and staged rollout  

---

## Module Upgrade Status

| Module | Current | Target | Phase | Prerequisite | Effort | Status |
|--------|---------|--------|-------|--------------|--------|--------|
| aws provider | ~> 5.8 | ~> 6.0 | 1 | N/A | LOW | READY |
| terraform-aws-modules/lambda/aws | v7.20.1 | v8.8.0 | 2 | Phase 1 | LOW | READY |
| terraform-aws-modules/iam/aws | v5.52.2 | v6.6.1 | 3 | Phase 1 | MEDIUM-HIGH | REQUIRES ANALYSIS |
| terraform-aws-modules/managed-prometheus/aws | v2.2.3 | v4.3.1 | DEFER | Unknown | HIGH | BLOCKED - NO DOCS |
| ministryofjustice/observability-platform-tenant/aws | v1.2.0 | v9.9.9 | SKIP | Unknown | CRITICAL | NOT RECOMMENDED |

---

## Phase 1: AWS Provider Upgrade (6.x)

### Impact Scope
- **File**: `versions.tf`
- **Affects**: ALL AWS resources in the environment
- **Risk Level**: MEDIUM (requires comprehensive testing)
- **Prerequisite**: None - This is the foundation

### Required Changes

**File: `versions.tf`**

```diff
 terraform {
   required_providers {
     aws = {
-      version = "~> 5.8, != 5.86.0"
+      version = "~> 6.0"
       source  = "hashicorp/aws"
     }
```

### Testing Checklist
- [ ] `terraform init` completes successfully
- [ ] `terraform validate` passes
- [ ] `terraform fmt -check` shows no formatting issues
- [ ] `terraform plan` shows no destructive changes
- [ ] All resource types are recognized by AWS provider 6.0
- [ ] Manual review of breaking changes in AWS provider 6.0 release notes

### Breaking Changes in AWS Provider 6.0
- **Default AMI data source deprecation**: `aws_ami` requires explicit `owners` filter
- **EC2 Classic removal**: If used, requires refactoring
- **Endpoint URLs**: Must be specified explicitly in some cases
- See: https://github.com/hashicorp/terraform-provider-aws/releases/tag/v6.0.0

### Rollout Strategy
1. Create feature branch (✓ Already done: `copilot-major-upgrade/observability-platform-*`)
2. Update `versions.tf` with AWS provider 6.0
3. Run `terraform init` to download provider
4. Run `terraform plan` to identify any breaking changes
5. If plan shows errors, investigate and fix specific resources
6. Create draft PR for team review
7. After approval, merge to main
8. Deploy to staging environment first
9. Verify in staging before production deployment

---

## Phase 2: terraform-aws-modules/lambda/aws (v7 → v8)

**Prerequisite**: Phase 1 (AWS provider 6.0+) ✓ Will be available after Phase 1  
**Timeline**: Can begin 1 day after Phase 1 completion  

### Impact Scope
- **Files**: `lambda-functions.tf`
- **Modules affected**:
  - `grafana_api_key_rotator` (v7.20.1 → v8.8.0)
  - `securityhub_metric_ingester` (v7.20.1 → v8.8.0)
- **Risk Level**: LOW
- **Code Changes Required**: NO - Version bump only

### Required Changes

**File: `lambda-functions.tf`**

Locate both lambda module blocks and update version:
```diff
 module "grafana_api_key_rotator" {
   source  = "terraform-aws-modules/lambda/aws"
-  version = "7.20.1"
+  version = "8.8.0"
```

```diff
 module "securityhub_metric_ingester" {
   source  = "terraform-aws-modules/lambda/aws"
-  version = "7.20.1"
+  version = "8.8.0"
```

### Breaking Changes
- Requires AWS provider v6.0+ (satisfied by Phase 1)
- No code changes required - module interface remains compatible
- No variable or output changes

### Testing Checklist
- [ ] `terraform init` completes
- [ ] `terraform validate` passes
- [ ] `terraform plan` shows no changes except version
- [ ] Manual review of lambda module changelog
- [ ] Verify Lambda function definitions are unchanged

---

## Phase 3: terraform-aws-modules/iam/aws (v5 → v6)

**Prerequisite**: Phase 1 (AWS provider 6.0+)  
**Timeline**: Can begin after Phase 1, but requires more analysis than Phase 2  

### Impact Scope
- **File**: `iam-policies.tf`
- **Module affected**: `amazon_managed_grafana_remote_cloudwatch_iam_policy` (v5.52.2 → v6.6.1)
- **Risk Level**: MEDIUM (requires validation)
- **Code Changes**: Likely minimal but requires review

### Required Changes

**File: `iam-policies.tf`**

```diff
 module "amazon_managed_grafana_remote_cloudwatch_iam_policy" {
   source = "terraform-aws-modules/iam/aws//modules/iam-policy"
-  version = "5.52.2"
+  version = "6.6.1"
```

**Note**: The module path `//modules/iam-policy` does NOT change. Only the version is updated.

### Breaking Changes in iam/aws v6
1. **AWS provider requirement**: v6.0+ (satisfied by Phase 1)
2. **Terraform version requirement**: v1.5.7+ (current: ~> 1.10 - COMPATIBLE ✓)
3. **Submodule restructuring** (NOT AFFECTED FOR iam-policy):
   - `iam-assumable-role` → `iam-role` (not used in observability-platform)
   - `iam-github-oidc-role` removed (not used)
   - `iam-eks-role` removed (not used)
4. **Permission defaults**: Removed - explicit ARN scopes now required (review needed)

### Code Review Checklist
- [ ] Verify `iam-policy` submodule usage remains unchanged
- [ ] Review all `policy` variable inputs for explicit ARN scope
- [ ] Ensure no variables are relying on removed default permissions
- [ ] Check if policy statements need explicit Principal restrictions

### Testing Checklist
- [ ] `terraform init` completes
- [ ] `terraform validate` passes
- [ ] `terraform plan` shows policy content (not destroying/recreating)
- [ ] Manual review of generated IAM policy JSON
- [ ] Security review: Verify permissions are still appropriate
- [ ] Test in staging: Verify Grafana can still access CloudWatch metrics

---

## Deferred Upgrades

### terraform-aws-modules/managed-prometheus/aws (v2 → v4)

**Status**: ⚠️ BLOCKED - Insufficient Documentation  

**Current**: v2.2.3  
**Latest**: v4.3.1  
**Issue**: No release notes, CHANGELOG, or upgrade guide available  

**Recommendation**: 
- Contact terraform-aws-modules maintainers for breaking change documentation
- OR skip this upgrade indefinitely (module works fine at v2.2.3)
- OR investigate by analyzing git history and code diffs manually

**Timeline**: Cannot proceed until documentation is available

---

### ministryofjustice/observability-platform-tenant/aws (v1 → v9)

**Status**: ❌ NOT RECOMMENDED - Excessive Risk  

**Current**: v1.2.0  
**Latest**: v9.9.9  
**Issue**: 8 major version jumps with no release history or documentation  

**Recommendation**: 
- This module is not recommended for upgrade at this time
- The version jump is too large without clear migration path
- Contact module maintainers for:
  - Release notes for v2.0.0 → v9.9.9
  - Migration guides
  - Breaking change summaries

**Timeline**: Defer indefinitely until documentation is available

---

## Rollout Strategy

### Per-Phase Approach
1. **Prepare Phase**: Create feature branch, update versions
2. **Plan Phase**: Run `terraform plan`, review output
3. **Review Phase**: Create draft PR, request team review
4. **Test Phase**: Merge to staging, run integration tests
5. **Deploy Phase**: After approval, deploy to production

### Parallel Execution
- Phases 2 & 3 can be planned in parallel (after Phase 1 completes)
- Only one phase should be deployed at a time
- Minimum 2-3 days between phase deployments for stability monitoring

### Rollback Strategy
Each phase can be rolled back by:
1. Reverting the version change
2. Running `terraform init` again
3. Reapplying previous version

---

## Recommendations & Next Steps

### Immediate Actions (Today)
1. **Review this plan** - Team discussion on approach
2. **Approve Phase 1** - AWS provider upgrade
3. **Schedule Phase 1 execution** - Recommend within 3 days

### After Phase 1 Completion
4. **Plan Phase 2** - Lambda module upgrade (low effort)
5. **Plan Phase 3** - IAM module analysis & upgrade (medium effort)

### Longer Term
6. **Investigate managed-prometheus** - Determine if v4 upgrade is viable
7. **Determine observability-platform-tenant strategy** - Keep at v1 or investigate v2+

---

## Risk Assessment

| Phase | Risk | Mitigation | Timeline |
|-------|------|-----------|----------|
| 1 - AWS Provider | MEDIUM | Comprehensive testing, staging first | 1-2 days |
| 2 - Lambda | LOW | Version only, no code changes | 1 day |
| 3 - IAM | MEDIUM | Code review, permission validation | 3-5 days |
| Deferred | UNKNOWN | Requires documentation | N/A |

---

## Contact & Questions

- **Module Maintainers**:
  - terraform-aws-modules: https://github.com/terraform-aws-modules
  - ministryofjustice modules: https://github.com/ministryofjustice

- **AWS Provider**: https://github.com/hashicorp/terraform-provider-aws

---

**Document Status**: DRAFT  
**Created**: 1 June 2026  
**Approval Status**: Pending  
