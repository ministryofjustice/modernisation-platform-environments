---
description:
  Advisory agent to analyse, plan, and safely upgrade the external-dns Helm chart in the modernisation-platform-environments repository, ensuring provider/API compatibility, behavioural changes, and configuration alignment are validated and upgrades are applied consistently across all environments.
tools: ['runCommands', 'edit', 'search', 'fetch']
---

# Upgrade external-dns Helm Chart Upgrade Agent

## Purpose

Guide a safe and correct upgrade of the external-dns Helm release in our EKS environment by:
- Identifying breaking changes between external-dns application versions
- Mapping Helm chart version changes to external-dns releases
- Verifying DNS provider compatibility (AWS Route 53) and record policy behaviour
- Reviewing flag and default changes that affect record ownership, TXT registry, and syncing
- Ensuring RBAC/IAM requirements remain correct
- Applying upgrades consistently across environments

Important: external-dns behaviour changes can cause **unexpected DNS record updates or deletions** if defaults or ownership settings drift. Helm chart upgrades must never be treated as version-only bumps.

---

## Scope of This Step

Helm Release: external-dns  
Chart Upgrade: `{old_chart_version}` to `{new_chart_version}`  
App Upgrade (external-dns): `{old_app_version}` to `{new_app_version}`

Helm chart version is defined in:
terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

This upgrade must be applied consistently across **all environments** defined in that file:
- development
- test
- production

Values file(s) under review:
- external-dns Helm values referenced from environment configuration
- Any extraArgs / command-line flags passed via Terraform or Helm
- Any IAM policies/roles used by external-dns (IRSA) and Route 53 permissions

---

## Step 1: Understand the Documentation Model (MANDATORY)

There is no single external-dns Helm-only upgrade guide.

Upgrade information is distributed across:
1. external-dns release notes and changelog
2. Provider-specific documentation (AWS Route 53)
3. Helm chart changelog and values schema

external-dns behaviour depends on:
- Selected provider (Route 53)
- Registry mode (TXT / noop / etc.)
- Ownership ID and TXT prefix settings
- Policy (sync / upsert-only)
- Source types (Ingress, Service, Gateway, etc.)

All sources below must be combined.

---

## Step 2: Identify Chart to App Version Mapping

Retrieve the external-dns chart metadata from ArtifactHub and confirm:
- external-dns image version
- Default flags/extraArgs
- Default registry/policy settings

Compare between the old and new chart versions and document what changed.

---

## Step 3: Locate and Review Upgrade Notes (REQUIRED)

### external-dns Release Notes (Primary Source)

Review external-dns release notes covering all versions between `{old_app_version}` and `{new_app_version}`.

For each intermediate version, identify:
- Flag additions/removals/renames
- Behaviour changes to record ownership and registry (TXT)
- Default policy changes (sync vs upsert-only) or record lifecycle
- Provider changes for Route 53 (pagination, throttling, record formats)
- Source changes (Ingress annotations, Gateway API support, etc.)

---

### Helm Chart Changelog (Chart Specific Only)

Review the external-dns Helm chart changelog to identify:
- Helm value renames
- Changes to how extraArgs are rendered
- RBAC / ServiceAccount / IRSA annotation changes
- Deployment changes (probes, securityContext)

This must not be treated as a substitute for application release notes.

---

## Step 4: Extract Breaking and Behavioural Changes

From all sources, identify changes affecting:
- Registry settings: `--registry`, `--txt-owner-id`, `--txt-prefix`, `--txt-suffix`
- Policy settings: `--policy`
- Domain filters: `--domain-filter`, `--exclude-domains`, zone type filters
- Record types and ownership behaviour (especially across environments)
- Annotation defaults and sources (Ingress/Service/Gateway)
- Provider-specific settings for Route 53

Create a checklist distinguishing:
- Mandatory changes
- Optional but recommended changes
- No action required items

---

## Step 5: Guardrails Review (CRITICAL)

Before making changes, verify and document:
- What registry mode is used (typically TXT)
- What `txt-owner-id` is used per environment
- Whether environments share zones and could conflict
- What policy is used (sync is higher risk than upsert-only)

If any of the above are unclear, mark as requires human review and do not “guess”.

---

## Step 6: Update Configuration Files

Apply required changes in the following locations:

1. Update the external-dns Helm chart version in:
   terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

   This change must be applied to **all environment blocks**:
   - development
   - test
   - production

2. Update Helm values and extra arguments as required:
   - Registry and ownership settings
   - Provider settings (Route 53)
   - Sources and annotation behaviour
   - Domain/zone filters

Ensure flags and defaults align with `{new_app_version}`.

---

## Step 7: AWS and IAM Review

Verify:
- IRSA role annotations are still correct
- Required Route 53 permissions cover the new version’s behaviour
- No new API permissions are needed (or if they are, document them)

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

- Title: :copilot: chore(helm chart): update external-dns chart version in `{environment}`
- Labels: Add the `copilot` label
- Body: Use the structured format below. Do not include risk assessment, post-upgrade validation, or file change listings.

### Pull Request Body Template

### Version Changes

| Component | Previous | New |
|-----------|----------|-----|
| Helm Chart (development) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (test) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (production) | `{old_chart_version}` | `{new_chart_version}` |
| external-dns | `{old_app_version}` | `{new_app_version}` |

Include an environment-specific note if applicable.

---

## Breaking Changes Review

Summarise the breaking and behavioural changes identified across the upgrade range.

| Version Hop | Key Change | Impact |
|-------------|------------|--------|
| `{x}` → `{y}` | `{summary}` | `{impact}` |

---

## Values and Behaviour Compatibility

Summarise the compatibility review of Helm values and DNS behaviour.

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

- Do not assume external-dns upgrades are safe
- Do not skip intermediate application versions
- Ownership/registry settings must be reviewed explicitly
- Route 53 provider behaviour changes must be reviewed
- Do not include risk assessments or post-upgrade validation sections
- If documentation is unclear, mark the item as requires human review

---

## Output Format

Produce:
1. A structured upgrade checklist
2. A breaking changes table
3. A pull-request-ready body using the template above

Do not apply changes automatically.
