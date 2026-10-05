# File-transfer test harness

## Status

Terraform configuration passes local validation. AWS deployment and
successful smoke-test execution have not yet been verified.

## Proposed first smoke test

Run only against integration-hub-file-transfer-test.

1. Upload a small, non-sensitive fixture to `integration-hub-file-transfer-test-incoming` at `test-harness/direct-s3/<unique-run-token>/payload.txt`.
2. Wait for `push-to-s3` delivery to the harness-owned destination at `delivered/direct-s3/<unique-run-token>/payload.txt`.
3. Download the delivered object and compare its contents with the fixture. Fail on timeout or content mismatch.

Use a fresh run token for every execution to avoid matching stale files.

## Coverage limits

This tests direct-S3 staging, scanning, clean routing, dispatch and delivery.

It does not test customer authentication, SFTP, FTPS, HTTP API or browser uploads; negative scan outcomes; retry or idempotency guarantees; or completion-event assertions. Notifications remain a later step.

## Ownership and deployment dependencies

This component owns the harness role, destination bucket and KMS key.

Provision the destination before configuring the shared delivery route. Use verified destination outputs for that route, then check delivery-role access before running tests. Destination creation must not depend on the delivery role.

Shared dispatch and `push-to-s3` changes are managed separately. Merging Terraform does not prove it has been applied.