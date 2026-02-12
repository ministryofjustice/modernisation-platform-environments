---
description:
  This agent manages dependabot PRs for the Analytical Platform ingestion repositories,
  merges eligible PRs, and creates issues to track release creation.

tools: ['githubPullRequest', 'githubIssue', 'githubSearch', 'edit', 'fetch']
---

# Analytical Platform Ingestion Dependabot Agent

This agent automates the management of dependabot PRs across the Analytical Platform ingestion repositories.

## Target Repositories

- [analytical-platform-ingestion-transfer](https://github.com/ministryofjustice/analytical-platform-ingestion-transfer)
- [analytical-platform-ingestion-scan](https://github.com/ministryofjustice/analytical-platform-ingestion-scan)
- [analytical-platform-ingestion-notify](https://github.com/ministryofjustice/analytical-platform-ingestion-notify)

## Workflow

When invoked, this agent should perform the following steps:

### Step 1: Gather Current State

For each of the three target repositories:

1. Search for open pull requests authored by `app/dependabot`
2. Get the latest release to determine the current version
3. For each open dependabot PR, check:
   - Whether all CI checks are passing
   - Whether the version bump is a **major** version bump (these should be skipped)

### Step 2: Merge Eligible PRs

For each repository, merge dependabot PRs that meet **all** of the following criteria:

- All CI status checks are passing
- The version bump is **not** a major version bump
- Use **squash** merge method

**Note on major version detection:**

- A major bump is when the first non-zero version number increases (e.g., `1.2.3` → `2.0.0`, or `0.2.3` → `0.3.0`, or `0.0.3` → `0.1.0`)
- For calendar-versioned packages like `black` (e.g., `25.12.0` → `26.1.0`), the year change is considered a major bump
- Check the PR title which typically contains `from X.Y.Z to A.B.C` to determine the bump type

### Step 3: Create Release Tracking Issues

After merging PRs, for each repository where PRs were merged, create an issue to track the release:

1. Determine the next version by incrementing the **patch** version of the current latest release:
   - `analytical-platform-ingestion-transfer`: Current version format is `0.0.x`
   - `analytical-platform-ingestion-scan`: Current version format is `0.2.x`
   - `analytical-platform-ingestion-notify`: Current version format is `0.0.x`

2. Create an issue in the respective repository with:
   - Title: `Release <next-version>`
   - Body:
     - The suggested next version number
     - List of merged dependabot PRs included in this release
     - Instructions to create the release via the GitHub UI or CLI

**Note:** Creating releases directly is not supported by the available tools. The issue serves as a reminder and tracking mechanism for manual release creation.

### Step 4: Report Summary

Provide a summary including:

1. **PRs Merged:** List of dependabot PRs that were successfully merged (with links)
2. **PRs Skipped:** List of PRs skipped due to:
   - Failing CI checks
   - Major version bumps
3. **Release Issues Created:** Links to the tracking issues for releases
4. **Next Steps:** Instructions for:
   - Creating the releases manually
   - Running this agent again after releases are created to update `environment-configuration.tf`

## Updating environment-configuration.tf

Once releases have been manually created, run this agent again or manually update:

- File: `terraform/environments/analytical-platform-ingestion/environment-configuration.tf`
- Variables to update in **both** `development` and `production` blocks:
  - `scan_image_version`
  - `transfer_image_version`
  - `notify_image_version`

Then create a pull request with:

- Branch name: `dependabot/ingestion-image-versions`
- Title: `Bump Analytical Platform Ingestion image versions`
- Body: Summary of version updates with links to the new releases

## Example Invocation

> @ingestion merge dependabot PRs

or

> @ingestion process dependabot updates

or

> @ingestion update environment-configuration.tf to versions: scan=0.2.3, transfer=0.0.25, notify=0.0.26

## Important Notes

- Always verify CI checks are green before merging
- Skip any PR that updates a major version - these require manual review
- If no PRs are eligible for merging in a repository, skip creating a release issue for that repository
- The agent cannot create releases directly - issues are created as tracking reminders
- Report a summary of actions taken at the end
