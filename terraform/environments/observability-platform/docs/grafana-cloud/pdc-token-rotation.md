# PDC token rotation handoff

Tracks [ministryofjustice/observability-platform#338](https://github.com/ministryofjustice/observability-platform/issues/338).

## Current safe boundary

The deployed baseline is still dormant: development has the Lambda, journal,
scoped IAM policy, alarms, credential secrets, token-less Grafana identities and
failure SNS/Slack delivery, but no tenant-secret rotation schedule. The reviewed
pilot configuration will enable rotation only for Sprinkler development. Its
first rotation starts during the approved Terraform apply; until that change is
deployed, existing tokens remain valid and managed as before. Cooker development
and production remain unchanged, and all non-pilot accounts retain Terraform's
first-token bootstrap behaviour. Production keeps `pdc_token_rotator = null`.
The secret names, per-account networks, KMS policies and tenant read permissions
are unchanged.

Managed token and secret-version resources block destruction, including
replacement and account removal. This is intentional: replacing a Grafana token
revokes it before ECS agents can read its replacement. The pilot instances are
the exception: they are explicitly moved and forgotten without destruction.
Offboarding other accounts still requires an explicitly reviewed change to
these protections.

Terraform still holds the existing tenant PDC token values in state until the
handoff below. The two new rotator credential values are never generated, read,
supplied as inputs or exposed as outputs by Terraform; it owns only their empty
secrets, keys and Grafana identities.

## Rotation contract

`grafana-cloud-pdc-rotation.tf` defines the rotation interval and grace period
together as code locals. `local.pdc_rotation_rules` supplies the pilot's Secrets
Manager `rotation_rules`; `local.pdc_token_lifetime_days` derives each new
token's expiry period from the same settings. These are not module inputs or
outputs.

Each central `grafana-cloud/pdc/<account ID>` secret carries these tags. They are
an integration contract for the deployed rotator runtime:

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

- Merge and deploy MPE PR
  [#20602](https://github.com/ministryofjustice/modernisation-platform-environments/pull/20602)
  before activation. It updates the tenant module pin to a release that adds
  `grafana-pdc-agent-restarter`; the development
  accounts were previously updated from that branch, but the change is not yet
  on `main`. Verify the merged module version is deployed to Sprinkler
  development. Do not edit that PR as part of this pilot.
- The main deployments in run `45418300030` succeeded in both environments.
  The pilot code still requires its own reviewed main-branch plan and apply.
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

Before scheduling the activation, securely record the existing Sprinkler
Grafana token ID and the Secrets Manager version ID currently labelled
`AWSCURRENT`. Use Grafana token metadata/portal and this metadata-only command:

```shell
aws secretsmanager describe-secret \
  --region eu-west-2 \
  --secret-id 'grafana-cloud/pdc/<Sprinkler-development-account-id>' \
  --query VersionIdsToStages \
  --output json
```

Do not call `get-secret-value`, copy token values, or print them. Store the IDs
in the approved restricted operational record, not in this repository. Protect
plan files and state backups as credentials.

Check the full preflight immediately before the maintenance window:

- Confirm exactly one `AWSCURRENT`, no unfinished rotation, and a working
  read-only PDC query through the Sprinkler network.
- Confirm the ECS service is `ACTIVE`, has a positive desired count, and is
  stable on its expected task definition. Confirm a single fresh
  `grafanacloud_grafana_pdc_connected_agents` series for the Sprinkler
  `tunnelID`, with the expected stack/network/region labels and count matching
  the exclusive service's desired count. The current runtime defaults require
  metric age at most 180 seconds, then at least two post-settle samples spanning
  60 seconds with the desired count; confirm any configured overrides.
- Recheck the management token's policy scopes/realm and expiry, the separate
  query token's access to `grafanacloud-usage`, the Lambda's scoped
  Secrets Manager invocation permission, tenant-role assumption, journal
  access, and the SNS-to-Slack failure path.
- Confirm the original token/version IDs are recorded, operators are available
  to monitor and recover, and this apply is within the approved maintenance
  window. A rotation run must finish or leave time for rollback before the
  current token's expiry.

## Sprinkler development pilot runbook

The change uses exact `moved` blocks from the Sprinkler development
`for_each` instances to singleton handoff addresses, followed by singleton
`removed` blocks with `destroy = false`. Terraform 1.10+ supports moving one
`for_each` instance this way; the PDC test runner also verifies the operation
with disposable local state and `prevent_destroy` enabled. The token and
secret-version instances are forgotten without provider delete calls. The
network, secret, KMS key, key alias, policies and other account tokens remain
managed. Do not substitute resource-wide `removed` blocks or `terraform state
rm`; either would lose the scope and safeguards of this handoff.

The runtime cannot create the first token for an empty secret. That is not a
problem for this pilot: Sprinkler already has an `AWSCURRENT` token. Every
non-pilot account, including Cooker development, remains in Terraform's token
and secret-version `for_each` resources, so new-account bootstrap remains
automatic. Production has no pilot handoff or rotation configuration.

### Review and fence the activation

1. Complete every preflight above, record the existing Sprinkler token ID and
   current secret version ID securely, and agree the maintenance window. Never
   retrieve or print secret values.
2. Deploy only the reviewed revision from `main`. Before activation, wait for or
   cancel every in-flight or queued Observability Platform deployment from an
   older revision and discard stale saved plans. The shared workflow serialises
   applies by environment/component and the S3 backend uses a lockfile; these
   do not make a stale plan safe to apply later. If the deployment queue cannot
   be fenced or its revision confirmed, do not activate.
3. Generate and review a fresh plan for each environment from that revision.
   Development must show only these PDC changes:
   - The Sprinkler development token and secret-version instances move to their
     singleton handoff addresses and are then forgotten, explicitly **not
     destroyed** (`destroy = false`).
   - One `aws_secretsmanager_secret_rotation.gc_pdc_token["sprinkler-development"]`
     is added, with the deployed rotator Lambda and the
     `local.pdc_rotation_rules` interval.
   - No network, secret, KMS key, key alias, policy, token replacement, or
     Cooker change.

   Production must have no PDC handoff, rotation, or rotator changes. Stop if
   there is any unexpected change, destroy/replacement, missing state move, or
   unexplained drift. Do not approve a stale plan.
4. Apply the reviewed development plan only inside the agreed window, with
   operators watching the apply and rotation. `rotate_immediately = true` means
   creating the rotation configuration starts the complete first rotation
   during this apply. Do **not** make a second `aws secretsmanager rotate-secret`
   call. The `automatically_after_days` rule from
   `local.pdc_rotation_rules` schedules later rotations; no separate
   EventBridge schedule is used.
5. If apply or rotation outcome is ambiguous, stop other applies and do not
   reintroduce the old resource configuration or blindly reapply. Check fresh
   Terraform state/plan, `describe-secret` version stages, Lambda logs, the
   DynamoDB journal and the alarm first. A failed apply may have enabled
   rotation or started the asynchronous rotation even if the workflow did not
   report success.

### Monitor and accept the first rotation

- Follow the Lambda's four Secrets Manager steps: `createSecret` creates an
  expiring Grafana token as `AWSPENDING`; `setSecret` verifies the pending
  version; `testSecret` validates it through PDC signing and confirms the
  connected-agent baseline; `finishSecret` journals and promotes it, forces a
  new ECS deployment, and verifies replacement agents.
- Watch the `grafana-pdc-token-rotator` CloudWatch log group, the rotation
  journal (it stores phases and identifiers, never credentials), the secret's
  `VersionIdsToStages`, the `grafana-pdc-token-rotator-errors` alarm and
  `RotationFailed` EventBridge/SNS delivery to
  `#observability-platform-development-alerts`. Do not log or fetch token
  values.
- Confirm success only when the new version is `AWSCURRENT`, the former current
  version is retained as `AWSPREVIOUS`, the journal reaches `completed`, and
  the new ECS deployment is stable with the expected task definition and
  desired running count. Confirm fresh connected-agent samples for the
  Sprinkler stack/network/region labels match that count after the configured
  settle period and across the stability period. Finally, verify a real
  private-data-source query through the network.

### Failure and rollback

The runtime fails closed before promotion if the pending token, service, or
metric preflight is invalid. If rollout verification fails after promotion, its
durable journal records the recovery phase; the Lambda moves `AWSCURRENT` back
to the recorded previous version, restarts the service on that credential, and
verifies reconnection. Confirm the resulting current version, deployment,
journal, and alarm rather than assuming rollback succeeded.

If the journal shows rollback incomplete or the current version is not the
recorded known-good version, treat this as an incident: prevent another
rotation invocation, retain `AWSPENDING`, `AWSCURRENT`, and `AWSPREVIOUS`, and
use the recorded version IDs to restore the known-good current version and
force an ECS deployment on it under the incident lead's direction. Verify
fresh connected-agent samples and a PDC query before resuming automation.
Never delete a candidate token or manually clear staging labels while an
invocation may still be running. Do not revoke the original token on failure.

### Post-success cleanup

Keep the original Terraform-created Sprinkler token valid through the full
seven-day grace period after successful replacement-agent verification. Then
delete that original token by its securely recorded Grafana token ID through
the approved Grafana administration path; it has no expiry, and the rotator
does not delete it. Never select a token by name alone. Retain the old secret
version and `AWSPREVIOUS` as required by the recovery policy. Historical
Terraform state versions, backups and plans may still contain the original
token value and must follow the existing sensitive-state retention controls.

Do not enable production rotation as part of this pilot. Production activation
requires a separate review and successful development evidence for scheduled
rotation, retries, interrupted invocation recovery, rollback, and cleanup.

## Focused validation

From the repository root:

```shell
python3 terraform/environments/observability-platform/tests/run_pdc_rotation_tests.py
```

The runner copies the real PDC files and their provider constraints into a
temporary root, initialises without a backend, validates, then runs Terraform
tests with mocked providers. Registry/module downloads require network access;
no AWS or Grafana credentials, live backend or real API calls are used. It checks
per-account metadata, expiry/schedule consistency, pilot-only rotation, Cooker
and production token/bootstrap preservation, new-account onboarding, opt-in and
empty-account behaviour, the dormant deployment, separate credential
keys/secrets, least-privilege Grafana identities, digest validation, scoped
runtime permissions and failure alert wiring. A disposable local-state test
applies the exact instance-move/`destroy = false` pattern against protected
synthetic token and version resources, verifies zero creates/changes/destroys,
and confirms the control account remains in state. A separate negative test
confirms token destruction protection rejects disabling accounts. These tests
are not an end-to-end rotation test.
