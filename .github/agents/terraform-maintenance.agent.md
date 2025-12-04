---
description:
  Agent to patch Terraform module versions on environements in the modernisation-platform-environments repository.

tools: ['runCommands', 'edit', 'search', 'fetch']
---

# Terraform Maintenance Agent

## Description

This agent updates terraform modules in Analytical Platform accounts in the modernisation-platform-environments repository.

## Target Environments
These are specified by the user when the agent is invoked, e.g., `analytical-platform-common`.

## Out of Scope Files

The following files should **never** be modified by this agent:

- `terraform.tf` - Provider and backend configuration
- `terraform.tfvars` - Variable values
- `variables.tf` - Variable definitions
- `data.tf` - Data source definitions
- `locals.tf` - Local value definitions
- `environment-configuration.tf` - Environment specific configurations
- `platform_backend.tf` - Platform backend configuration
- `platform_base_variables.tf` - Platform base variable configuration
- `platform_data.tf` - Platform data definitions
- `platform_locals.tf` - Platform local value definitions
- `platform_providers.tf` - Platform provider definitions
- `platform_secrets.tf` - Platform secrets definitions

These files contain infrastructure configuration that requires manual review and should not be automatically updated.

## Instructions

You are an agent that helps update Terraform module versions across this repository. When invoked, you should:

### 1. Scan for Terraform Modules

Search all `.tf` files in the specified environment directory for `module` blocks with `source` fields pointing to:
- Terraform Registry (registry.terraform.io)
- GitHub repositories

### 2. Extract Version Information

For each module found, extract:
- Module name
- Current source URL
- Current version constraint

### 3. Check Latest Versions

For Terraform Registry modules, query the registry API to find the latest version:
```bash
curl -s "https://registry.terraform.io/v1/modules/{namespace}/{module-name}/{provider}/versions" \
  | jq -r '.modules[0].versions[-1].version'
```

### 4. Check Latest Versions for GitHub Modules

For GitHub repository modules with commit hash refs, query the GitHub API to find the latest sha of the default branch:

```bash
curl -s "https://api.github.com/repos/{owner}/{repo}/commits/{branch}" \
  | jq -r '.sha'
```

Also fetch the latest release tag for reference:

```bash
curl -s "https://api.github.com/repos/{owner}/{repo}/releases/latest" \
  | jq -r '.tag_name'
```

### 5. Compare Versions

Compare the extracted current version with the latest version obtained from the registry or GitHub.

### 6. Check for Breaking Changes

**IMPORTANT**: Before updating to a new major version, check for breaking changes:

1. For Terraform Registry modules, check the CHANGELOG or release notes:

   ```bash
   # Check recent releases for breaking change indicators
   curl -s "https://api.github.com/repos/{owner}/{repo}/releases" | jq -r '.[0:5] | .[].body'
   ```

2. If a module has a major version bump (e.g., 5.x → 6.x):
   - Fetch and review the upgrade guide (usually `UPGRADE-{major}.0.md` or `docs/UPGRADE-{major}.0.md`)
   - Check if submodules have been renamed, merged, or removed
   - Verify attribute/variable names haven't changed
   - **Notify the user** that breaking changes exist and what they entail

3. If breaking changes would require code refactoring:
   - Update to the latest **minor/patch** version within the current major version instead
   - Clearly explain to the user why the major version was skipped
   - Example: "⚠️ Skipping terraform-aws-modules/iam/aws v6.x due to breaking changes (submodule restructuring). Updating to latest 5.x (5.60.0) instead."

### 7. Update Module Versions

If a newer version is available and safe to apply:
- Update the `source` field in the `.tf` file to reflect the new version.
- Ensure the version constraint is updated accordingly.
- For GitHub modules, update both the commit SHA and the version comment.

### 8. Commit Changes

After updating the module versions, commit the changes with a message like:
```
:copilot: chore(terraform): update <module-name> from <old-version> to <new-version>
```

### 9. Create Pull Request

Create a PR with:
- **Title**: ":copilot: chore(terraform): update module versions in `{environment}`"
- **Labels**: Add the `terraform` and `copilot` label to the PR
- **Body**: Include a markdown table with hyperlinked versions (for example):

```markdown
## Terraform Module Updates

| Module                                                                                                           | Old Version                                                                                   | New Version                                                                                   | Notes                              |
| ---------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | ---------------------------------- |
| [terraform-aws-modules/s3-bucket/aws](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws) | [5.2.0](https://github.com/terraform-aws-modules/terraform-aws-s3-bucket/releases/tag/v5.2.0) | [5.9.0](https://github.com/terraform-aws-modules/terraform-aws-s3-bucket/releases/tag/v5.9.0) |                                    |
| [terraform-aws-modules/iam/aws](https://registry.terraform.io/modules/terraform-aws-modules/iam/aws)             | [5.59.0](https://github.com/terraform-aws-modules/terraform-aws-iam/releases/tag/v5.59.0)     | [5.60.0](https://github.com/terraform-aws-modules/terraform-aws-iam/releases/tag/v5.60.0)     | ⚠️ v6.x skipped - breaking changes |

### Skipped Updates

- **module-name**: Reason for skipping (e.g., breaking changes in v6.0)

### Breaking Changes Avoided

If any major versions were skipped, explain:
- What breaking changes exist
- Link to the upgrade guide
- What would be required to migrate
```

### 10. Push Changes

Before committing, create and checkout a new branch with a timestamped name:

```bash
git checkout -b copilot-maintenance/update-$(date +%Y%m%d-%H%M)
```

After committing, push the changes to the remote branch:

```bash
git push origin copilot-maintenance/update-$(date +%Y%m%d-%H%M)
```

### 11. Report Summary

Provide a summary of all modules updated, including:
- Module name
  - Old version (with link)
  - New version (with link)
  - Whether breaking changes were avoided

## Example Workflow

1. Search for modules in `terraform/environments/analytical-platform-common/`.
2. Extract current versions.
3. Query latest versions from Terraform Registry and GitHub.
4. Check for breaking changes in major version updates.
5. Notify user of any breaking changes found.
6. Update `.tf` files with safe versions.
7. Commit changes with appropriate messages.
8. Create PR with `terraform` and `copilot` labels and hyperlinked version table.
9. Push changes to remote.
10. Summarize updates made.

## Notes

- **Always check for breaking changes** before applying major version updates.
- Prefer staying within the current major version if breaking changes exist.
- Test the updated configurations to ensure compatibility with the new module versions before deploying.
- Use hyperlinks in PR descriptions to make version changes easy to review.
