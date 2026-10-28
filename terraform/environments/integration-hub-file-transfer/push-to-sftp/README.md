# Push to SFTP

This component delivers exact clean S3 object versions to configured SFTP recipients in a separate Terraform state in the parent file-transfer account. It operates in `eu-west-2`.

## Architecture

The component selects `push-to-sftp` entries from the shared [file-dispatch configuration](../modules/file-dispatch-configuration/README.md#action-configuration). One EventBridge rule routes `FileActionExecutionRequested.v1` events through encrypted SNS and SQS to the writer Lambda. EventBridge, SNS and processing each have a separate encrypted DLQ; a reporter consumes these and publishes terminal outcomes to the existing event bus.

The SNS topic is module-managed; its policy and subscription are explicit resources.

EventBridge grants follow the [SNS topic-policy guidance](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-use-resource-based.html#sns-permissions) and [SNS KMS guidance](https://docs.aws.amazon.com/sns/latest/dg/sns-key-management.html#compatibility-with-aws-services): the publish grant is scoped to this topic and the encryption grant to its transport key, both for `events.amazonaws.com`. Source-account/ARN conditions are omitted from these grants; AWS does not support them for EventBridge-to-encrypted-topic KMS access.

The shared pipeline remains deployed and enabled with no entries. Per-entry roles and keypair secrets are then absent, and both Lambdas reject requests without an authorised configuration. There is no manual enablement switch. Deployed infrastructure alone does not establish recipient readiness or customer-supported availability.

The writer processes one message at a time, with a 900-second timeout, maximum concurrency of five, 5,400-second queue visibility and five receives before dead-lettering. The reporter uses batches of ten, a 60-second timeout and maximum concurrency of two per DLQ; DLQ visibility is 360 seconds. Both return partial batch failures.

## Configuration and deployment

1. Deploy the parent state first: this component looks up its event bus, clean bucket, KMS keys and PagerDuty topics by name.
2. Configure the recipient in the shared module and deploy the parent dispatch secret and this component. For an existing dispatch secret, update its action through the approved Secrets Manager process: the parent ignores subsequent secret-value changes.
3. Use `credential_secrets` and `operator_policy_arns` to populate the per-entry keypair secrets through approved operator tooling. Policies are created but not attached. The private secret contains JSON with `private_key` and an optional `passphrase`; the public secret holds the OpenSSH client public key for the recipient. Never put private keys or passphrases in Terraform, events or logs.
4. Have the recipient install the client public key. Verify server host keys independently, approved IPv4 CIDRs, the account's existing destination directory and support for exclusive temporary-file creation and POSIX overwrite rename.
5. Before sending service files, validate the route with a non-sensitive fixture and confirm the remote file and completion event. Terraform provisioning is not an interoperability test.

The writer retrieves the exact dispatch secret version referenced by the request and compares it with Terraform-authorised destination settings. It assumes the entry's delivery role to read only its clean source prefix and private-key secret. Credentials use `AWSCURRENT`; rotate through approved custodians, coordinating recipient authorisation before switching the current key.

The writer uses shared private subnets: one deterministically selected subnet in development/test, all selected subnets in preproduction/production. Egress permits approved SFTP CIDRs/ports, HTTPS to shared protected-subnet CIDRs, and HTTPS to the regional AWS-managed S3 and DynamoDB prefix lists. SFTP rules use the same normalised destinations as the writer, with one rule per unique CIDR/port pair across all entries. Prefix-list rules permit traffic but do not create routes or endpoints: verify S3/DynamoDB gateway endpoint routes and reachable private endpoints for STS, Secrets Manager and EventBridge, plus the recipient path.

## Delivery and recovery

The destination path is the configured relative prefix plus the source key relative to its authorised source prefix. The writer streams the exact S3 version into a temporary remote file, verifies byte counts and renames it over the destination. The clean source is retained under the parent's lifecycle policy; remote retention belongs to the recipient.

DynamoDB stores leases, a `COPIED` checkpoint and terminal outcomes. A retry after `COPIED` republishes completion without uploading again. Deduplication and terminal retention use seven-day windows; TTL removal is asynchronous and does not extend source-file availability.

A failure before the checkpoint may leave an uncertain remote outcome, and a retry may overwrite the destination. This is not exactly-once delivery. Do not delete idempotency records, bypass leases or manufacture requests to force recovery. Investigate uncertain outcomes with the recipient before further delivery; a failed completion does not prove the remote file is absent. Malformed or unauthorised DLQ messages remain for investigation.

## Outputs and monitoring

`pipeline` exposes the rule, topic, processing queue, three DLQs and reporter ARNs. `delivery_roles` maps entries to their identity, source prefix, destination hostname/prefix and role ARN. Existing role-ARN, queue-URL, credential and operator-policy outputs remain available.

[CloudWatch alarms](./locals-cloudwatch.tf) cover DLQ backlogs, record failures, Lambda errors/throttles/duration, processing-message age and terminal delivery failures. They use the parent's PagerDuty priority routing. Terminal delivery failure alarms do not send OK notifications: resolve incidents after investigation, not when the metric goes quiet.

## Local validation

The ARM64 Python 3.12 packages are built in Docker using pinned runtime dependencies. Run from the repository root without contacting AWS:

```shell
terraform fmt -check -recursive terraform/environments/integration-hub-file-transfer/push-to-sftp
env AWS_ACCESS_KEY_ID=dummy AWS_SECRET_ACCESS_KEY=dummy AWS_SESSION_TOKEN=dummy \
  AWS_DEFAULT_REGION=eu-west-2 AWS_EC2_METADATA_DISABLED=true \
  PYTHONPATH=terraform/environments/integration-hub-file-transfer/push-to-sftp/lambda/push-to-sftp-writer \
  uv run --no-project --python 3.12 \
  --with-requirements terraform/environments/integration-hub-file-transfer/push-to-sftp/lambda/push-to-sftp-writer/requirements.txt \
  --with-requirements terraform/environments/integration-hub-file-transfer/push-to-sftp/lambda/push-to-sftp-writer/tests/requirements.txt \
  python -m pytest -q terraform/environments/integration-hub-file-transfer/push-to-sftp/lambda/push-to-sftp-writer/tests
```

Tests use dummy credentials and disable EC2 metadata lookup. Run plans and deployments through the existing Terraform workflow, not as part of these local checks.
