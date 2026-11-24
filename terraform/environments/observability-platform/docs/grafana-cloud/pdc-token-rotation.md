# PDC token rotation handoff

Tracks [ministryofjustice/observability-platform#338](https://github.com/ministryofjustice/observability-platform/issues/338).

## Current safe boundary

Rotation is **not enabled**. Terraform still creates the initial token and writes
the plain token to the existing central secret. Development configures
`pdc_token_rotator` with the released image digest, deploying the Lambda, journal,
scoped IAM policy, alarms, empty credential secrets and token-less Grafana
identities. There is no rotation configuration, schedule or automatic invocation.
The Lambda remains dormant until a later reviewed pilot. Development also deploys
the failure SNS topic and Slack delivery. Production keeps
`pdc_token_rotator = null` and has no configured failure destination.
Existing tokens remain valid, and new opted-in
accounts retain the current bootstrap behaviour.
The secret names, per-account networks, KMS policies and tenant read permissions
are unchanged.

The token and secret-version resources now block destruction, including
replacement and account removal. This is intentional: replacing a Grafana token
revokes it before ECS agents can read its replacement. Offboarding therefore
requires an explicitly reviewed change to these protections.

Terraform still holds the existing tenant PDC token values in state until the
handoff below. The two new rotator credential values are never generated, read,
supplied as inputs or exposed as outputs by Terraform; it owns only their empty
secrets, keys and Grafana identities.

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
`ministryofjustice/observability-platform-grafana-pdc-token-rotator`. The
deployable image is released as `v0.1.0-alpha.2`, with digest
`sha256:e37d2133c21fae8db1345c653d181f33c85cd2e6ff4c2e4c86d2a0046d8c98fa`.
Development pins this digest, not the mutable tag. The earlier `v0.1.0-alpha.1`
artifact was a manifest list rejected by Lambda and is not deployable; do not use
its digest.

The development environment publishes the repository URI as an SSM `String`
parameter at
`/observability-platform/grafana-pdc-token-rotator/ecr-repository-uri`. It
constructs the URI in `eu-west-2` from the core shared services production
account ID in `environment_management` and the repository name. This parameter
is development-only. The Lambda image URI uses the same derived registry and
repository, followed by `@` and the configured digest. No account ID is hard-coded.

The environment configuration's optional `pdc_failure_alerts` object declares
the Slack destination; in development its `slack_channel_id` is
`C06ALD6LX55`. Terraform creates a KMS-encrypted SNS topic named
`grafana-pdc-rotation-failures-development` and an Amazon Q Developer (AWS
Chatbot) Slack channel configuration subscribed to it. CloudWatch alarm and
EventBridge publish permissions are restricted to their respective alert/rule
ARNs and this AWS account. This is notification-only: the channel configuration
uses the required CloudWatch read-only guardrail and has no managed policies
attached to its channel role. Production keeps `pdc_failure_alerts = null`.

Before applying the development Terraform configuration, complete this
one-time manual prerequisite: authorise the MoJ Slack workspace in **Amazon Q
Developer in chat applications** in the Observability Platform development AWS
account, then run `/invite @Amazon Q` in the Slack channel. The channel
configuration cannot be created until both steps are complete.

Verify delivery after applying by sending a test message from the Amazon Q
Developer console to the configured channel, then publishing a test message to
the SNS topic (its ARN is visible in the SNS console). Confirm both messages
arrive in `#observability-platform-development-alerts`.

The optional `pdc_token_rotator` configuration contains only:

| Field | Required value |
| --- | --- |
| `image_digest` | Released image digest, validated as `sha256:` followed by 64 lowercase hexadecimal characters |

Terraform creates `grafana-cloud/pdc-token-rotator/management-token` and
`grafana-cloud/pdc-token-rotator/stack-query-token` in the current environment's
AWS account and region, each with its own rotation-enabled customer-managed key.
The aliases are `alias/grafana-cloud-pdc-token-rotator-management-token` and
`alias/grafana-cloud-pdc-token-rotator-stack-query-token`. These are separate from
the tenant `grafana-cloud/pdc/<account ID>` secrets. No secret-version resource is
created for these credentials. The Lambda may only read the credential values
and decrypt each with its own key through Secrets Manager and that secret's
encryption context.

Terraform also creates the stack-scoped Cloud access policy
`pdc-token-rotator-development`, with exactly `accesspolicies:read` and
`accesspolicies:write`, and the stack service account
`pdc-token-rotator-query-development`. Grafana provider `3.25.9` supports role
`None` and `grafana_data_source_permission_item`: the service account has no
basic-role access and receives only `Query` on `grafanacloud-usage`. The
permission item is non-authoritative and preserves other permissions on that
provisioned data source. The Cloud service-account ID includes the stack slug;
the permission item uses only its numeric service-account portion.
Terraform creates no tokens for either identity.

This deploys the Lambda using the existing module/version, exact execution role
name, scoped IAM permissions, per-secret Secrets Manager invocation permissions,
Lambda error alarm and a Secrets Manager `RotationFailed` EventBridge target.
The alarm and EventBridge target use the SNS topic created from
`pdc_failure_alerts`; no SNS ARN needs to be supplied.
Initial reserved concurrency is one to serialise rotation invocations.
The Lambda uses a central DynamoDB table (`ROTATION_STATE_TABLE_NAME`) to resume
interrupted rotations. The journal stores progress and version/deployment
identifiers, not credentials. It has point-in-time recovery and deletion
protection; retain it across runtime changes and review retention before
activation. Do not remove it while any rotation could still be retried.
The SNS topic policy created with `pdc_failure_alerts` permits EventBridge and
CloudWatch delivery from only this account's rotation-failure rule and alarm.
Confirm the Chatbot subscription and delivery before activation.

Lambda receives only the management and stack query secret ARNs through
`GRAFANA_API_CREDENTIAL_SECRET_ARN` and
`GRAFANA_STACK_QUERY_CREDENTIAL_SECRET_ARN`. Use the
stack URL passed in `GRAFANA_STACK_URL` and confirm during the pilot that
`GRAFANA_USAGE_DATASOURCE_UID` (`grafanacloud-usage`) resolves to the usage data
source and that the credential can query it. Cadence comes from secret metadata.
The rotator derives the metric's `tunnelID` as `<stack ID>/<access policy ID>`
from the existing tags; no manual mapping is needed. The development pilot's
`testSecret` preflight must find a single fresh series with matching stack,
network, tunnel and region labels. Missing or ambiguous matches fail before
promotion. Confirm scrape and ingestion lag before choosing the runtime's metric
freshness, settling and stability settings.
Setting this object does **not** enable secret rotation or perform state handoff.

## Manual credentials after apply

1. In the Grafana Cloud portal, locate the Terraform-created
   `pdc-token-rotator-development` access policy in the stack's Cloud region
   (`prod-gb-south-1`) and add an **expiring** token. Retain the policy's exact
   scopes and stack realm; do not reuse Terraform's Cloud credential. This token
   is used to list and create PDC tokens through `https://grafana.com/api/v1/tokens`,
   never to delete them.
2. In the development stack's service-account settings, create a token for
   `pdc-token-rotator-query-development`. Do not widen its role or permissions.
   It queries
   `/api/datasources/proxy/uid/grafanacloud-usage/api/v1/query` for
   `grafanacloud_grafana_pdc_connected_agents`.
3. Using authenticated AWS credentials for Observability Platform development,
   put each token into its corresponding secret. Prepare protected local files
   containing **only the token string**, with no JSON, quotes or trailing newline.
   Keep files outside the repository, restrict permissions to the owner, and
   delete them securely after upload. Using files avoids putting literal tokens
   in shell history:

   ```shell
   aws secretsmanager put-secret-value \
     --region eu-west-2 \
     --secret-id grafana-cloud/pdc-token-rotator/management-token \
     --secret-string file:///secure/path/management-token

   aws secretsmanager put-secret-value \
     --region eu-west-2 \
     --secret-id grafana-cloud/pdc-token-rotator/stack-query-token \
     --secret-string file:///secure/path/stack-query-token
   ```

   Each call creates `AWSCURRENT` in its previously empty secret. Do not pass
   these values to Terraform or use a Terraform secret-version data source.

The management token's **own expiry and renewal are manual** for now. Record its
expiry and arrange renewal before it expires; issue its replacement through the
Cloud portal and update the same secret. Renew the query token manually too if
it has an expiry. Neither credential is rotated by the PDC rotator.
Uploading credentials does not invoke the Lambda or enable rotation.

## Dependencies before activation

- Confirm the released image can be pulled by Lambda from the cross-account ECR
  repository, including its repository policy. The dormant wiring follows the
  existing Lambda module `7.20.1` deployment pattern.
- Apply the development prerequisites, upload both credentials above, verify the
  scope/realm and the usage query, and agree manual credential renewal ownership.
  The initial runtime contract uses expiry rather than token deletion; do not
  grant deletion scope until its cleanup implementation is reviewed.
- A tenant module release with `grafana-pdc-agent-restarter`, trusted only by the
  agreed central Lambda execution role. The dormant wiring grants that execution
  role `sts:AssumeRole` only on opted-in accounts' restarter roles, with secret
  read/write/staging and KMS permissions restricted to this environment's PDC
  secrets and keys.
- A proven token acceptance check and a reconnection signal attributable to the
  **replacement** agents. The rotator queries
  `grafanacloud_grafana_pdc_connected_agents` for the network's `tunnelID`.
  Each network must be exclusive to one ECS agent service: the metric counts
  all connected agents on the network and must match that service's desired count.
  Verify during the pilot that the metric is fresh enough and measures the
  replacement deployment rather than still-connected old agents.
  ECS service stability alone is insufficient: an
  unauthenticated agent can stay running and retrying. Agree any additional log
  or metric permissions before extending the tenant role.
- A bounded restart/verification/rollback sequence within Lambda's 15-minute
  limit, including retry idempotency and concurrent invocation handling.
- A configured `pdc_failure_alerts` destination in the environment. Confirm
  both SNS and Amazon Q delivery before activation.

The future Secrets Manager invocation permission must restrict
`secretsmanager.amazonaws.com` to this AWS account and these secrets. Configure
each existing secret with `rotate_immediately = true` only after deploying and
verifying that permission, the runtime and alerts. Set
`rotation_rules.automatically_after_days` from
`local.pdc_rotation_rules.automatically_after_days`; do not add a separate
EventBridge schedule.

## Non-destructive Terraform state handoff

Do not perform this handoff while the rotator is unavailable or before a
reviewed manual bootstrap process is in place for new accounts. The rotator
requires an existing `AWSCURRENT` token and a healthy connected-agent baseline;
it fails closed on empty secrets and cannot issue the first token. After the
handoff, seed the first token and verify agents connect before enabling rotation
for a new account. Automatic first-token issuance remains unimplemented.
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
   unexpected change. Confirm an existing `AWSCURRENT` token and connected agents
   for each secret that will be enrolled in rotation.
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
Test manual bootstrap for a fresh account, scheduled and forced rotation, retries, reconnection
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
behaviour, dormant deployment, separate credential keys/secrets, least-privilege
Grafana identities, digest validation, scoped runtime permissions and failure
alert wiring. A separate negative test confirms that token destruction protection
rejects disabling accounts. It is not a full environment plan or an end-to-end
rotation test.
