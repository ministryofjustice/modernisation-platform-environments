# File-transfer test harness

This component provides test-only infrastructure for an Integration Hub repository smoke test using direct S3 uploads. The test checks that a file can pass through the existing scanning and delivery pipeline and arrive unchanged at an isolated destination.

The component provisions a GitHub OIDC IAM role, a private destination bucket and a dedicated KMS encryption key using Terraform registry modules. Resources are created only in the test environment. The parent file-transfer and `push-to-s3` components own routing and delivery.

Smoke-test scripts and GitHub Actions workflow configuration are outside this component's scope.

## Architecture

The harness uses the existing file-transfer pipeline rather than deploying a separate delivery pipeline:

1. The harness role uploads a non-sensitive fixture beneath `test-harness/repo-smoke-test/direct-s3/` in the test incoming bucket.
2. The parent file-transfer pipeline scans the file and routes the clean object through the shared dispatch configuration.
3. The `push-to-s3` component assumes its delivery role and copies the clean object to the harness-owned destination beneath `delivered/repo-smoke-test/direct-s3/`.
4. The harness role downloads the delivered object and compares it with the original fixture.

The harness role does not deliver files itself. A successful test requires the
parent pipeline and `push-to-s3` configuration to be deployed and authorised.

## Configuration contract

The route belongs in the shared
[`file-dispatch-configuration` module](../modules/file-dispatch-configuration/locals-test.tf), under the test environment's `test-harness` identity and `/repo-smoke-test/direct-s3/` source prefix. Its action is `push-to-s3`, with these destination settings:

| Setting | Value |
| --- | --- |
| `bucket_id` | `integration-hub-file-transfer-test-test-harness` |
| `bucket_region` | `eu-west-2` |
| `destination_prefix` | `delivered/repo-smoke-test/direct-s3/` |
| `kms_key_arn` | The key ARN resolved from `alias/s3/integration-hub-file-transfer-test-harness-test-delivery` |

This component exposes `destination_bucket_name` and `destination_kms_key_arn`.
Use the deployed outputs to verify the shared route, especially after replacing
the destination key. The shared module looks up the destination key alias only
in the test environment. The alias must exist before planning the parent or `push-to-s3` component, and the deployment role must be able to read it. If the alias points to a replacement key, a new plan reads that key's ARN; an existing dispatch secret still needs updating through the process below.

New dispatch entries receive their initial non-sensitive action value when the
parent state creates their secret. For an existing entry, update the secret
value through the approved Secrets Manager process to match any changed action.
See the [push-to-s3 configuration contract](../push-to-s3/README.md#configuration-contract).

## Names and isolation

Resources are created only in the test environment. The smoke test uses:

| Resource | Name or prefix |
| --- | --- |
| Incoming bucket | `integration-hub-file-transfer-test-incoming` |
| Upload prefix | `test-harness/repo-smoke-test/direct-s3/` |
| Destination bucket | `integration-hub-file-transfer-test-test-harness` |
| Delivery prefix | `delivered/repo-smoke-test/direct-s3/` |

GitHub OIDC trust is restricted to jobs using the `smoke-test` environment in
`ministryofjustice/integration-hub`, with audience `sts.amazonaws.com`. The
workflow job must declare `environment: smoke-test` and grant `id-token: write`.
Jobs without this environment do not match the trust policy, including jobs on
`main`.

Before using this role, create and protect the `smoke-test` GitHub environment
with deployment branch restrictions and required reviewers. Allow `main` and
the authorised feature branches needed to test changes before merging. The IAM
trust policy does not restrict branches itself; access is controlled by the
GitHub environment's protection rules.

The harness role can upload only beneath its incoming prefix, list and read only
its destination prefix, and use the relevant KMS keys only through S3 with the
configured encryption contexts. It has no destination-write, delete or
administrative permissions. Delivery uses a separate role managed by `push-to-s3`.

## Retention and costs

The destination blocks public access, enforces TLS and bucket-owner-enforced
ownership, and uses versioning and SSE-KMS with its dedicated key. Incorrect
encryption headers or a different KMS key are rejected. S3 Bucket Keys are disabled.

Lifecycle rules expire current and noncurrent objects after one day, abort
incomplete multipart uploads after one day, and remove expired delete markers.
Cleanup is asynchronous; it is not a guarantee that objects disappear exactly
24 hours after upload. The harness role cannot delete test objects manually.

Costs include the dedicated KMS key, S3 requests and stored versions, and use of
the existing scanning and delivery pipeline. Use small, non-sensitive fixtures.

## Smoke-test procedure

Run only against `integration-hub-file-transfer-test` after deploying the
components and configuring GitHub environment access.

1. Upload a small, non-sensitive fixture to `integration-hub-file-transfer-test-incoming` at `test-harness/repo-smoke-test/direct-s3/<unique-run-token>/payload.txt`.
2. Wait for `push-to-s3` delivery to the harness-owned destination at `delivered/repo-smoke-test/direct-s3/<unique-run-token>/payload.txt`.
3. Download the delivered object and compare its contents with the fixture. Fail on timeout or content mismatch.

Use a fresh run token for every execution to avoid matching stale files.

Run the upload and download using the harness role to verify its permissions as
well as delivery. A manual test using an operator's credentials verifies the
pipeline path but does not establish that GitHub OIDC or harness access works.

If delivery does not arrive within the test's timeout, inspect the parent
pipeline and `push-to-s3` CloudWatch logs and dead-letter queues. Do not manually copy the fixture into the destination to make the test pass. Follow the
[push-to-s3 dead-letter guidance](../push-to-s3/README.md#dead-letter-operations) before retrying failed deliveries.

## Coverage limits

The smoke-test procedure covers direct-S3 staging, scanning, clean routing,
dispatch and delivery.

It does not test customer authentication, SFTP, FTPS, HTTP API or browser uploads; negative scan outcomes; retry or idempotency guarantees; or completion-event assertions. Notifications remain a later step.

## Deployment order

1. Confirm the parent test file-transfer infrastructure exists, including the incoming and clean buckets and their KMS keys.
2. Deploy this test-harness component and confirm its destination bucket and KMS key outputs. Destination creation must not depend on the delivery role.
3. Confirm the destination key alias exists and that the shared test dispatch route resolves the expected key ARN, then deploy the parent file-transfer state to create or update the dispatch secret.
4. For an existing dispatch entry, ensure its secret value matches the configured action through the approved Secrets Manager process.
5. Deploy the `push-to-s3` state and confirm its delivery role has the required destination bucket and KMS access.
6. Run the smoke test using the harness role and confirm the delivered contents match the fixture.

Review Terraform plans before applying and confirm the parent and `push-to-s3`
deployments before running the test. Do not run smoke tests while changing role
permissions or routing. A successful plan does not establish successful delivery.

## Local validation

Run the formatting check from the repository root without contacting AWS:

```shell
terraform fmt -check -recursive terraform/environments/integration-hub-file-transfer/test-harness
```

Formatting and Terraform validation do not verify deployed permissions, GitHub
OIDC access or file delivery. Review plans and applies separately through the
deployment process, then use the smoke test for runtime verification.