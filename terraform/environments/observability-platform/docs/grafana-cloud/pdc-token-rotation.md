# PDC token rotation handoff

Tracks [ministryofjustice/observability-platform#338](https://github.com/ministryofjustice/observability-platform/issues/338).

## Current safe boundary

Sprinkler development has completed an alpha.4 rotation and reconnection and
previously demonstrated rollback. Keep its existing schedule and agents running.
Cooker development already has a working `AWSCURRENT`; the configuration below
prepares its non-destructive handoff and first rotation at the next reviewed
development apply. Do **not** bootstrap either account.

Production still has `tenant_configuration = {}`, no image and no alert
destination. A later reviewed stable image and production alert configuration
can deploy the common Lambda, journal, credential metadata and monitoring with
zero tenants. There are no empty or wildcard tenant IAM grants, tenant secrets,
schedules or invocations in that state. Confirm ECR pull access, production
credential custody/renewal and end-to-end alert delivery before onboarding.
An earlier protected production apply with plugin/AMG `EDITOR` drift is not a
production PDC deployment or approval.

## First issuance for a new opt-in

Development enables `bootstrap_enabled` for alpha.6. Its first-issuance accounts
are `example-development` and `cloud-platform-development`. Only the latter
belongs to the `cloud-platform` tenant in this stack. `cloud-platform-{preproduction,nonlive,live}`
and `container-platform-{octo,laa,hmpps,cd}-{nonlive,live}` are planned for
production, in a separate rollout after the production PDC rotator is ready.
They must not get development agents or development CloudWatch data sources.

Readiness gate for development:

1. Do not apply while any Sprinkler, Cooker or Example rotation step is in
   flight, and reconcile (approve or cancel) any older queued development run
   first. Never approve an older apply after a newer one.
2. After the central apply, confirm each new account's bootstrap journal is
   `completed` and `grafana-cloud/pdc/<account ID>` has a single initial version
   labelled only `AWSCURRENT`. Check version metadata only; do not retrieve the
   token.
3. Only then deploy agents, one account at a time. Wait for that account's
   enrolment to reach `enrolled` (its first rotation completed) before deploying
   the next. Prolonged pending enrolment raises the Errors alarm (default one
   day).

Example has no production opt-in or configured private query target; configure
a real target separately before query acceptance.

1. Use a genuinely new account and network/access policy, with **no** Grafana
   token history in that policy/region (including expired tokens). Terraform
   creates only the network, CMK, protected secret and cross-account policies;
   it tags the empty secret `pdc:bootstrap=true` alongside the rotation tags.
   No legacy token or secret-version resource may match. For live development
   proof use an authorised third account, never a cleared Sprinkler/Cooker secret.
2. On creation only, `terraform_data.gc_pdc_bootstrap` invokes the central
   Lambda synchronously: `{"Step":"bootstrapSecret","SecretId":"<full secret ARN>"}`.
   The apply runner needs Python 3, AWS CLI v2 and `lambda:InvokeFunction` on
   that function; the helper uses the runner credentials. Success is HTTP 200,
   no `FunctionError`, JSON `null`. No response, token or request ID is emitted
   or stored in state. The runtime checks all version history, claims issuance
   in its journal and guards the first `AWSCURRENT`; it does not contact ECS or
   query metrics.
3. After confirmed first issuance the team deploys the existing tenant module
   with `grafana_cloud.pdc_agent.enabled = true`; ECS reads the central secret.
   Keep the completed marker at its address. No image, enrolment or destroy
   trigger replays it.
4. After bootstrap, EventBridge invokes the unqualified rotator hourly with
   `{"Step":"enrolRotation","SecretId":"<full secret ARN>"}`. This is a
   readiness check, not a token request. It stays `pending` until one stable
   ECS deployment and a fresh, sustained matching Grafana network count confirm
   that the expected agents are connected. The runtime then requests the first
   rotation and its native 90-day schedule (`rotation_requested`). `enrolled`
   means that first rotation completed, not just that a schedule exists.
   `superseded` means another invocation won the journal update. Further ticks
   do not reset the schedule or reissue the seed.

**If bootstrap fails:** the shared Lambda has one concurrency slot. A seeded
tenant's immediate rotation can occupy it. The helper retries only a Lambda
Invoke `TooManyRequestsException`, which rejects the request before the handler
runs. It waits 10, 20, 40, then up to fourteen 60-second intervals (15 minutes
10 seconds of backoff in total). Other service errors report only their code
when recognised. A `FunctionError`, read timeout, unrecognised error or invalid
response stops the helper without another attempt. CLI exit 254 alone does
not identify throttling.

An apply that adds several opt-ins at once
starts their bootstrap invocations in parallel, up to Terraform's
default parallelism of 10. They share the single slot with each other, seeded
rotations and hourly enrolment ticks, so most wait inside the helper's retry
budget. If an invocation runs long, others can exhaust that budget; handle each
failed marker as below.

Before allowing another apply, let any in-flight invocation finish. Check the
seeded rotation journal, Lambda `Throttles` and `ConcurrentExecutions`, and
Invoke data events if recorded. Check the new secret's version IDs and stages
(not values), its bootstrap journal and the Grafana policy's token history. If
issuance is ambiguous, stop and reconcile: never clear the claim, reseed the
secret, manually taint the marker or rerun an old plan. For `AccessDeniedException`,
check the apply runner's invoke permission on the exact function.

A failed create provisioner normally leaves a tainted `terraform_data` marker.
After reconciliation, review a **fresh** plan: replacing that marker invokes
bootstrap again; it must not replace the secret or any issued token. A matching
completed journal and sole initial `AWSCURRENT` are a runtime no-op before
enrolment. After a successful apply, confirm the completed journal,
`AWSCURRENT`, enrolment rule, target, permissions and delivery alarm before
deploying the tenant agents. A retained, successful marker is not replayed by
an ordinary apply; state loss or explicit replacement is not an ordinary apply.

The function's Errors alarm covers enrolment failures. On the first hourly
check that finds the account not ready, alpha.6 records `pending_since`. On a
subsequent check it raises an error if still pending for **at least 86,400
seconds from `pending_since`**, or within 14 days of seed expiry. This is not
a timer from bootstrap. One error in a 60-second period is enough for the
shared `AWS/Lambda` Errors alarm; the precise alert time depends on tick
delivery. See the [pinned enrolment code](https://github.com/ministryofjustice/observability-platform-grafana-pdc-token-rotator/blob/v0.1.0-alpha.6/src/pdc_rotator/enrolment.py#L218-L245).
The per-rule `AWS/Events` `FailedInvocations` alarm covers delivery failures
that never reached Lambda. Both notify the existing encrypted SNS destination.
Check the journal and AWS/Grafana metadata on alerts; never re-bootstrap an
expired seed or retry an ambiguous rotation request manually.

Terraform still owns Sprinkler's and Cooker's rotation schedules. For
bootstrap accounts only, the runtime can call `RotateSecret` on their exact
ARNs with its own unqualified function and assume the tenant restarter roles.
Lambda permissions restrict EventBridge to the corresponding rule and Secrets
Manager to the corresponding secret and source account.

## Retire the three CP3 accounts from development

The four-account development configuration was already applied. Retire only
`cloud-platform-preproduction`, `cloud-platform-nonlive` and `cloud-platform-live`.
This does not migrate tokens to production. Keep `cloud-platform-development`,
Example, Sprinkler and Cooker running.

**Before apply:** fence stale plans; confirm no agents, connected-agent traffic,
rotation/in-flight invocation or native rotation schedule for the three accounts.
Check each completed bootstrap journal, sole initial `AWSCURRENT` version and
Grafana policy/token IDs using **metadata only**. Record the exact secret ARN,
KMS key ARN, development policy ID, token ID and region in the restricted change
record before Terraform removes aliases and networks. Never read or copy the
token, clear journal entries or change version labels.

Review the development plan against the applied state:

- Six exact moves to singleton addresses followed by `forget`, not `delete`:
  the `aws_secretsmanager_secret.gc_pdc_token` and `aws_kms_key.gc_pdc_token`
  instances for those three accounts. Keep `prevent_destroy` on the managed
  secrets. Do not use resource-wide removals or `terraform state rm`.
- Per retired account: remove only its Grafana PDC network, CloudWatch data
  source and permission, enrolment rule, target, two Lambda permissions and
  delivery alarm, bootstrap marker, secret policy and KMS alias. The marker
  has only a **create-time** provisioner; removing it does not invoke Lambda.
- The rotator IAM policy, failure-alert KMS key policy and SNS topic policy
  narrow in place. Stop on any create, replacement, other managed change or
  change to a retained account. Production should have no handoff.

**Grafana deletion gate:** the [3.25.9 provider](https://github.com/grafana/terraform-provider-grafana/blob/v3.25.9/internal/resources/cloud/resource_private_data_source_connect_network.go#L211-L220)
calls only `DeleteAccessPolicy(region, id)`; it does not delete tokens individually.
The [API reference](https://grafana.com/docs/grafana-cloud/learn-and-build/developer-resources/api-reference/cloud-api/)
documents a successful policy deletion but does not guarantee what happens to
existing tokens on that call. Confirm the behaviour for policies with issued
tokens with Grafana before apply. After apply verify that the three policy IDs
are gone and their token IDs are no longer active in the correct organisation
and region. If a delete is rejected, the outcome is ambiguous, or a token
remains active, stop and reconcile the partial apply. Any necessary revocation
requires a separately approved Grafana operation by token ID. Forgetting or
deleting an AWS secret does **not** revoke a Grafana token.

### Manual AWS cleanup after the handoff

Use a reviewed operator session in **Observability Platform development**,
`eu-west-2`, one retired account at a time. Do not run these as Terraform
provisioners. Before the handoff, in a shell with tracing disabled, identify
the account from the approved inventory and capture its metadata:

```bash
set -eu
: "${AWS_PROFILE:?select the Observability Platform development profile}"
: "${OP_DEV_ACCOUNT_ID:?set from the approved inventory}"
: "${account:?set the retired account name}" "${tenant_id:?set its verified AWS account ID}"
case "$account" in
  cloud-platform-preproduction|cloud-platform-nonlive|cloud-platform-live) ;;
  *) exit 1 ;;
esac
export AWS_REGION=eu-west-2 AWS_DEFAULT_REGION=eu-west-2
test "$(aws sts get-caller-identity --query Account --output text)" = "$OP_DEV_ACCOUNT_ID"
secret_arn=$(aws secretsmanager describe-secret --secret-id "grafana-cloud/pdc/$tenant_id" --query ARN --output text)
key_arn=$(aws kms describe-key --key-id "alias/grafana-cloud-pdc-$account" --query KeyMetadata.Arn --output text)
test "$(aws secretsmanager describe-secret --secret-id "$secret_arn" --query KmsKeyId --output text)" = "$key_arn"
test "$(aws kms describe-key --key-id "$key_arn" --query KeyMetadata.Description --output text)" = "Encrypts the Grafana Cloud PDC agent token for $account"
```

After the reviewed apply, check that the six objects have left Terraform state,
the three accounts' ticks and secret policies are gone, and the Grafana deletion
gate above is satisfied. Using the verified ARNs from the change record (not an
alias or a name search), recheck identity, region and the secret/key pairing.
Schedule the **secret first**, with a 30-day recovery window:

```bash
set -eu
case "$account" in cloud-platform-preproduction|cloud-platform-nonlive|cloud-platform-live) ;; *) exit 1 ;; esac
test "$(aws sts get-caller-identity --query Account --output text)" = "$OP_DEV_ACCOUNT_ID"
test "$(aws secretsmanager describe-secret --region eu-west-2 --secret-id "grafana-cloud/pdc/$tenant_id" --query ARN --output text)" = "$secret_arn"
test "$(aws secretsmanager describe-secret --region eu-west-2 --secret-id "$secret_arn" --query KmsKeyId --output text)" = "$key_arn"
test "$(aws kms describe-key --region eu-west-2 --key-id "$key_arn" --query KeyMetadata.Description --output text)" = "Encrypts the Grafana Cloud PDC agent token for $account"
aws secretsmanager delete-secret --region eu-west-2 --secret-id "$secret_arn" \
  --recovery-window-in-days 30 --query DeletionDate --output text
```

Keep the key enabled through the entire recovery window. Only after the secret
is actually gone (`describe-secret` on that exact ARN returns
`ResourceNotFoundException`, not access denied or a transport error), recheck
that the dedicated key has no other consumers and match its ARN to the recorded
pair. With separate operator confirmation schedule the key for deletion:

```bash
set -eu
case "$account" in cloud-platform-preproduction|cloud-platform-nonlive|cloud-platform-live) ;; *) exit 1 ;; esac
test "$(aws sts get-caller-identity --query Account --output text)" = "$OP_DEV_ACCOUNT_ID"
test "$(aws kms describe-key --region eu-west-2 --key-id "$key_arn" --query KeyMetadata.Description --output text)" = "Encrypts the Grafana Cloud PDC agent token for $account"
aws kms schedule-key-deletion --region eu-west-2 --key-id "$key_arn" \
  --pending-window-in-days 30 --query DeletionDate --output text
```

Do not use force deletion. Retain the journals and the restricted audit record.
Before configuring these instance keys in production, verify the development
handoff is complete and retire its six move/forget pairs in a reviewed change:
both workspaces use the same root, so a move source must not also be configured
as a live instance in the new stack.

## Rotation contract

`grafana-cloud-pdc-rotation.tf` defines the rotation interval and grace period
together as code locals. `local.pdc_rotation_rules` supplies the seeded accounts' Secrets
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

Bootstrapped accounts also get `pdc:bootstrap=true` and
`pdc:rotation-interval-days=90`; both are absent on seeded accounts.

The Lambda must read and validate these settings rather than hard-code another
cadence. Shortening an interval or changing expiry settings must not change the
expiry of the currently deployed token. If PDC is enabled in a different AWS
region, extend the account configuration and region metadata before onboarding.

The confirmed role contract is
`arn:aws:iam::<observability-account-id>:role/grafana-pdc-token-rotator`, at path
`/`, assuming
`arn:aws:iam::<tenant-account-id>:role/grafana-pdc-agent-restarter`. The runtime
derives the tenant role ARN from the account ID.

## Shared Lambda deployment

The dedicated repository is
`ministryofjustice/observability-platform-grafana-pdc-token-rotator`. The
development image is [v0.1.0-alpha.6](https://github.com/ministryofjustice/observability-platform-grafana-pdc-token-rotator/releases/tag/v0.1.0-alpha.6).
The [publish job](https://github.com/ministryofjustice/observability-platform-grafana-pdc-token-rotator/actions/runs/45822655850/job/139919808939)
verified and signed the single image manifest
`sha256:e5f367b6af986020ff291b095f7ef0a44f56c7c7acd241fbaaae9484c81884c2`.
Development pins this digest, not the tag. Do not use alpha.5 for bootstrap:
it rejected the `AWSCURRENT` label that Secrets Manager automatically adds to a
secret's first version, so it failed after storing the candidate. Alpha.6
resumes from that journalled state. The earlier `v0.1.0-alpha.1` artifact was a
manifest list rejected by Lambda and is not deployable; do not use its digest.

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
| `bootstrap_enabled` | Enables first issuance and hourly enrolment only for new accounts; requires a compatible pinned image |

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
CloudWatch delivery from only this account's rotation-failure rule, function
Errors alarm and per-tenant tick delivery alarms.
Confirm the Chatbot subscription and delivery before activation.

Lambda receives only the management and stack query secret ARNs through
`GRAFANA_API_CREDENTIAL_SECRET_ARN` and
`GRAFANA_STACK_QUERY_CREDENTIAL_SECRET_ARN`. Use the
stack URL passed in `GRAFANA_STACK_URL` and confirm before activation that
`GRAFANA_USAGE_DATASOURCE_UID` (`grafanacloud-usage`) resolves to the usage data
source and that the credential can query it. Cadence comes from secret metadata.
The rotator derives the metric's `tunnelID` as `<stack ID>/<access policy ID>`
from the existing tags; no manual mapping is needed. The development pilot's
`testSecret` preflight must find a single fresh series with matching stack,
network, tunnel and region labels. Missing or ambiguous matches fail before
promotion. Confirm scrape and ingestion lag before choosing the runtime's metric
freshness, settling and stability settings.
With no tenants this object does not enable rotation or invoke the Lambda.

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

- Confirm the merged tenant-module update in MPE PR
  [#20602](https://github.com/ministryofjustice/modernisation-platform-environments/pull/20602)
  has been deployed before activation. It updates the tenant module pin to a
  release that adds `grafana-pdc-agent-restarter`. Verify the merged module
  version is deployed to Cooker development before its handoff.
- Confirm the released image can be pulled by Lambda from the cross-account ECR
  repository, including its repository policy. The rotator follows the
  existing Lambda module `7.20.1` deployment pattern.
- Apply the development prerequisites, upload both credentials above, verify the
  scope/realm and the usage query, and agree manual credential renewal ownership.
  The initial runtime contract uses expiry rather than token deletion; do not
  grant deletion scope until its cleanup implementation is reviewed.
- A tenant module release with `grafana-pdc-agent-restarter`, trusted only by the
  agreed central Lambda execution role. The execution role can assume only
  scheduled and enrolment-eligible accounts' restarter roles, with secret
  read/write/staging and KMS permissions restricted to this environment's PDC
  secrets and keys.
- A proven token acceptance check and a reconnection signal attributable to the
  **replacement** agents. The rotator queries
  `grafanacloud_grafana_pdc_connected_agents` for the network's `tunnelID`.
  Each network must be exclusive to one ECS agent service: the metric counts
  all connected agents on the network and must match that service's desired count.
  Verify that the metric is fresh enough and measures the
  replacement deployment rather than still-connected old agents.
  ECS service stability alone is insufficient: an
  unauthenticated agent can stay running and retrying. Agree any additional log
  or metric permissions before extending the tenant role.
- A bounded restart/verification/rollback sequence within Lambda's 15-minute
  limit, including retry idempotency and concurrent invocation handling.
- A configured `pdc_failure_alerts` destination in the environment. Confirm
  both SNS and Amazon Q delivery before activation.

Before scheduling the activation, securely record the existing Cooker
Grafana token ID and the Secrets Manager version ID currently labelled
`AWSCURRENT`. Use Grafana token metadata/portal and this metadata-only command:

```shell
aws secretsmanager describe-secret \
  --region eu-west-2 \
  --secret-id 'grafana-cloud/pdc/<Cooker-development-account-id>' \
  --query VersionIdsToStages \
  --output json
```

Do not call `get-secret-value`, copy token values, or print them. Store the IDs
in the approved restricted operational record, not in this repository. Protect
plan files and state backups as credentials.

Check the full preflight immediately before the maintenance window:

- Confirm exactly one `AWSCURRENT`, no unfinished rotation, and a working
  read-only PDC query through the Cooker network.
- Confirm the ECS service is `ACTIVE`, has a positive desired count, and is
  stable on its expected task definition. Confirm a single fresh
  `grafanacloud_grafana_pdc_connected_agents` series for the Cooker
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

## Cooker development handoff runbook

The change uses exact `moved` blocks from the Cooker development
`for_each` instances to singleton handoff addresses, followed by singleton
`removed` blocks with `destroy = false`. Terraform 1.10+ supports moving one
`for_each` instance this way; the PDC test runner also verifies the operation
with disposable local state and `prevent_destroy` enabled. The token and
secret-version instances are forgotten without provider delete calls. The
network, secret, KMS key, key alias, policies and Sprinkler schedule remain
managed. Do not substitute resource-wide `removed` blocks or `terraform state
rm`; either would lose the scope and safeguards of this handoff.

Both legacy resource collections are now empty. Retain the historical Cooker
and Sprinkler moved/removed blocks for their tokens and versions.
Secret metadata has `prevent_destroy` even after its version is forgotten.

### Review and fence the activation

1. Complete every preflight above, record the existing Cooker token ID and
   current secret version ID securely, and agree the maintenance window. Never
   retrieve or print secret values.
2. Before opening the PR, confirm the GitHub Environment approval gate and who
   can approve the development deployment. The Observability Platform workflow
   can apply development from the PR branch as well as from `main`: do not
   approve a PR-branch apply of this change. Only the reviewed main-branch
   deployment may activate Cooker's schedule.
3. Coordinate merging the PR with the agreed maintenance window if a push to
   `main` can auto-apply. Before activation, wait for or cancel every in-flight
   or queued Observability Platform deployment from an older revision and
   discard stale saved plans. The shared workflow serialises applies by
   environment/component and the S3 backend uses a lockfile; these do not make
   a stale plan safe to apply later. If the deployment queue cannot be fenced
   or its revision confirmed, do not activate.
4. Generate and review a fresh plan for each environment from that revision.
   For Cooker's handoff, development must show:
   - The Cooker development token and secret-version instances move to their
     singleton handoff addresses and are then forgotten, explicitly **not
     destroyed** (`destroy = false`).
   - One `aws_secretsmanager_secret_rotation.gc_pdc_token["cooker-development"]`
     is added, with the deployed rotator Lambda and the
     `local.pdc_rotation_rules` interval.
   - No replacement of Cooker's network, secret, key, alias or token, and no
     change to Sprinkler's schedule.

   If the revision also onboards a new opt-in, review its network and protected secret,
   first-issuance marker, scoped permissions, readiness rule/target and delivery
   alarm. There must be **no** Terraform-managed token, secret version or native
   rotation schedule for them, and the development image pin and existing
   accounts' resources must be unchanged.

   Production must have no PDC handoff, rotation, or rotator changes. Stop if
   there is any unexpected change, destroy/replacement, missing state move, or
   unexplained drift. Do not approve a stale plan.
5. Apply the reviewed development plan only inside the agreed window, with
   operators watching the apply and rotation. `rotate_immediately = true` means
   creating the rotation configuration starts the complete first rotation
   during this apply. Do **not** make a second `aws secretsmanager rotate-secret`
   call. The `automatically_after_days` rule from
   `local.pdc_rotation_rules` schedules later rotations; no separate
   EventBridge schedule is used.
6. If apply or rotation outcome is ambiguous, stop other applies and do not
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
  Cooker stack/network/region labels match that count after the configured
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

Seven days after successful replacement-agent verification is the earliest
cleanup review, not authority to revoke. Before revoking the original
Terraform-created token, verify by its recorded Grafana token ID and secret
version that the secret version is not labelled `AWSCURRENT`, no rotation or
rollback is in flight, and the token is no longer needed for recovery. Check
explicitly whether its secret version is still `AWSPREVIOUS` and whether it is
needed for rollback. An `AWSPREVIOUS` label does not preserve fallback
capability after its Grafana token is revoked. If the original is still the
only viable rollback token, defer revocation until an alternative recovery path
is verified and approved.

Only after that review and explicit operational approval, revoke the original
token through the approved Grafana administration path; the token has no
expiry, and the rotator does not delete it. Never select a token by name alone.
Retain secret versions and staging labels according to the recovery policy,
without treating a label as proof that a revoked Grafana token remains usable.
Historical Terraform state versions, backups and plans may still contain the
original token value and must follow the existing sensitive-state retention
controls.

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
per-account metadata, 90-day schedules for existing accounts, 97-day token
lifetime, new-account bootstrap eligibility, empty-production IAM, separate credential
keys/secrets, least-privilege Grafana identities, digest validation, scoped
runtime permissions, hourly enrolment payload and separate delivery and runtime
alarms. A stub CLI checks the synchronous
bootstrap request, throttle-only backoff and redaction, and non-replay across
an image change, tick target replacement and teardown. Disposable local-state
tests verify failed marker replacement, no replay after success, and exactly
two Cooker forgets with zero deletes using the checked-in migration blocks.
A separate mocked plan starts from the previously applied four-account CP3
tenant and checks all six secret/key forgets, 33 deletes and three in-place
policy changes by address, rejecting any change to a retained account.
A negative test confirms secret protection rejects destructive
account disablement. These are not live issuance or reconnection tests.
