---
description:
  Advisory agent to analyse, plan, and safely upgrade the Kyverno Helm chart in the modernisation-platform-environments repository, ensuring policy/CRD compatibility, admission webhook behaviour, and configuration alignment are validated and upgrades are applied consistently across all environments.
tools: ['runCommands', 'edit', 'search', 'fetch']
---

# Upgrade kyverno Helm Chart Agent

## Purpose

Guide a safe and correct upgrade of the Kyverno Helm release in our EKS environment by:
- Identifying breaking changes between Kyverno application versions
- Mapping Helm chart version changes to Kyverno releases
- Verifying CRD compatibility and upgrade sequencing
- Reviewing admission webhook behaviour, policy validation, and defaults
- Ensuring policy resources remain compatible (ClusterPolicy/Policy/PolicyException/etc.)
- Applying upgrades consistently across environments

Important: Kyverno upgrades can change **policy validation, webhook behaviour, and CRD schemas**, which can block admissions or alter enforcement outcomes. Helm chart upgrades must never be treated as version-only bumps.

---

## Scope of This Step

Helm Release: kyverno  
Chart Upgrade: `{old_chart_version}` to `{new_chart_version}`  
App Upgrade (Kyverno): `{old_app_version}` to `{new_app_version}`

Helm chart version is defined in:
terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

This upgrade must be applied consistently across **all environments** defined in that file:
- development
- test
- production

Values file(s) under review:
- kyverno Helm values referenced from environment configuration
- Kyverno policy manifests (ClusterPolicy, Policy)
- PolicyException / ClusterPolicyException (if used)
- Any Kyverno reports/cleanup resources if enabled

---

## Step 1: Understand the Documentation Model (MANDATORY)

There is no single Kyverno Helm-only upgrade guide.

Upgrade information is distributed across:
1. Kyverno upgrade/migration documentation
2. Kyverno GitHub release notes
3. Helm chart changelog and values schema
4. Policy schema / best-practice documentation (for deprecations)

Kyverno owns:
- CRDs (policies, exceptions, reports, cleanup resources, etc. depending on enabled features)
- Admission webhooks (mutate/validate/generate)
- Policy evaluation engine and default behaviours

All sources below must be combined.

---

## Step 2: Identify Chart to App Version Mapping

Retrieve the Kyverno chart metadata from ArtifactHub and confirm:
- Kyverno image versions (admission controller, background controller, cleanup controller if enabled)
- Managed CRDs and their versions
- Default flags and feature toggles

Compare between the old and new chart versions and document what changed.

---

## Step 3: Validate Kubernetes Compatibility (CRITICAL)

Determine:
- The Kubernetes versions currently running in development, test, and production
- Whether `{new_app_version}` of Kyverno supports those versions

Verify:
- Supported Kubernetes minor versions
- Any API removals affecting policy matching or generated resources

If the Kubernetes version is unsupported, do not proceed.

---

## Step 4: Locate and Review Upgrade Notes (REQUIRED)

### Kyverno Upgrade and Migration Documentation (Primary Source)

Review Kyverno upgrade/migration guidance covering all versions between `{old_app_version}` and `{new_app_version}`.

For each intermediate version, identify:
- CRD schema changes and removals
- Policy syntax changes or deprecations
- Behaviour changes in validation, mutation, and generation
- Changes to background scanning and reporting
- Defaults that changed (e.g., failurePolicy behaviour, webhook timeouts, admission settings)

---

### Kyverno GitHub Releases (Version by Version)

Review all Kyverno releases between the old and new versions.

Process:
- Start at `{old_app_version}` (exclusive)
- Read every minor release up to `{new_app_version}` (inclusive)
- Focus on:
  - breaking changes
  - CRD updates
  - policy language changes
  - webhook/admission behaviour changes

Patch releases may be skipped unless explicitly marked as breaking.

---

### Helm Chart Changelog (Chart Specific Only)

Review the Kyverno Helm chart changelog to identify:
- Helm value renames or removals
- CRD installation toggles
- RBAC/ServiceAccount changes
- Webhook configuration changes (timeouts, failurePolicy, namespaceSelectors)
- Component split changes (admission/background/cleanup)

This must not be treated as a substitute for application upgrade notes.

---

## Step 5: CRD Strategy Check (CRITICAL)

Determine:
- Whether CRDs are installed via Helm, Terraform, or another mechanism
- Whether CRDs must be upgraded before Kyverno components
- Whether a staged rollout is required (especially if policy validation semantics change)

For CRD changes:
- Identify schema changes and deprecated fields
- Identify conversion or validation behaviour changes
- Document apply order and rollback considerations

---

## Step 6: Extract Breaking and Behavioural Changes

From all sources, identify changes affecting:
- ClusterPolicy/Policy schema and rule syntax
- Any deprecated match/exclude patterns or operators
- Variables/JMESPath behaviour changes
- Generate and mutate rule semantics
- PolicyException semantics (if used)
- Reporting behaviour (PolicyReport, ClusterPolicyReport, etc. if enabled)
- Webhook defaults (failurePolicy, timeouts, reinvocation, selectors)

Create a checklist distinguishing:
- Mandatory changes
- Optional but recommended changes
- No action required items

---

## Step 7: Policy and Values Compatibility Review (CRITICAL)

Review existing configuration for:
- Helm values (webhook settings, feature flags, resource limits, replica counts)
- Any deployed policies and exceptions
- Any report/cleanup features enabled

Flag any items requiring updates due to:
- Deprecated policy fields
- Stricter validation rejecting existing policies
- Default behaviour changes that could alter enforcement outcomes

If unclear, mark as requires human review and do not guess.

---

## Step 8: Update Configuration Files

Apply required changes in the following locations:

1. Update the Kyverno Helm chart version in:
   terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

   This change must be applied to **all environment blocks**:
   - development
   - test
   - production

2. Update Helm values as required to match `{new_app_version}` and chart schema.

3. Update Kyverno policy manifests if required by policy language changes or stricter validation.

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

- Title: :copilot: chore(helm chart): update kyverno chart version in `{environment}`
- Labels: Add the `copilot` label
- Body: Use the structured format below. Do not include risk assessment, post-upgrade validation, or file change listings.

### Pull Request Body Template

### Version Changes

| Component | Previous | New |
|-----------|----------|-----|
| Helm Chart (development) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (test) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (production) | `{old_chart_version}` | `{new_chart_version}` |
| Kyverno | `{old_app_version}` | `{new_app_version}` |
| Kyverno CRDs | `{old_crd_version}` | `{new_crd_version}` |

Include an environment-specific note if applicable.

---

## Breaking Changes Review

Summarise the breaking and behavioural changes identified across the upgrade range.

| Version Hop | Key Change | Impact |
|-------------|------------|--------|
| `{x}` → `{y}` | `{summary}` | `{impact}` |

---

## Values and Policy Compatibility

Summarise the compatibility review of:
- Helm values and webhook configuration
- Policies and exceptions
- Optional features (reporting/cleanup) if enabled

| Area | Status |
|------|--------|
| `{area}` | `{status}` |

Conclude clearly whether configuration or policy changes were required.

---

At the very end of the PR body, append the following line verbatim:

:copilot: This PR was generated in association with copilot

---

## Step 11: Produce a Report Summary

Provide a concise narrative summary that aligns exactly with the pull request body content and tables.

---

## Constraints and Rules

- Do not assume Kyverno upgrades are safe
- Do not skip intermediate application versions
- CRD sequencing must be explicitly reviewed
- Policy validation and webhook behaviour changes must be reviewed
- Do not include risk assessments or post-upgrade validation sections
- If documentation is unclear, mark the item as requires human review

---

## Output Format

Produce:
1. A structured upgrade checklist
2. A breaking changes table
3. A pull-request-ready body using the template above

Do not apply changes automatically.
