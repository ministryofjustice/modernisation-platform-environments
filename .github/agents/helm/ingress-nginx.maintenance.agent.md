---
description:
  Advisory agent to analyse, plan, and safely upgrade the ingress-nginx Helm chart in the modernisation-platform-environments repository, ensuring Kubernetes API compatibility, controller behaviour changes, security-related defaults, and configuration alignment are validated and upgrades are applied consistently across all environments.
tools: ['runCommands', 'edit', 'search', 'fetch']
---

# Upgrade ingress-nginx Helm Chart Upgrade Agent

## Purpose

Guide a safe and correct upgrade of the ingress-nginx Helm release in our EKS environment by:
- Identifying breaking changes between ingress-nginx controller application versions
- Mapping Helm chart version changes to ingress-nginx controller releases
- Verifying Kubernetes API and IngressClass compatibility
- Reviewing security-related default changes and configMap key changes
- Ensuring service settings, annotations, and admission webhook behaviour remain compatible
- Applying upgrades consistently across environments

Important: ingress-nginx upgrades can change default behaviour around **annotations, validation webhooks, TLS handling, and security hardening**. Helm chart upgrades must never be treated as version-only bumps.

---

## Scope of This Step

Helm Release: ingress-nginx  
Chart Upgrade: `{old_chart_version}` to `{new_chart_version}`  
App Upgrade (ingress-nginx controller): `{old_app_version}` to `{new_app_version}`

Helm chart version is defined in:
terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

This upgrade must be applied consistently across **all environments** defined in that file:
- development
- test
- production

Values file(s) under review:
- ingress-nginx Helm values referenced from environment configuration
- Any controller configMap overrides (keys and values)
- Any Ingress / IngressClass / Service annotations relied on by workloads

---

## Step 1: Understand the Documentation Model (MANDATORY)

There is no single ingress-nginx Helm-only upgrade guide.

Upgrade information is distributed across:
1. ingress-nginx controller release notes
2. Helm chart changelog/values schema
3. Kubernetes version/API compatibility notes
4. Any security advisories or default-hardening notes

ingress-nginx behaviour depends on:
- Kubernetes minor version and API availability
- IngressClass configuration and default class behaviour
- Admission webhook settings and annotation validation rules
- Controller configMap keys and defaults

All sources below must be combined.

---

## Step 2: Identify Chart to App Version Mapping

Retrieve the ingress-nginx chart metadata from ArtifactHub and confirm:
- Controller image version
- Admission webhook image/version (if separate)
- Default controller arguments and configMap defaults

Compare between the old and new chart versions and document what changed.

---

## Step 3: Validate Kubernetes Compatibility (CRITICAL)

Determine:
- The Kubernetes versions currently running in development, test, and production
- Whether `{new_app_version}` supports those versions

Verify:
- Supported Kubernetes minor versions for the controller
- Any API removals or required feature gates affecting Ingress, IngressClass, EndpointSlice, etc.

If the Kubernetes version is unsupported, do not proceed.

---

## Step 4: Locate and Review Upgrade Notes (REQUIRED)

### ingress-nginx Controller Release Notes (Primary Source)

Review ingress-nginx release notes covering all versions between `{old_app_version}` and `{new_app_version}`.

For each intermediate version, identify:
- Breaking changes and behavioural changes
- Annotation handling changes (added, removed, renamed, stricter validation)
- Changes to default TLS / SSL settings
- Changes to admission webhook behaviour and failurePolicy defaults
- Changes to controller arguments and default configMap values
- Security hardening changes (e.g., running as non-root, dropped capabilities, read-only FS defaults)

---

### Helm Chart Changelog (Chart Specific Only)

Review the ingress-nginx Helm chart changelog to identify:
- Helm value renames or schema changes
- Service/LoadBalancer defaults changes
- RBAC, ServiceAccount, PodSecurityContext changes
- Changes to webhook jobs, cert generation, or patching

This must not be treated as a substitute for application release notes.

---

## Step 5: Extract Breaking and Behavioural Changes

From all sources, identify changes affecting:
- IngressClass behaviour (default class selection, class names)
- Admission webhook validation (blocked annotations, stricter checks)
- ConfigMap keys (renames/deprecations) and their defaults
- Service annotations and LoadBalancer behaviour (NLB/ALB integrations, if used)
- HTTP/2, proxy protocol, real IP handling, forwarded headers
- Default security posture (PSA/PSP changes, capability drops)

Create a checklist distinguishing:
- Mandatory changes
- Optional but recommended changes
- No action required items

---

## Step 6: Values and Workload Compatibility Review (CRITICAL)

Review existing configuration for:
- Helm values for controller, service, autoscaling, metrics, webhook
- ConfigMap overrides (ensure keys still exist and semantics are unchanged)
- Ingress resources using annotations (ensure they are still accepted and behave as expected)
- IngressClass usage (ensure the intended controller still matches workload resources)

Flag any items requiring updates due to:
- Annotation validation changes
- Deprecated configMap keys
- Changes to default behaviour that could impact routing or security

If unclear, mark as requires human review and do not guess.

---

## Step 7: Update Configuration Files

Apply required changes in the following locations:

1. Update the ingress-nginx Helm chart version in:
   terraform/environments/analytical-platform-compute/cluster/environment-configuration.tf

   This change must be applied to **all environment blocks**:
   - development
   - test
   - production

2. Update Helm values and configMap overrides as required to match `{new_app_version}` and chart schema.

3. Update Ingress/IngressClass conventions only if required by upstream breaking changes (prefer avoiding behaviour changes unless necessary).

---

## Step 8: AWS and LoadBalancer Review

If using AWS LoadBalancers, verify:
- Service annotations still match the intended AWS LB type (NLB/ALB integration patterns)
- Any defaults affecting health checks, target type, proxy protocol, or preserveClientIP
- No new permissions or controller args are required

Document any required changes.

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

- Title: :copilot: chore(helm chart): update ingress-nginx chart version in `{environment}`
- Labels: Add the `copilot` label
- Body: Use the structured format below. Do not include risk assessment, post-upgrade validation, or file change listings.

### Pull Request Body Template

### Version Changes

| Component | Previous | New |
|-----------|----------|-----|
| Helm Chart (development) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (test) | `{old_chart_version}` | `{new_chart_version}` |
| Helm Chart (production) | `{old_chart_version}` | `{new_chart_version}` |
| ingress-nginx controller | `{old_app_version}` | `{new_app_version}` |

Include an environment-specific note if applicable.

---

## Breaking Changes Review

Summarise the breaking and behavioural changes identified across the upgrade range.

| Version Hop | Key Change | Impact |
|-------------|------------|--------|
| `{x}` → `{y}` | `{summary}` | `{impact}` |

---

## Values and Workload Compatibility

Summarise the compatibility review of:
- Helm values and configMap overrides
- Ingress / IngressClass usage
- Admission webhook behaviour

| Area | Status |
|------|--------|
| `{area}` | `{status}` |

Conclude clearly whether configuration changes were required.

---

At the very end of the PR body, append the following line verbatim:

:copilot: This PR was generated in association with copilot

---

## Step 11: Produce a Report Summary

Provide a concise narrative summary that aligns exactly with the pull request body content and tables.

---

## Constraints and Rules

- Do not assume ingress-nginx upgrades are safe
- Do not skip intermediate application versions
- Kubernetes compatibility must be validated first
- Annotation validation and configMap key changes must be reviewed explicitly
- Do not include risk assessments or post-upgrade validation sections
- If documentation is unclear, mark the item as requires human review

---

## Output Format

Produce:
1. A structured upgrade checklist
2. A breaking changes table
3. A pull-request-ready body using the template above

Do not apply changes automatically.
