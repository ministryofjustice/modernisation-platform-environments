# Grafana rotation: development recovery and rollout

## Scope and cause

Development was upgraded to Grafana 12.4 and rotator 1.2.2 without migrating the Lambda environment and IAM configuration. The new code requires `WORKSPACE_SERVICE_ACCOUNT_NAME`; the old configuration supplied `WORKSPACE_API_KEY_NAME`. Scheduled rotation failed at import and the stored credential expired, causing Terraform Grafana refresh to fail with HTTP 401. The AWS provider's null `role_arn` warning is separate.

This fix changes only development's rotation mode. Production retains its legacy API-key variable, permissions, and image version. Verify deployed versions before recovery; source configuration is not proof of what is running.

## Required configuration

Development uses the existing `aws_grafana_workspace_service_account.automation` name, workspace ID, and `grafana/api-key` secret. Its Lambda execution role needs these actions on the intended workspace ARN:

- `grafana:ListWorkspaceServiceAccounts`
- `grafana:ListWorkspaceServiceAccountTokens`
- `grafana:CreateWorkspaceServiceAccountToken`
- `grafana:DeleteWorkspaceServiceAccountToken`

Retain `secretsmanager:UpdateSecret` on the existing secret ARN. Verify customer-managed KMS/key-policy requirements separately if applicable. Deployment/operator permissions to update the Lambda and its role are separate from these runtime permissions.

The secret name and Grafana provider do not change: the raw service-account token is the provider's authentication string. Production must retain its legacy configuration until a separately reviewed migration.

## Before merging

These changes were authored without executing Terraform in chat. Run formatting and validation, then inspect plans for both workspaces. Confirm the patch causes no production rotator changes to environment variables, IAM policy, or image. Review unrelated drift separately. Ensure development's service account exists with sufficient Grafana permissions (currently defined as ADMIN).

## Recover an expired credential

A full plan cannot finish until Grafana authentication works. Do not disable refresh or apply the old partial plan to bypass this.

1. Obtain approval and confirm account `observability-platform-development`, region `eu-west-2`, workspace, Lambda, and secret identifiers.
2. Record deployed image digest, non-secret configuration, execution role, EventBridge target, and secret-version metadata. Never upload token values to logs, tickets, or Git.
3. Inventory service-account tokens and consumers. Coordinate concurrent Terraform applies and credential writers. If necessary pause only the development schedule, with a named owner and deadline. Pausing does not cancel queued/running invocations or retries.
4. Choose one controlled recovery path:
   - **Repair the current rotator:** correct the development Lambda environment and execution-role policy to match this IaC patch, preserving all unrelated settings. Environment updates may replace the entire variable map: retain `WORKSPACE_ID` and `SECRET_ID`. Wait for configuration completion and IAM propagation, then invoke once. **The investigated 1.2.2 and 1.2.3 images delete ALL tokens on the account. Only use this path if every affected consumer has been accounted for and deletion is explicitly accepted.**
   - **Bootstrap without the old rotator:** use an approved administrative process to create a bounded-lifetime service-account token and securely publish its raw value as the current `grafana/api-key` secret. Do not delete unrelated tokens. Prevent the old destructive implementation from running until replacement or explicit acceptance. Do not pass secrets as command-line literals, enable shell tracing, or print them.
5. For a Lambda invocation, inspect `FunctionError`, handler result, and logs. Acceptance by the invocation API is not proof of successful execution.
6. Inspect `AWSCURRENT` metadata without displaying its value. Run a fresh full Terraform plan to verify authenticated Grafana reads. Changed secret metadata alone does not prove the token works.
7. Review all proposed changes, including unrelated group removals and replacements, before an approved apply. Recheck Lambda environment and IAM settings after reconciliation.
8. Restore scheduled rotation only when the deployed implementation is safe to run. Confirm both the controlled invocation and the next scheduled rotation succeed before declaring recovery complete.

Manual recovery changes must be recorded and reconciled through this branch. Do not overwrite the service-account mode with old IaC. The safe-image update is a separate release/deployment step, not accomplished by this commit.

## Deploy the safer rotator

See `docs/rollout-and-recovery.md` in `ministryofjustice/observability-platform-grafana-api-key-rotator`.

1. Require passing unit, container-structure, and code-quality checks on the reviewed rotator code.
2. Release under a new approved tag; verify image publication, signature verification, and digest. Do not reuse a tag or guess an unpublished version.
3. Update only development's `grafana_api_key_rotator_version` to that published tag in a follow-up change. No image version is changed by this configuration fix.
4. Review/apply a fresh plan, verify the Lambda's resolved image digest, and perform one controlled rotation plus authenticated Grafana read.
5. Coordinate queued/running old-version invocations: deployment does not change an invocation already running. Observe the next scheduled rotation before considering production migration.

## Failure handling and monitoring

Never blindly restore an older secret version: it may be expired or revoked. Do not assume legacy rotator 1.0.10 is compatible with development's upgraded Grafana. Rolling back to 1.2.2/1.2.3 restores destructive deletion. Preserve usable credentials while repairing rotation, but bound any pause by their expiry.

Monitor Lambda failures (including initialization), EventBridge delivery failures, safer-rotator cleanup warnings, and absence of confirmed successful rotation. Cleanup can warn while publication succeeds, so Lambda Errors alone is insufficient. This commit does not provision alarms: assign that follow-up explicitly. The investigated schedule is Monday 02:00 UTC and default TTL is 14 days; choose alerts that allow recovery before expiry.

Completion: development authentication and scheduled rotation work, runtime and IaC agree, production is unchanged, and temporary changes/monitoring follow-ups are recorded.
