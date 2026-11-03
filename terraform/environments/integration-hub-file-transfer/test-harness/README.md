# File-transfer test harness

This component provides test-only infrastructure for Integration Hub live tests
in `eu-west-2`. It supplies a GitHub OIDC role and an isolated push-to-S3
destination bucket with a dedicated KMS key. The tests use the existing
file-transfer service, not a separate scanning or delivery pipeline.

The live-test scripts and GitHub Actions workflows belong to the
`ministryofjustice/integration-hub` repository under `tests/file-transfer/`.
This component defines their AWS access and test destination, not the tests
themselves. Its resources are created only in the test environment.

## Architecture

1. A GitHub Actions job assumes the harness role and uploads a non-sensitive
	fixture to a route-specific prefix in the incoming bucket.
2. The parent file-transfer pipeline processes the uploaded object version.
	Only a positive clean malware scan permits clean-file dispatch.
3. Shared dispatch configuration selects the action or notification for that
	source prefix. The corresponding service component delivers or retains the
	clean file using its own execution role.
4. The test uses the harness role to inspect the result within its permitted
	destination prefix.

| Component | Responsibility |
| --- | --- |
| `test-harness` | GitHub test role, simulated customer destination bucket and its encryption key |
| Parent file-transfer service | Incoming and clean storage, malware-processing pipeline and dispatch secrets |
| `push-to-s3` | Copies clean files to the harness-owned destination |
| `push-to-s3-with-hosted-pickup` | Provisions hosted recipient storage and copies clean files into it |
| `pull-from-presigned-url` | Retains recipient files in shared pickup storage and manages pickup grants and notifications |

The harness role has no destination-write permissions. File delivery remains
the responsibility of the service components.

## Routes and destinations

All fixtures enter `integration-hub-file-transfer-test-incoming`. The
[shared test dispatch configuration](../modules/file-dispatch-configuration/locals-test.tf)
defines three routes under the `test-harness` identity.

| Route | Incoming prefix | Destination bucket | Destination prefix |
| --- | --- | --- | --- |
| Push to S3 | `test-harness/push-to-s3/` | `integration-hub-file-transfer-test-test-harness` | `push-to-s3/` |
| Hosted pickup | `test-harness/hosted-pickup/` | `integration-hub-test-test-harness-pickup` | `pickup/` |
| Presigned pickup | `test-harness/pull-from-presigned-url/` | `integration-hub-file-transfer-pickup-test-<account-id>` | `test-harness-presigned/` |

Push-to-S3 and hosted pickup use their respective delivery actions, with no
notifications configured. The presigned route has `action = null` and a Slack
notification for recipient `test-harness-presigned`; its notification component
retains the clean copy for pickup.

The presigned recipient is configured for the `azure-aws-sso-integration-hub`
Identity Center group and `#integration-hub-test-alerts` in the Justice Digital
Slack workspace. Web-app membership is managed by the parent configuration;
pickup grants are managed by the presigned component. Slack channel membership
does not itself grant file access.

## Access boundaries

GitHub OIDC trust accepts jobs using the `smoke-test` environment in
`ministryofjustice/integration-hub` or
`ministryofjustice/modernisation-platform-environments`, with audience
`sts.amazonaws.com`. Jobs require `environment: smoke-test` and
`id-token: write`. Branch restrictions and required reviewers belong to the
GitHub environment protection rules, not the IAM trust policy.

| Scope | Harness permissions |
| --- | --- |
| Incoming storage | Upload and encrypt fixtures beneath the three test prefixes |
| Clean storage | List object versions beneath those prefixes, without reading file contents |
| Dispatch configuration | Describe the three route secrets, without reading their values |
| Delivery functions | Invoke the push-to-S3 and hosted-pickup writers |
| Push-to-S3 destination | List, read and decrypt objects beneath `push-to-s3/` |
| Hosted destination | List, read and decrypt objects beneath `pickup/`; read lifecycle configuration |
| Presigned destination | List objects beneath `test-harness-presigned/`, without object-read or decryption permissions |
| S3 Access Grants | List grant metadata on the account's regional default instance |

KMS permissions are restricted to use through S3 with the configured encryption
contexts. Hosted storage uses S3 Bucket Keys and therefore a bucket-level
encryption context; S3 object permissions still restrict reads to `pickup/`.
The harness policy grants no object deletion, destination writes or
administrative access. Direct writer invocations remain subject to the
writers' request and source/destination validation.

## Verification scope

For push-to-S3 and hosted pickup, the harness supports checking that a fixture
arrives and its contents match the original. Hosted tests can also inspect the
configured retention rules.

For presigned pickup, the harness supports an access-control check: locate the
specific run's retained fixture, inspect grant metadata, then verify that a
direct read using the harness credentials is denied. A denied read alone does
not establish that the fixture exists. The policy deliberately supplies no
presigned object-read permission; it does not contain an explicit deny.

Use a unique run token for each fixture and bounded waits for asynchronous
delivery. Assertions must use the harness role, not an operator's broader
credentials. Never copy a fixture into a destination to satisfy a test.

These permissions do not establish successful Slack delivery or an authorised
recipient download. Direct S3 staging does not exercise customer authentication,
SFTP, FTPS, HTTP API or browser uploads. Negative scan outcomes, retries,
idempotency and completion events require dedicated test assertions; deploying
this infrastructure does not verify them.

## Storage and retention

The harness-owned bucket blocks public access, enforces TLS and bucket-owner
ownership, and uses versioning and SSE-KMS. Incorrect encryption headers and
alternative KMS keys are rejected. S3 Bucket Keys are disabled for this bucket.

Its lifecycle rules expire current and noncurrent versions after one day,
abort incomplete multipart uploads after one day and remove expired delete
markers. The hosted route also specifies one-day retention, managed by the
hosted component. Shared presigned storage follows the
[presigned component's retention policy](../pull-from-presigned-url/README.md).
Lifecycle cleanup is asynchronous, not an exact 24-hour deletion guarantee.

Use small, non-sensitive fixtures. Costs include the dedicated KMS key, S3
requests and storage, and the existing scanning and delivery services.

## Deployment dependencies

The harness depends on the parent incoming and clean buckets, the incoming
encryption key, and the hosted key at
`alias/s3/integration-hub-test-test-harness-pickup`. The shared test dispatch
module in turn looks up the harness destination key at
`alias/s3/integration-hub-file-transfer-test-test-harness`.

For the existing test installation, keep the shared routes present on `main`
and aligned across deploying branches. Deploy parent dispatch configuration
and the delivery/pickup components before applying the updated harness role.
A fresh installation requires staged bootstrapping of these key dependencies;
the complete configuration cannot be applied harness-first unchanged.

New dispatch secrets receive their initial configuration from Terraform.
Existing secret values must be maintained through the approved Secrets Manager
process; changing shared configuration alone does not update those values.
The harness outputs `destination_bucket_name` and `destination_kms_key_arn`
identify the push-to-S3 destination. See the
[push-to-S3 configuration contract](../push-to-s3/README.md#configuration-contract).

Before running live tests, confirm GitHub environment protection, deployed
recipient-group access, and the test account's Amazon Q Developer in chat
applications connection to the configured Slack workspace and channel. Review
plans through the deployment process and do not run tests while changing
routing or permissions.

Formatting can be checked from the repository root:

```shell
terraform fmt -check -recursive terraform/environments/integration-hub-file-transfer/test-harness
```

Formatting and Terraform validation do not verify deployed permissions, OIDC
access or file delivery. Runtime results must come from the live tests.