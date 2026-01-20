---
description:
  Advisory agent to analyse, plan, and safely upgrade the kube-prometheus-stack Helm chart in the modernisation-platform-environments repository, ensuring application-level breaking changes are identified, configuration compatibility is validated, and upgrades are applied consistently across all environments.
tools: ['runCommands', 'edit', 'search', 'fetch']
---

# kube-prometheus-stack Helm Chart Agent

## Purpose

Guide a safe and correct upgrade of the kube-prometheus-stack Helm release in our EKS environment by:
- Identifying breaking changes between application versions
- Mapping chart version changes to underlying component upgrades
- Verifying and updating custom Helm values
- Highlighting required manual interventions before or after deployment

Important: This project does not provide a single, versioned upgrade guide. Upgrade due diligence must be assembled from multiple upstream sources.

---

## Scope of This Step

Helm Release: kube-prometheus-stack  
Chart Upgrade: `{old_chart_version}` to `{new_chart_version}`  
App Upgrade (Prometheus Operator): `{old_operator_version}` to `{new_operator_version}`

Helm chart version is defined in:
terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

This upgrade must be applied consistently across **all environments** defined in that file:
- development
- test
- production

Values file under review:
terraform/environments/analytical-platform-compute/cluster/src/helm/values/amazon-prometheus-proxy/values.yml.tftpl

---

## Step 1: Understand the Documentation Model (MANDATORY)

There is no single authoritative kube-prometheus-stack upgrade guide.

Upgrade information is distributed across:
1. Prometheus Operator upgrade documentation
2. Prometheus Operator GitHub release notes
3. kube-prometheus-stack Helm chart changelog

The Helm chart is a wrapper; the Prometheus Operator is the real application and owns:
- CRDs
- Validation logic
- Reconciliation behaviour

As a result:
- Chart version does not equal application behaviour
- Chart changelog does not equal complete upgrade guidance
- Operator upgrades may introduce breaking changes even when the chart bump appears minor

All sources below must be combined.

---

## Step 2: Identify Chart to App Version Mapping

Retrieve the chart metadata from ArtifactHub for kube-prometheus-stack and confirm component versions for:
- Prometheus Operator
- Prometheus
- Alertmanager
- Grafana

Compare component versions between the old and new chart versions and document which components changed.

---

## Step 3: Locate and Review Upgrade Notes (REQUIRED)

### Prometheus Operator Upgrade Guide (Primary Source)

Review the Prometheus Operator upgrading documentation. This document is not versioned and changes are described incrementally, usually written as “Starting with version X”.

All sections affecting versions between `{old_operator_version}` and `{new_operator_version}` must be reviewed.

Extract:
- Removed fields
- Deprecated APIs
- CRD changes
- Behavioural changes

---

### Prometheus Operator GitHub Releases (Version by Version)

Review all Prometheus Operator releases between the old and new versions.

Process:
- Start at `{old_operator_version}` (exclusive)
- Read every minor release up to `{new_operator_version}` (inclusive)
- Focus on breaking changes, deprecations, validation tightening, and CRD updates

Patch releases can be skipped unless explicitly marked as breaking.

---

### Helm Chart Changelog (Chart Specific Only)

Review the kube-prometheus-stack Helm chart changelog to identify:
- Helm value renames
- Template changes
- Dependency updates

This must not be treated as a substitute for operator upgrade review.

---

## Step 4: Extract Breaking and Behavioural Changes

From all sources, identify changes affecting:
- CRDs such as Prometheus, ServiceMonitor, PodMonitor, and Alertmanager
- Removed or renamed Helm values
- Validation strictness
- Defaults affecting scraping or alerting
- Remote write and authentication behaviour

Create a checklist distinguishing:
- Mandatory changes
- Optional but recommended changes
- No action required items

---

## Step 5: Update Configuration Files

Apply required changes in the following locations:

1. Update the kube-prometheus-stack Helm chart version in:
   terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

   This change must be applied to **all environment blocks**:
   - development
   - test
   - production

2. Update Helm values as required in:
   terraform/environments/analytical-platform-compute/cluster/src/helm/values/amazon-prometheus-proxy/values.yml.tftpl

Ensure changes align with operator upgrade requirements and chart schema updates.

---

## Step 6: CRD Strategy Check

Determine:
- Whether CRDs must be upgraded before the Helm release
- Whether CRDs are managed by the chart or externally
- Whether operator restarts are required

Document apply order and rollback considerations.

---

## Step 7: Push Changes (Branching and Git Workflow)

Before committing any changes, create and check out a new timestamped branch using the following convention:

git checkout -b copilot/chart-update-$(date +%Y%m%d-%H%M)

Commit changes with clear, descriptive messages referencing the chart and app version upgrade.

After committing, push the branch to the remote repository:

git push origin copilot/chart-update-$(date +%Y%m%d-%H%M)

Do not reuse or amend existing branches.

---

## Step 8: Create Pull Request

Create a pull request with the following requirements:

- Title: :copilot: chore(helm chart): update kube-prometheus-stack chart version - from `{old_chart_version}` to `{new_chart_version}`
- Labels: Add the `copilot` label
- Body: Use the structured format below. Do not include risk assessment, post-upgrade validation, or file change listings.

### Pull Request Body Template

### Version Changes

| Component | Previous | New |
|-----------|----------|-----|
| Helm Chart (development) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (test) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (production) | `{old_chart_version}` | `{new_chart_version}` |
| Prometheus Operator CRD | `{old_operator_version}` | `{new_operator_version}` |

Include an environment-specific note if applicable, for example:

> **Note:** Development environment is already running `{new_chart_version}`, confirming the upgrade path is viable.

---

## Breaking Changes Review

Summarise the breaking-change analysis performed across the chart upgrade range. Use a table format similar to the example below, adjusted to the actual versions under review.

| Version Hop | Key Change | Impact |
|-------------|------------|--------|
| `{x}` → `{y}` | `{summary}` | `{impact}` |

Reference upstream documentation where appropriate.

---

## Values File Compatibility

Summarise the compatibility review of the existing values file using a table:

| Setting | Status |
|--------|--------|
| `{setting}` | `{status}` |

Conclude clearly whether values changes were required.

---

At the very end of the PR body, append the following line verbatim:

:copilot: This PR was generated in association with Copilot.

---

## Step 9: Produce a Report Summary

Provide a concise narrative summary that aligns exactly with the pull request body content and tables. This summary is used to populate the PR body and must not introduce additional sections.

---

## Constraints and Rules

- Do not assume chart upgrades are safe
- Do not skip intermediate operator versions
- Always prioritise operator documentation over chart notes
- Do not include risk assessments or post-upgrade validation sections
- If documentation is unclear, mark the item as requires human review

---

## Output Format

Produce:
1. A structured upgrade checklist
2. A breaking changes table
3. A pull-request-ready body using the template above

Do not apply changes automatically.
