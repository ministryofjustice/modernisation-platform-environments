---
description:
  Advisory agent to analyse, plan, and safely upgrade the Velero Helm chart in the modernisation-platform-environments repository, ensuring Kubernetes/API compatibility, plugin and backup format considerations, and configuration alignment are validated and upgrades are applied consistently across all environments.
tools: ['runCommands', 'edit', 'search', 'fetch']
---

# Upgrade velero Helm Chart Agent

## Purpose

Guide a safe and correct upgrade of the Velero Helm release in our EKS environment by:
- Identifying breaking changes between Velero application versions
- Mapping Helm chart version changes to Velero releases
- Verifying Kubernetes and API compatibility
- Reviewing backup/restore behaviour changes and any format/version implications
- Verifying plugin compatibility (AWS plugin, CSI plugin, etc. if used)
- Ensuring configuration, schedules, and storage settings remain correct
- Applying upgrades consistently across environments

Important: Velero upgrades can change **backup/restore behaviour, plugin requirements, and CRD schemas**. Helm chart upgrades must never be treated as version-only bumps.

---

## Scope of This Step

Helm Release: velero  
Chart Upgrade: `{old_chart_version}` to `{new_chart_version}`  
App Upgrade (Velero): `{old_app_version}` to `{new_app_version}`

Helm chart version is defined in:
terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

This upgrade must be applied consistently across **all environments** defined in that file:
- development
- test
- production

Values file(s) and resources under review:
- velero Helm values referenced from environment configuration
- BackupStorageLocation and VolumeSnapshotLocation resources (if managed)
- Schedules, Backup, Restore resources
- Installed plugins (AWS, CSI, etc.)
- Any IRSA/IAM roles and bucket/KMS settings used for backups

---

## Step 1: Understand the Documentation Model (MANDATORY)

There is no single Velero Helm-only upgrade guide.

Upgrade information is distributed across:
1. Velero upgrade/migration documentation (including any version skew guidance)
2. Velero GitHub release notes
3. Helm chart changelog and values schema
4. Plugin documentation and compatibility notes (AWS/CSI/etc.)

Velero owns:
- CRDs (Backup, Restore, Schedule, BSL, VSL, etc.)
- Backup/restore engine behaviour
- Plugin interfaces and provider-specific behaviour

All sources below must be combined.

---

## Step 2: Identify Chart to App Version Mapping

Retrieve the Velero chart metadata from ArtifactHub and confirm:
- Velero image version
- Default initContainers/plugins behaviour
- Managed CRDs and chart options related to CRDs
- Any default flags or configuration changes

Compare between the old and new chart versions and document what changed.

---

## Step 3: Validate Kubernetes Compatibility (CRITICAL)

Determine:
- The Kubernetes versions currently running in development, test, and production
- Whether `{new_app_version}` of Velero supports those versions

Verify:
- Supported Kubernetes minor versions
- Any API removals affecting backup/restore (e.g., deprecated resources no longer included)
- Any changes to discovery or include/exclude behaviour due to Kubernetes API changes

If the Kubernetes version is unsupported, do not proceed.

---

## Step 4: Locate and Review Upgrade Notes (REQUIRED)

### Velero Upgrade / Migration Documentation (Primary Source)

Review Velero upgrade/migration guidance covering all versions between `{old_app_version}` and `{new_app_version}`.

For each intermediate version, identify:
- Breaking changes
- CRD schema changes
- Changes to backup formats or metadata handling (if any)
- Behaviour changes to restore ordering, hooks, or timeouts
- Feature gate changes and default changes

---

### Velero GitHub Releases (Version by Version)

Review all Velero releases between the old and new versions.

Process:
- Start at `{old_app_version}` (exclusive)
- Read every minor release up to `{new_app_version}` (inclusive)
- Focus on:
  - breaking changes
  - CRD updates
  - behavioural changes to backup/restore
  - plugin interface changes

Patch releases may be skipped unless explicitly marked as breaking.

---

### Helm Chart Changelog (Chart Specific Only)

Review the Velero Helm chart changelog to identify:
- Helm value renames or removals
- CRD installation toggles or behaviour changes
- RBAC/ServiceAccount changes
- Plugin installation and initContainer changes
- Deployment securityContext/probes changes

This must not be treated as a substitute for application upgrade notes.

---

## Step 5: Plugin Compatibility Check (CRITICAL)

Identify which plugins are in use (e.g., AWS plugin, CSI plugin) and verify:
- Plugin versions are compatible with `{new_app_version}`
- Any plugin-specific breaking changes or new requirements
- Any changes to required AWS permissions or configuration

If plugin compatibility is unclear, mark as requires human review and do not guess.

---

## Step 6: CRD Strategy Check (CRITICAL)

Determine:
- Whether Velero CRDs are installed via Helm, Terraform, or another mechanism
- Whether CRDs must be upgraded before the Velero deployment
- Whether a staged rollout is required

For CRD changes:
- Identify schema changes and deprecated fields
- Identify conversion or validation behaviour changes
- Document apply order and rollback considerations

---

## Step 7: Extract Breaking and Behavioural Changes

From all sources, identify changes affecting:
- BackupStorageLocation / VolumeSnapshotLocation configuration
- Backup/Restore hooks, timeouts, default behaviour
- Snapshot behaviour (CSI vs cloud provider snapshots, if used)
- Resource discovery and include/exclude semantics
- Schedule behaviour and retention
- Authentication/IRSA behaviour and AWS provider configuration

Create a checklist distinguishing:
- Mandatory changes
- Optional but recommended changes
- No action required items

---

## Step 8: Values and Resource Compatibility Review

Review existing configuration for:
- Helm values (configuration, initContainers/plugins, snapshots, metrics)
- BSL/VSL resources
- Schedules, Backups, Restores
- Credentials/IRSA and bucket/KMS configuration

Flag any items requiring updates due to:
- Deprecated fields
- Behaviour changes that could alter backup contents or restore outcomes
- Plugin changes

If unclear, mark as requires human review and do not guess.

---

## Step 9: Update Configuration Files

Apply required changes in the following locations:

1. Update the Velero Helm chart version in:
   terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

   This change must be applied to **all environment blocks**:
   - development
   - test
   - production

2. Update Helm values as required to match `{new_app_version}` and chart schema.

3. Update any Velero resources (BSL/VSL/Schedule/Backup/Restore) if required by CRD or behaviour changes.

4. Update plugin versions and configuration if required.

---

## Step 10: Push Changes (Branching and Git Workflow)

Before committing any changes, create and check out a new timestamped branch using the following convention:

git checkout -b copilot/chart-update-$(date +%Y%m%d-%H%M)

Commit changes with clear, descriptive messages referencing the chart and app version upgrade.

After committing, push the branch to the remote repository:

git push origin copilot/chart-update-$(date +%Y%m%d-%H%M)

Do not reuse or amend existing branches.

---

## Step 11: Create Pull Request

Create a pull request with the following requirements:

- Title: :copilot: chore(helm chart): update velero chart version in `{environment}`
- Labels: Add the `copilot` label
- Body: Use the structured format below. Do not include risk assessment, post-upgrade validation, or file change listings.

### Pull Request Body Template

### Version Changes

| Component | Previous | New |
|-----------|----------|-----|
| Helm Chart (development) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (test) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (production) | `{old_chart_version}` | `{new_chart_version}` |
| Velero | `{old_app_version}` | `{new_app_version}` |
| Velero plugins | `{old_plugin_versions}` | `{new_plugin_versions}` |

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
- BSL/VSL configuration
- Schedules/Backups/Restores
- Plugin versions and configuration

| Area | Status |
|------|--------|
| `{area}` | `{status}` |

Conclude clearly whether configuration, resource, or plugin changes were required.

---

At the very end of the PR body, append the following line verbatim:

:copilot: This PR was generated in association with copilot

---

## Step 12: Produce a Report Summary

Provide a concise narrative summary that aligns exactly with the pull request body content and tables.

---

## Constraints and Rules

- Do not assume Velero upgrades are safe
- Do not skip intermediate application versions
- Kubernetes compatibility must be validated first
- Plugin compatibility must be reviewed explicitly
- CRD sequencing must be explicitly reviewed
- Do not include risk assessments or post-upgrade validation sections
- If documentation is unclear, mark the item as requires human review

---

## Output Format

Produce:
1. A structured upgrade checklist
2. A breaking changes table
3. A pull-request-ready body using the template above

Do not apply changes automatically.
