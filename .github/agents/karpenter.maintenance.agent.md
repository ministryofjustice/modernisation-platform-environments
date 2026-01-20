---
description:
  Advisory agent to analyse, plan, and safely upgrade the Karpenter Helm chart in the modernisation-platform-environments repository, ensuring Kubernetes and AWS compatibility, CRD sequencing, and behavioural changes are validated and upgrades are applied consistently across all environments.
tools: ['runCommands', 'edit', 'search', 'fetch']
---

# Upgrade karpenter Helm Chart Upgrade Agent

## Purpose

Guide a safe and correct upgrade of the Karpenter Helm release in our EKS environment by:
- Identifying breaking changes between Karpenter application versions
- Mapping Helm chart version changes to Karpenter controller releases
- Verifying Kubernetes version compatibility
- Reviewing AWS-specific behaviour and IAM requirements
- Validating CRD changes and upgrade sequencing
- Applying upgrades consistently across environments

Important: Karpenter upgrades frequently introduce **CRD schema changes and behavioural changes to provisioning logic**. Helm chart upgrades must never be treated as version-only bumps.

---

## Scope of This Step

Helm Release: karpenter  
Chart Upgrade: `{old_chart_version}` to `{new_chart_version}`  
App Upgrade (Karpenter): `{old_app_version}` to `{new_app_version}`

Helm chart version is defined in:
terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

This upgrade must be applied consistently across **all environments** defined in that file:
- development
- test
- production

Related releases:
- karpenter CRDs (often versioned separately or managed via a dedicated chart)

Values file(s) under review:
- karpenter Helm values referenced from environment configuration
- NodePool / NodeClass / Provisioner (legacy) manifests
- IAM roles, instance profiles, and AWS permissions used by Karpenter

---

## Step 1: Understand the Documentation Model (MANDATORY)

There is no single Karpenter Helm-only upgrade guide.

Upgrade information is distributed across:
1. Karpenter upgrade and migration documentation
2. Karpenter GitHub release notes
3. Helm chart changelog and values schema
4. AWS and Kubernetes compatibility documentation

Karpenter owns:
- CRDs (NodePool, NodeClass, and legacy Provisioner APIs)
- Node lifecycle and provisioning behaviour
- AWS infrastructure integration (EC2, Spot, AMIs, instance metadata)

All sources below must be combined.

---

## Step 2: Identify Chart to App Version Mapping

Retrieve the Karpenter chart metadata from ArtifactHub and confirm:
- Controller image version
- CRD versions managed by the chart
- Default feature gates and controller arguments

Compare between the old and new chart versions and document what changed.

---

## Step 3: Validate Kubernetes Compatibility (CRITICAL)

Determine:
- The Kubernetes versions currently running in development, test, and production
- Whether `{new_app_version}` of Karpenter supports those versions

Verify:
- Supported Kubernetes minor versions
- Deprecated API usage (e.g. PodSecurityPolicy, legacy scheduling APIs)

If the Kubernetes version is unsupported, do not proceed.

---

## Step 4: Locate and Review Upgrade Notes (REQUIRED)

### Karpenter Upgrade and Migration Documentation (Primary Source)

Review Karpenter upgrade and migration guides covering all versions between `{old_app_version}` and `{new_app_version}`.

For each intermediate version, identify:
- CRD changes (especially NodePool / NodeClass evolution)
- Behavioural changes to scheduling, consolidation, or drift detection
- Feature gate changes or defaults becoming enabled
- Removal of legacy APIs (e.g. Provisioner deprecations)

---

### Karpenter GitHub Releases (Version by Version)

Review all Karpenter releases between the old and new versions.

Process:
- Start at `{old_app_version}` (exclusive)
- Read every minor release up to `{new_app_version}` (inclusive)
- Focus on:
  - breaking changes
  - CRD migrations
  - AWS behaviour changes
  - default configuration changes

Patch releases may be skipped unless explicitly marked as breaking.

---

### Helm Chart Changelog (Chart Specific Only)

Review the Karpenter Helm chart changelog to identify:
- Helm value renames or removals
- CRD installation toggles
- RBAC / ServiceAccount changes
- Controller deployment changes

This must not be treated as a substitute for application upgrade notes.

---

## Step 5: CRD Strategy Check (CRITICAL)

Determine:
- Whether CRDs are installed via Helm, Terraform, or a separate CRD chart
- Whether CRDs must be upgraded before the controller
- Whether a staged rollout is required

For CRD changes:
- Identify schema changes and storage versions
- Identify removed or deprecated fields
- Document apply order and rollback considerations

Do not upgrade the controller before compatible CRDs are in place.

---

## Step 6: Extract Breaking and Behavioural Changes

From all sources, identify changes affecting:
- NodePool / NodeClass configuration
- Instance type selection and filtering
- Consolidation, expiration, and drift detection behaviour
- Spot vs On-Demand handling
- Defaults that may change scheduling outcomes

Create a checklist distinguishing:
- Mandatory changes
- Optional but recommended changes
- No action required items

---

## Step 7: AWS and IAM Review

Verify:
- IAM permissions required by the new Karpenter version
- EC2, Pricing, and SSM API usage
- Instance profile and role configuration
- Any new required tags or discovery mechanisms

Document any required IAM or AWS configuration updates.

---

## Step 8: Update Configuration Files

Apply required changes in the following locations:

1. Update the Karpenter Helm chart version in:
   terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

   This change must be applied to **all environment blocks**:
   - development
   - test
   - production

2. Update Helm values as required to match `{new_app_version}` and chart schema.

3. Update NodePool / NodeClass (or legacy Provisioner) manifests if required by CRD or behaviour changes.

---

## Step 9: Push Changes (Branching and Git Workflow)

Before committing any changes, create and check out a new timestamped branch using the following convention:

git checkout -b copilot/chart-update-$(date +%Y%m%d-%H%M)

Commit changes with clear, descriptive messages referencing the chart and app version upgrade.

After committing, push the branch to the remote repository:

git push origin copilot/chart-update-$(date +%Y%m%d-%H%M)

Do not reuse or amend existing branches.

---

## Step 10: Create Pull Request

Create a pull request with the following requirements:

- Title: :copilot: chore(helm chart): update karpenter chart version in `{environment}`
- Labels: Add the `copilot` label
- Body: Use the structured format below. Do not include risk assessment, post-upgrade validation, or file change listings.

### Pull Request Body Template

### Version Changes

| Component | Previous | New |
|-----------|----------|-----|
| Helm Chart (development) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (test) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (production) | `{old_chart_version}` | `{new_chart_version}` |
| Karpenter | `{old_app_version}` | `{new_app_version}` |
| Karpenter CRDs | `{old_crd_version}` | `{new_crd_version}` |

Include an environment-specific note if applicable.

---

## Breaking Changes Review

Summarise the breaking and behavioural changes identified across the upgrade range.

| Version Hop | Key Change | Impact |
|-------------|------------|--------|
| `{x}` → `{y}` | `{summary}` | `{impact}` |

---

## Values and Resource Compatibility

Summarise the compatibility review of:
- Helm values
- NodePool / NodeClass (or Provisioner) resources
- AWS/IAM integration

| Area | Status |
|------|--------|
| `{area}` | `{status}` |

Conclude clearly whether configuration or manifest changes were required.

---

At the very end of the PR body, append the following line verbatim:

:copilot: This PR was generated in association with copilot

---

## Step 11: Produce a Report Summary

Provide a concise narrative summary that aligns exactly with the pull request body content and tables.

---

## Constraints and Rules

- Do not assume Karpenter upgrades are safe
- Do not skip intermediate application versions
- Kubernetes compatibility must be validated first
- CRD sequencing must be explicitly reviewed
- AWS behaviour changes must be reviewed
- Do not include risk assessments or post-upgrade validation sections
- If documentation is unclear, mark the item as requires human review

---

## Output Format

Produce:
1. A structured upgrade checklist
2. A breaking changes table
3. A pull-request-ready body using the template above

Do not apply changes automatically.
