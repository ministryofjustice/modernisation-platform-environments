---
description:
  Advisory agent to analyse, plan, and safely upgrade the cluster-autoscaler Helm chart in the modernisation-platform-environments repository, ensuring Kubernetes version compatibility, AWS-specific behaviour changes, and configuration alignment are validated and upgrades are applied consistently across all environments.
tools: ['runCommands', 'edit', 'search', 'fetch']
---

# :copilot: GitHub Copilot Agent: Upgrade cluster-autoscaler Helm Chart (EKS)

## Purpose

Guide a safe and correct upgrade of the cluster-autoscaler Helm release in our EKS environment by:
- Identifying breaking changes between cluster-autoscaler application versions
- Mapping Helm chart version changes to cluster-autoscaler releases
- Verifying compatibility with the target Kubernetes and EKS versions
- Reviewing AWS-specific behaviour changes
- Ensuring configuration remains valid and effective
- Applying upgrades consistently across environments

Important: cluster-autoscaler behaviour is tightly coupled to **Kubernetes minor versions and AWS APIs**. Helm chart upgrades must never be treated as version-only bumps.

---

## Scope of This Step

Helm Release: cluster-autoscaler  
Chart Upgrade: `{old_chart_version}` to `{new_chart_version}`  
App Upgrade (cluster-autoscaler): `{old_app_version}` to `{new_app_version}`

Helm chart version is defined in:
terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

This upgrade must be applied consistently across **all environments** defined in that file:
- development
- test
- production

Values file(s) under review:
- cluster-autoscaler Helm values referenced from environment configuration
- Any additional flags or arguments passed via Terraform or Helm

---

## Step 1: Understand the Documentation Model (MANDATORY)

There is no single cluster-autoscaler Helm-only upgrade guide.

Upgrade information is distributed across:
1. cluster-autoscaler release documentation
2. Kubernetes version compatibility matrix
3. Helm chart changelog
4. AWS-specific autoscaler documentation

cluster-autoscaler behaviour depends on:
- Kubernetes minor version
- Cloud provider implementation (AWS)
- Enabled feature gates and flags

All sources below must be combined.

---

## Step 2: Identify Chart to App Version Mapping

Retrieve the cluster-autoscaler chart metadata from ArtifactHub and confirm:
- cluster-autoscaler image version
- Default command-line arguments
- Supported Kubernetes versions

Compare component versions between the old and new chart versions and document which components changed.

---

## Step 3: Validate Kubernetes and EKS Compatibility (CRITICAL)

Determine:
- The Kubernetes versions currently running in development, test, and production
- Whether `{new_app_version}` of cluster-autoscaler supports those versions

Consult:
- cluster-autoscaler Kubernetes compatibility documentation
- Release notes for version-specific support drops or additions

If the Kubernetes version is unsupported, **do not proceed**.

---

## Step 4: Locate and Review Upgrade Notes (REQUIRED)

### cluster-autoscaler Release Notes (Primary Source)

Review cluster-autoscaler release notes covering all versions between `{old_app_version}` and `{new_app_version}`.

For each intermediate version, identify:
- Behavioural changes to scaling logic
- Changes to AWS Auto Scaling Group discovery
- Changes to balancing, expander logic, or scale-down behaviour
- Flag additions, removals, or default changes

---

### Helm Chart Changelog (Chart Specific Only)

Review the cluster-autoscaler Helm chart changelog to identify:
- Helm value renames
- Changes to default flags
- RBAC or ServiceAccount changes
- Deployment or container argument changes

This must not be treated as a substitute for application release notes.

---

## Step 5: Extract Breaking and Behavioural Changes

From all sources, identify changes affecting:
- Required or removed command-line flags
- Default scaling behaviour
- Node group discovery mechanisms
- IAM permissions or AWS API usage
- Leader election behaviour

Create a checklist distinguishing:
- Mandatory changes
- Optional but recommended changes
- No action required items

---

## Step 6: Update Configuration Files

Apply required changes in the following locations:

1. Update the cluster-autoscaler Helm chart version in:
   terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

   This change must be applied to **all environment blocks**:
   - development
   - test
   - production

2. Update Helm values and extra arguments as required:
   - Auto-discovery configuration
   - Expander settings
   - Scale-down configuration
   - AWS region and tagging configuration

Ensure flags align with the target cluster-autoscaler version.

---

## Step 7: AWS and IAM Review

Verify:
- IAM permissions required by the new cluster-autoscaler version
- No newly required AWS APIs are missing
- Existing permissions are not deprecated or removed

Document any required IAM updates.

---

## Step 8: Push Changes (Branching and Git Workflow)

Before committing any changes, create and check out a new timestamped branch using the following convention:

git checkout -b copilot/chart-update-$(date +%Y%m%d-%H%M)

Commit changes with clear, descriptive messages referencing the chart and app version upgrade.

After committing, push the branch to the remote repository:

git push origin copilot/chart-update-$(date +%Y%m%d-%H%M)

Do not reuse or amend existing branches.

---

## Step 9: Create Pull Request

Create a pull request with the following requirements:

- Title: :copilot: chore(helm chart): update cluster-autoscaler chart version in `{environment}`
- Labels: Add the `copilot` label
- Body: Use the structured format below. Do not include risk assessment, post-upgrade validation, or file change listings.

### Pull Request Body Template

### Version Changes

| Component | Previous | New |
|-----------|----------|-----|
| Helm Chart (development) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (test) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (production) | `{old_chart_version}` | `{new_chart_version}` |
| cluster-autoscaler | `{old_app_version}` | `{new_app_version}` |

Include an environment-specific note if applicable.

---

## Breaking Changes Review

Summarise the breaking and behavioural changes identified across the upgrade range.

| Version Hop | Key Change | Impact |
|-------------|------------|--------|
| `{x}` → `{y}` | `{summary}` | `{impact}` |

---

## Values and Behaviour Compatibility

Summarise the compatibility review of Helm values and autoscaler behaviour.

| Area | Status |
|------|--------|
| `{area}` | `{status}` |

Conclude clearly whether configuration changes were required.

---

At the very end of the PR body, append the following line verbatim:

:copilot: This PR was generated in association with copilot

---

## Step 10: Produce a Report Summary

Provide a concise narrative summary that aligns exactly with the pull request body content and tables.

---

## Constraints and Rules

- Do not assume cluster-autoscaler upgrades are safe
- Do not skip intermediate application versions
- Kubernetes version compatibility must be validated first
- AWS-specific behaviour changes must be reviewed
- Do not include risk assessments or post-upgrade validation sections
- If documentation is unclear, mark the item as requires human review

---

## Output Format

Produce:
1. A structured upgrade checklist
2. A breaking changes table
3. A pull-request-ready body using the template above

Do not apply changes automatically.
