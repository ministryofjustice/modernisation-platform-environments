# Push to S3

This component implements the Integration Hub `push-to-s3` supported pattern in a separate Terraform state in the same AWS account as the parent file-transfer component.

## Architecture

The component reads the shared `../modules/file-dispatch-configuration` module independently and selects entries whose action name is `push-to-s3`. It works when that selection is empty.

One shared pipeline handles every selected entry:

1. An EventBridge rule on the existing `integration-hub-file-transfer` custom bus selects `FileActionExecutionRequested.v1` events for `push-to-s3`.
2. EventBridge publishes to an encrypted SNS topic, with a dedicated encrypted SQS DLQ for exhausted EventBridge deliveries.
3. SNS sends wrapped notifications to an encrypted SQS queue.
4. SNS and the processing queue each have a separate encrypted SQS DLQ. The queue invokes one Lambda function with partial batch responses; exhausted transient records move to the processing DLQ. The SQS mapping caps concurrency at five; Lambda has no reserved concurrency.
5. Lambda assumes the delivery role mapped to the validated dispatch secret ARN. That role reads only its clean-bucket source prefix and writes only its configured customer bucket prefix. S3 performs a managed multipart-capable server-side copy of the exact source `VersionId`; the source object is retained.
6. Lambda publishes `FileActionExecutionCompleted.v1` to the existing custom bus. A separate reporter consumes the three DLQs, normalises their original request envelopes and emits one non-retryable failed completion when delivery exhausts retries. Both functions claim one terminal outcome per action execution in the existing DynamoDB table.

The Lambda is not attached to a VPC because it uses public AWS service endpoints and does not need access to a private network.

## Configuration contract

Configuration belongs in the shared file-dispatch configuration module. Do not add entries in this component. A selected entry has this shape:

```hcl
action = {
  name = "push-to-s3"
  push_to_s3 = {
    bucket_id          = "customer-bucket-name"
    bucket_region      = "eu-west-2"
    destination_prefix = "agreed-prefix/"
    kms_key_arn        = "customer-managed KMS key ARN"
  }
}
```

`bucket_region` may be omitted and defaults to `eu-west-2`. No other region is supported. `destination_prefix` may be empty or must end with `/`; it must not start with `/`.

Terraform creates or discovers the dispatch secret but never reads its value. Operators must populate sensitive values through the established Secrets Manager process after the parent state creates the secret. The Lambda requests the exact `secretVersionId` carried by the event and validates the complete action structure before delivery. It also compares the destination bucket, prefix, Region, and KMS key with an immutable map generated from Terraform; changing those fields only in Secrets Manager is rejected and cannot redirect a delivery.

The parent deliberately ignores secret-value changes. After changing an existing action in the shared Terraform configuration, update the corresponding secret value manually to match before sending files. A newly added entry receives its initial non-sensitive action value when the parent state first creates the secret.

## Names and isolation

Shared resources use the predictable base name:

```text
integration-hub-file-transfer-<environment>-push-to-s3
```

Each dispatch entry receives one role and policy named:

```text
ihft-<environment>-push-to-s3-<12-character-entry-id>
```

The entry ID is the stable hash emitted by the shared module. The `delivery_roles` Terraform output maps each ID to its source and destination prefixes and role ARN.

The Lambda execution role can read only selected dispatch secrets and assume the configured delivery roles; it cannot read clean objects or write customer objects directly. The environment contains ARN-keyed maps from each dispatch secret to its source prefix and delivery role. Each delivery role trusts account root only when `aws:PrincipalArn` matches the exact component Lambda execution role; it can read only its configured clean source prefix and write only beneath its own destination prefix using the configured KMS keys. It cannot read another entry's source or write another entry's destination.

## Dead-letter operations

The `pipeline` output exposes `eventbridge_dlq_arn`, `sns_dlq_arn`, `processing_dlq_arn` and `dlq_reporter_arn`. The original `sqs_dlq_arn` and queue name are retained as the processing DLQ to avoid replacement. Before enabling the reporter, inspect and resolve any pre-existing messages on that formerly shared queue: older EventBridge messages may have a different envelope. Malformed or unrecognised requests remain in their DLQ for investigation.

Each DLQ has a CloudWatch visible-message backlog alarm. These child states have no approved notification topic output, so alarms have no actions until operators connect them to the operational notification destination. Monitor oldest-message age and reporter failures as well: a reporter retry can keep a message in flight without a visible backlog. The terminal-outcome record expires after 90 days. Once a `FileActionExecutionCompleted.v1` failure has been emitted, never manually redrive that `actionExecutionId` to seek a successful completion; create a new request with a new action execution ID instead. An accepted EventBridge publication followed by a failed DynamoDB marker write may repeat the *same* completion detail; consumers must deduplicate using the completion idempotency key.

## Customer responsibilities

The customer owns the destination bucket, retention controls, and customer-managed KMS key. Before enabling an entry, its team must:

- keep S3 Block Public Access and encryption at rest enabled
- allow the reported delivery role `s3:PutObject`, `s3:AbortMultipartUpload`, and `s3:ListMultipartUploadParts` only beneath the agreed destination prefix
- allow the same role `kms:Encrypt`, `kms:GenerateDataKey*`, and `kms:Decrypt` on the configured KMS key
- ensure the bucket and KMS key are in `eu-west-2`

Bucket names, prefixes, regions, and KMS key ARNs are non-sensitive configuration. Credentials, file contents, passwords, private keys, and notification destinations must not be committed. Populate deferred sensitive secret values manually in Secrets Manager.

## Deployment order

1. Update and deploy the parent `integration-hub-file-transfer` state. This creates the custom bus, clean bucket and KMS key, and dispatch secrets with predictable names.
2. Populate any deferred sensitive values in the exact dispatch secret version through the approved operational process.
3. Deploy this `push-to-s3` state. Its AWS metadata data sources resolve the parent resources without remote-state coupling.
4. Give each destination owner the `delivery_roles` output and have them update their bucket and KMS key policies.
5. Validate delivery with a non-sensitive test file and confirm the completion event and destination object version.

Removing a parent resource before this state will make metadata lookup fail. Destroy or update the child state first when decommissioning the pattern.

## Local validation

Run from the repository root without contacting AWS:

```shell
terraform fmt -check -recursive terraform/environments/integration-hub-file-transfer/push-to-s3
PYTHONPATH=terraform/environments/integration-hub-file-transfer/push-to-s3/lambda/file-mover \
  uv run --with pytest --with boto3 python -m pytest -q \
  terraform/environments/integration-hub-file-transfer/push-to-s3/lambda/file-mover/tests
python3 -m py_compile \
  terraform/environments/integration-hub-file-transfer/push-to-s3/lambda/file-mover/file_mover.py \
  terraform/environments/integration-hub-file-transfer/push-to-s3/lambda/file-mover/handler.py \
  terraform/environments/integration-hub-file-transfer/push-to-s3/lambda/file-mover/dlq_reporter.py \
  terraform/environments/integration-hub-file-transfer/push-to-s3/lambda/file-mover/terminal_outcome.py \
  terraform/environments/integration-hub-file-transfer/push-to-s3/lambda/file-mover/reporter_handler.py
```

Do not run `terraform init`, `terraform plan`, or `terraform apply` as part of local component validation unless the deployment workflow explicitly requires it.