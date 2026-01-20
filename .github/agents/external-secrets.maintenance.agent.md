---
description:
  Advisory agent to analyse, plan, and safely upgrade the external-secrets Helm chart in the modernisation-platform-environments repository, ensuring CRD compatibility, provider/API behaviour changes, and configuration alignment are validated and upgrades are applied consistently across all environments.
tools: ['runCommands', 'edit', 'search', 'fetch']
---

# :copilot: GitHub Copilot Agent: Upgrade external-secrets Helm Chart (EKS)

## Purpose

Guide a safe and correct upgrade of the external-secrets Helm release in our EKS environment by:
- Identifying breaking changes between External Secrets Operator application versions
- Mapping Helm chart version changes to operator releases
- Verifying CRD compatibility and upgrade sequencing
- Reviewing provider behaviour changes (AWS Secrets Manager / SSM Parameter Store, if used)
- Ensuring configuration, RBAC, and service accounts remain correct
- Applying upgrades consistently across environments

Important: External Secrets Operator upgrades frequently include **CRD schema and API changes**. Helm chart upgrades must never be treated as version-only bumps.

---

## Scope of This Step

Helm Release: external-secrets  
Chart Upgrade: `{old_chart_version}` to `{new_chart_version}`  
App Upgrade (External Secrets Operator): `{old_app_version}` to `{new_app_version}`

Helm chart version is defined in:
terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

This upgrade must be applied consistently across **all environments** defined in that file:
- development
- test
- production

Values file(s) under review:
- external-secrets Helm values referenced from environment configuration
- Any SecretStore / ClusterSecretStore manifests managed via Terraform, Helm, or raw YAML
- Any ExternalSecret / PushSecret / ClusterExternalSecret (if used) resources

---

## Step 1: Understand the Documentation Model (MANDATORY)

There is no single external-secrets Helm-only upgrade guide.

Upgrade information is distributed across:
1. External Secrets Operator upgrade documentation and migration notes
2. External Secrets Operator GitHub releases
3. Helm chart changelog and values schema
4. Provider documentation (AWS Secrets Manager / SSM) where behaviour changed

External Secrets Operator owns:
- CRDs (ExternalSecret, SecretStore, ClusterSecretStore, and any optional resources)
- Reconciliation logic and refresh behaviour
- Provider client behaviour and auth modes

All sources below must be combined.

---

## Step 2: Identify Chart to App Version Mapping

Retrieve the external-secrets chart metadata from ArtifactHub and confirm:
- Operator image version
- Installed/managed CRDs and their versions
- Default flags and feature gates
- Any bundled webhook or metrics components

Compare between the old and new chart versions and document what changed.

---

## Step 3: Locate and Review Upgrade Notes (REQUIRED)

### External Secrets Operator Upgrade / Migration Notes (Primary Source)

Review upstream upgrade/migration documentation covering all versions between `{old_app_version}` and `{new_app_version}`.

For each intermediate version, identify:
- CRD schema changes and removals
- API field deprecations/renames
- Behaviour changes to refresh, templating, creationPolicy, deletionPolicy
- Provider auth changes (IRSA, STS, token sources)
- New defaults (e.g., decoding, conversion, templating engine changes)

---

### External Secrets Operator GitHub Releases (Version by Version)

Review all operator releases between the old and new versions.

Process:
- Start at `{old_app_version}` (exclusive)
- Read every minor release up to `{new_app_version}` (inclusive)
- Focus on:
  - breaking changes
  - CRD updates
  - behavioural changes to reconciliation
  - provider-specific fixes that may alter output or timing

Patch releases may be skipped unless explicitly marked as breaking.

---

### Helm Chart Changelog (Chart Specific Only)

Review the external-secrets Helm chart changelog to identify:
- Helm value renames or schema changes
- CRD installation toggles or behaviour changes
- RBAC/ServiceAccount changes
- Deployment securityContext/probes changes

This must not be treated as a substitute for application upgrade notes.

---

## Step 4: CRD Strategy Check (CRITICAL)

Determine:
- Whether CRDs are installed by Helm or managed externally
- Whether CRDs must be upgraded before upgrading the controller
- Whether the upgrade requires a staged rollout

For CRD changes:
- Identify new/removed fields and storage versions
- Identify conversion webhook requirements (if any)
- Document apply order and rollback considerations

---

## Step 5: Extract Breaking and Behavioural Changes

From all sources, identify changes affecting:
- CRDs: ExternalSecret, SecretStore, ClusterSecretStore (and optional CRDs if used)
- Templating behaviour and output formatting
- Refresh intervals and reconciliation timing
- Secret creationPolicy / deletionPolicy semantics
- Provider behaviour for AWS backends (rate limits, pagination, binary secret handling)
- RBAC and auth settings (IRSA annotations, token projection)

Create a checklist distinguishing:
- Mandatory changes
- Optional but recommended changes
- No action required items

---

## Step 6: Values and Resource Compatibility Review

Review existing configuration for:
- Helm values (controller args, webhook, metrics, leader election)
- SecretStore / ClusterSecretStore provider configs (AWS auth methods, region, role ARN usage)
- ExternalSecret definitions (dataFrom, template, target, metadata, decoding strategies)

Flag any resources that require updates due to:
- Deprecated fields
- Schema changes
- Behaviour changes that could alter secret contents or naming

If unclear, mark as requires human review and do not guess.

---

## Step 7: Update Configuration Files

Apply required changes in the following locations:

1. Update the external-secrets Helm chart version in:
   terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

   This change must be applied to **all environment blocks**:
   - development
   - test
   - production

2. Update Helm values as required to match `{new_app_version}` and chart schema.

3. Update any SecretStore / ClusterSecretStore / ExternalSecret manifests if required by CRD or behaviour changes.

---

## Step 8: AWS and IAM Review

Verify:
- IRSA role annotations are still correct for the service account
- AWS permissions remain sufficient for required providers (Secrets Manager / SSM)
- Any new API usage introduced by the new version is permitted

Document any required IAM updates.

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

- Title: :copilot: chore(helm chart): update external-secrets chart version in `{environment}`
- Labels: Add the `copilot` label
- Body: Use the structured format below. Do not include risk assessment, post-upgrade validation, or file change listings.

### Pull Request Body Template

### Version Changes

| Component | Previous | New |
|-----------|----------|-----|
| Helm Chart (development) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (test) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (production) | `{old_chart_version}` | `{new_chart_version}` |
| External Secrets Operator | `{old_app_version}` | `{new_app_version}` |

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
- SecretStore / ClusterSecretStore resources
- ExternalSecret resources

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

- Do not assume external-secrets upgrades are safe
- Do not skip intermediate application versions
- CRD strategy and sequencing must be reviewed explicitly
- Provider behaviour changes must be reviewed (AWS Secrets Manager / SSM)
- Do not include risk assessments or post-upgrade validation sections
- If documentation is unclear, mark the item as requires human review

---

## Output Format

Produce:
1. A structured upgrade checklist
2. A breaking changes table
3. A pull-request-ready body using the template above

Do not apply changes automatically.
