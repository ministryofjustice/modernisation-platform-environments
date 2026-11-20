# PDC token rotation handoff

Tracks [ministryofjustice/observability-platform#338](https://github.com/ministryofjustice/observability-platform/issues/338).

## Current safe boundary

Rotation is **not enabled**. Terraform still creates the initial token and writes
the plain token to the existing central secret. Both environments leave
`pdc_token_rotator = null`, so no Lambda, journal, IAM policy, alarms, rotation invocation
or expiry is deployed by this preparation. Existing tokens remain valid, and
new opted-in accounts retain the current bootstrap behaviour.
The secret names, per-account networks, KMS policies and tenant read permissions
are unchanged.

The token and secret-version resources now block destruction, including
replacement and account removal. This is intentional: replacing a Grafana token
revokes it before ECS agents can read its replacement. Offboarding therefore
requires an explicitly reviewed change to these protections.

Terraform still holds token values in state until the handoff below. Do not claim
that adding metadata enables rotation or removes credentials from state.

## Rotation contract

`grafana-cloud-pdc-rotation.tf` defines the rotation interval and grace period
together as code locals. `local.pdc_rotation_rules` supplies the future Secrets
Manager `rotation_rules`; `local.pdc_token_lifetime_days` derives the new token's
expiry period from the same settings. These are not module inputs or outputs.

Each central `grafana-cloud/pdc/<account ID>` secret carries these tags. They are
an integration contract for the future rotator, not existing Lambda behaviour:

| Tag | Meaning |
| --- | --- |
| `pdc:tenant-account-id` | Tenant AWS account containing the agents |
| `pdc:access-policy-id` | Existing Grafana PDC network/access policy ID |
| `pdc:region` | Grafana Cloud region, not the AWS region |
| `pdc:stack-id` | Grafana Cloud stack ID |
| `pdc:token-ttl-seconds` | Interval plus grace, converted to seconds; expiry offset from issuance |
| `pdc:ecs-region` | ECS region; current pilot accounts use the central account's region |
| `pdc:ecs-cluster` | `grafana-pdc-agent` |
| `pdc:ecs-service` | `grafana-pdc-agent` |
| `pdc:metrics-tunnel-id` | Observed `tunnelID` label for this network in the usage data source; added only when configured |

The Lambda must read and validate these settings rather than hard-code another
cadence. Shortening an interval or changing expiry settings must not change the
expiry of the currently deployed token. If PDC is enabled in a different AWS
region, extend the account configuration and region metadata before onboarding.

The confirmed role contract is
`arn:aws:iam::<observability-account-id>:role/grafana-pdc-token-rotator`, at path
`/`, assuming
`arn:aws:iam::<tenant-account-id>:role/grafana-pdc-agent-restarter`. The runtime
derives the tenant role ARN from the account ID.

## Dormant Lambda deployment

The dedicated repository is
`ministryofjustice/observability-platform-grafana-pdc-token-rotator`. An image
release is not yet available. There is deliberately no guessed ECR URI or
placeholder version that a deployment might try to pull.

Once the dependencies below are met, `pdc_token_rotator` in the relevant
environment configuration can be set to an object containing:

| Field | Required value |
| --- | --- |
| `image_uri` | Actual released ECR image URI, preferably pinned by digest |
| `credential_secret_arn` | Dedicated Cloud API credential secret in this account/region |
| `credential_kms_key_arn` | Customer-managed KMS key encrypting that credential |
| `stack_query_credential_secret_arn` | Separate read-only stack service-account token secret in this account/region |
| `stack_query_credential_kms_key_arn` | Customer-managed KMS key encrypting the stack query credential |
| `metrics_tunnel_ids` | Map of account name to verified `tunnelID` label; one distinct value per opted-in account |
| `failure_topic_arn` | Operational SNS topic in this account/region |

This deploys the Lambda using the existing module/version, exact execution role
name, scoped IAM permissions, per-secret Secrets Manager invocation permissions,
Lambda error alarm and a Secrets Manager `RotationFailed` EventBridge target.
Initial reserved concurrency is one to serialise rotation invocations.
The Lambda uses a central DynamoDB table (`ROTATION_STATE_TABLE_NAME`) to resume
interrupted rotations. The journal stores progress and version/deployment
identifiers, not credentials. It has point-in-time recovery and deletion
protection; retain it across runtime changes and review retention before
activation. Do not remove it while any rotation could still be retried.
The topic's owning configuration must permit EventBridge `sns:Publish` from the
rule ARN (and CloudWatch alarm delivery); this configuration does not overwrite
an existing topic policy. Confirm its subscriptions and delivery.

Store each credential as a plain token. Lambda receives only the management and
stack query secret ARNs through `GRAFANA_API_CREDENTIAL_SECRET_ARN` and
`GRAFANA_STACK_QUERY_CREDENTIAL_SECRET_ARN`. Provision the query token separately
for a dedicated Viewer/read-only service account in the target stack. Do not
generate or read its value in Terraform, where it could enter state. Use the
stack URL passed in `GRAFANA_STACK_URL` and confirm during the pilot that
`GRAFANA_USAGE_DATASOURCE_UID` (`grafanacloud-usage`) resolves to the usage data
source and that the credential can query it. Cadence comes from secret metadata.
Record the observed `tunnelID` in `metrics_tunnel_ids`; do not assume it equals
the access policy ID. Confirm scrape and ingestion lag before choosing the
runtime's metric freshness, settling and stability settings.
Setting this object does **not** enable secret rotation or perform state handoff.

## Dependencies before activation

- A released rotator image and approved ECR repository/access. The dormant wiring
  follows the existing `grafana_api_key_rotator` deployment pattern (Lambda module
  `7.20.1`, container image reference in the environment configuration).
- A dedicated Grafana credential, its central secret ARN, required KMS access and
  an agreed credential rotation process. Confirm the
  `accesspolicies:read`/`write` scope and organisation-wide implications;
  do not silently reuse Terraform's credential. The initial runtime contract
  uses expiry rather than token deletion, so do not grant deletion scope until
  its cleanup implementation is reviewed.
- A tenant module release with `grafana-pdc-agent-restarter`, trusted only by the
  agreed central Lambda execution role. The dormant wiring grants that execution
  role `sts:AssumeRole` only on opted-in accounts' restarter roles, with secret
  read/write/staging and KMS permissions restricted to this environment's PDC
  secrets and keys.
- A proven token acceptance check and a reconnection signal attributable to the
  **replacement** agents. The rotator queries
  `grafanacloud_grafana_pdc_connected_agents` for the network's `tunnelID`.
  Verify during the pilot that the metric is fresh enough and measures the
  replacement deployment rather than still-connected old agents.
  ECS service stability alone is insufficient: an
  unauthenticated agent can stay running and retrying. Agree any additional log
  or metric permissions before extending the tenant role.
- A bounded restart/verification/rollback sequence within Lambda's 15-minute
  limit, including retry idempotency and concurrent invocation handling.
- An operational notification destination. Wire Lambda error alarms and Secrets
  Manager `RotationFailed` events to it before activation, and verify delivery.

The future Secrets Manager invocation permission must restrict
`secretsmanager.amazonaws.com` to this AWS account and these secrets. Configure
each existing secret with `rotate_immediately = true` only after deploying and
verifying that permission, the runtime and alerts. Set
`rotation_rules.automatically_after_days` from
`local.pdc_rotation_rules.automatically_after_days`; do not add a separate
EventBridge schedule.

## Non-destructive Terraform state handoff

Do not perform this handoff while the rotator is unavailable. Otherwise new
accounts would receive empty secrets, with no mechanism to issue their tokens.
Do not use a normal Terraform destroy or replace, or add `expires_at` to the
Terraform-managed live token.

In the reviewed activation change, replace **both entire resource blocks** below
with these `removed` blocks. Keep networks, secrets, keys and policies managed:

```hcl
removed {
  from = grafana_cloud_private_data_source_connect_network_token.account

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_secretsmanager_secret_version.gc_pdc_token

  lifecycle {
    destroy = false
  }
}
```

These addresses cover all `for_each` instances. The root's Terraform constraint
(`~> 1.10`) supports non-destructive `removed` blocks. Remove the secret's
`CKV2_AWS_57` skip only when real rotation is configured.

1. Securely record each network's existing token ID and current secret version ID
   for later cleanup, without printing token values. Treat saved plans and state
   backups as credentials.
2. Plan each environment separately. Confirm the two resources are **forgotten,
   not destroyed**, with no network, secret, key or token replacement. Reject any
   unexpected change. The new rotator must also support empty secrets for new
   accounts.
3. Apply only through the usual reviewed deployment process. Forgetting the
   resources must not revoke the live token or change `AWSCURRENT`. Historical
   state versions, backups and plans still contain the old token: handle them
   under the existing retention/access policy.
4. Pilot in development. Confirm a query through PDC before rotation, issue
   `AWSPENDING`, test it and the tenant role, promote it and restart agents.
   Preserve the old token and `AWSPREVIOUS` until replacement agents demonstrably
   reconnect. If verification fails, restore the old current version, redeploy
   and confirm reconnection, raise an alert and fail the rotation. Do not delete
   either recovery token on failure.
5. After a successful rotation and the grace period, delete the original
   Terraform-created token by its recorded ID. It has no expiry, so waiting for
   the new token's expiry is not a cleanup strategy. Never select tokens for
   deletion by name alone. Subsequent cleanup must protect `AWSCURRENT` and
   `AWSPREVIOUS`.

The automatic expiry of newly issued tokens is a hard limit: a failed rotation
must alert with enough time for recovery before the current token expires.
Test a fresh account, scheduled and forced rotation, retries, reconnection
failure/rollback and cleanup before production activation. No live rotation or
infrastructure apply is part of this preparatory change.

## Focused validation

From the repository root:

```shell
python3 terraform/environments/observability-platform/tests/run_pdc_rotation_tests.py
```

The runner copies the real PDC files and their provider constraints into a
temporary root, initialises without a backend, validates, then runs Terraform
tests with mocked providers. Registry/module downloads require network access;
no AWS or Grafana credentials, live backend or real API calls are used. It checks
per-account metadata, expiry/schedule consistency, opt-in and empty-account
behaviour, dormant deployment, scoped runtime permissions and failure alert
wiring. A separate negative test confirms that token destruction protection
rejects disabling accounts. It is not a full environment plan or an end-to-end
rotation test.
