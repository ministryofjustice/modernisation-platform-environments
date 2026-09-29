# Push to S3

This component implements the Integration Hub `push-to-s3` supported pattern in a separate Terraform state in the same AWS account as the parent file-transfer component.

## Architecture

The component reads the shared `../modules/file-dispatch-configuration` module independently and selects entries whose action name is `push-to-s3`. It works when that selection is empty.

One shared pipeline handles every selected entry:

1. An EventBridge rule on the existing `integration-hub-file-transfer` custom bus selects `FileActionExecutionRequested.v1` events for `push-to-s3`.
2. EventBridge publishes to an encrypted SNS topic, with a dedicated encrypted SQS DLQ for exhausted EventBridge deliveries.
3. SNS sends wrapped notifications to an encrypted SQS queue.
4. SNS and the processing queue each have a separate encrypted SQS DLQ. The queue invokes one Lambda function with partial batch responses, one record per invocation, a 900-second timeout, a 5,400-second visibility timeout and a maximum receive count of five; the mapping caps concurrency at five and has no batching window. Lambda has no reserved concurrency.
5. Lambda assumes the delivery role mapped to the validated dispatch secret ARN. That role reads only its clean-bucket source prefix and writes only its configured customer bucket prefix. S3 performs a managed multipart-capable server-side copy of the exact source `VersionId`; the source object is retained.
6. Lambda publishes `FileActionExecutionCompleted.v1` to the existing custom bus. A separate reporter consumes the three DLQs, normalises their original request envelopes and emits one non-retryable failed completion when delivery exhausts retries. Both functions claim one terminal outcome per action execution in the existing DynamoDB table.

The reporter has a 60-second timeout and consumes batches of up to ten messages. Each DLQ visibility timeout is at least 360 seconds.

Both Lambdas emit `WriterRecordFailed` or `ReporterRecordFailed` CloudWatch metrics when individual SQS records fail, even when Lambda returns HTTP 200 for partial batch responses. The child state alarms on these metrics as well as Lambda `Errors`, which remains useful for hard function failures. The alarms have no actions until an approved operational notification destination is connected.

The Lambda is not attached to a VPC because it uses public AWS service endpoints and does not need access to a private network.

## Delivery and retry contract

The mover copies the exact source `VersionId` to the destination key formed from the configured destination prefix and the source key relative to its authorised source prefix. The source object and its retention are unchanged. The mover does not read destination objects or lock keys for exclusive writing.

The parent clean bucket has a one-day current-version expiry and a one-day noncurrent-version expiry in both environments. A version can therefore remain after its current-version expiry until it ages out as noncurrent; S3 lifecycle removal is asynchronous. The seven-day lifecycle in production belongs to the quarantine and investigation buckets, not clean. Initial `IN_PROGRESS` claims have a seven-day DynamoDB TTL, and terminal records expire seven days after their last outcome update. A pending retry does not restart its seven-day TTL. TTL removal is asynchronous, and records no longer protect against duplicate copies once removed. This is not an exactly-once S3 write guarantee. If S3 accepts a copy but the SDK times out before receiving the result, a retry may overwrite the key or create another destination version. An unknown copy outcome does not establish that the destination object is absent. SDK timeouts and Lambda deadline failures follow the normal retry and DLQ path; no completion-latency guarantee is made.

For completed events, `actionDefinitionId` is the request's `configurationReference.secretArn` (the dispatch `secretARN`); the request has no separate definition ID. A terminal record for that action and secret prevents a later retry from copying while it exists. An existing `IN_PROGRESS` record is logically expired after seven days; the reporter emits failure when its request reaches a DLQ, and recovery requires a new action execution ID.

Before enabling an entry, confirm the source and destination bucket policies and KMS key policies allow the required copy, decrypt, encrypt and data-key operations, and that destination encryption headers are accepted. Customer-owned destination lifecycle and object-retention policies remain the customer's responsibility. Costs include S3 requests and stored versions, KMS key/API usage, Lambda duration, EventBridge, SNS, SQS, DynamoDB and CloudWatch Logs.

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
integration-hub-file-transfer-push-to-s3
```

Each dispatch entry receives one role and policy named:

```text
ihft-<environment>-push-to-s3-<12-character-entry-id>
```

The entry ID is the stable hash emitted by the shared module. The `delivery_roles` Terraform output maps each ID to its source and destination prefixes and role ARN.

The Lambda execution role can read only selected dispatch secrets and assume the configured delivery roles; it cannot read clean objects or write customer objects directly. The environment contains ARN-keyed maps from each dispatch secret to its source prefix and delivery role. Each delivery role trusts account root only when `aws:PrincipalArn` matches the exact component Lambda execution role; it can read only its configured clean source prefix and write only beneath its own destination prefix using the configured KMS keys. It cannot read another entry's source or write another entry's destination.

## Dead-letter operations

The `pipeline` output exposes `eventbridge_dlq_arn`, `sns_dlq_arn`, `processing_dlq_arn` and `dlq_reporter_arn`. The original `sqs_dlq_arn` and queue name are retained as the processing DLQ to avoid replacement. Before enabling the reporter, inspect and resolve any pre-existing messages on that formerly shared queue: older EventBridge messages may have a different envelope. Malformed or unrecognised requests remain in their DLQ for investigation.

Each DLQ has a CloudWatch visible-message backlog alarm. The component also alarms on mover/reporter errors and throttles, near-timeout duration, and processing-message age. These child states have no approved notification topic output, so alarms have no actions until operators connect them to the operational notification destination; this is a production notification gate. Monitor reporter failures as well: a retry can keep a message in flight without a visible backlog. DLQs retain messages for 14 days, longer than DynamoDB's seven-day markers; a late reporter may create a new failure record after the original marker has been removed. Inspect old messages rather than redriving them: once a `FileActionExecutionCompleted.v1` failure has been emitted, never manually redrive that `actionExecutionId` to seek a successful completion; create a new request with a new action execution ID instead. An accepted EventBridge publication followed by a failed DynamoDB marker write may repeat the *same* completion detail; consumers must deduplicate using the completion idempotency key.

## Customer responsibilities

The customer owns the destination bucket, retention controls, and customer-managed KMS key. Before enabling an entry, its team must:

- keep S3 Block Public Access and encryption at rest enabled
- allow the reported delivery role `s3:PutObject`, `s3:AbortMultipartUpload`, and `s3:ListMultipartUploadParts` only beneath the agreed destination prefix
- allow the same role `kms:Encrypt`, `kms:GenerateDataKey*`, and `kms:Decrypt` on the configured KMS key
- ensure the bucket and KMS key are in `eu-west-2`
- configure lifecycle cleanup for incomplete multipart uploads

Bucket names, prefixes, regions, and KMS key ARNs are non-sensitive configuration. Credentials, file contents, passwords, private keys, and notification destinations must not be committed. Populate deferred sensitive secret values manually in Secrets Manager.

## Deployment order

1. Update and deploy the parent `integration-hub-file-transfer` state. This creates the custom bus, clean bucket and KMS key, and dispatch secrets with predictable names.
2. Populate any deferred sensitive values in the exact dispatch secret version through the approved operational process.
3. Deploy this `push-to-s3` state. Its AWS metadata data sources resolve the parent resources without remote-state coupling.
4. Give each destination owner the `delivery_roles` output and have them update their bucket and KMS key policies.
5. Validate delivery with a non-sensitive test file and confirm the completion event and destination object version.

Removing a parent resource before this state will make metadata lookup fail. Destroy or update the child state first when decommissioning the pattern.

## Local validation

The Lambda package is built from this component's `lambda/push-to-s3-writer` directory. Its pinned `requirements.txt` is installed into the deployment package; `tests/requirements.txt` contains test-only dependencies. Each component has its own writer copy and tests; CI tests both copies, while a change under this component selects only this Terraform state.

Run from the repository root without contacting AWS:

```shell
terraform fmt -check -recursive terraform/environments/integration-hub-file-transfer/push-to-s3
env AWS_ACCESS_KEY_ID=dummy AWS_SECRET_ACCESS_KEY=dummy AWS_SESSION_TOKEN=dummy \
  AWS_DEFAULT_REGION=eu-west-2 AWS_EC2_METADATA_DISABLED=true \
  PYTHONPATH=terraform/environments/integration-hub-file-transfer/push-to-s3/lambda/push-to-s3-writer \
  uv run --no-project --python 3.12 \
  --with-requirements terraform/environments/integration-hub-file-transfer/push-to-s3/lambda/push-to-s3-writer/requirements.txt \
  --with-requirements terraform/environments/integration-hub-file-transfer/push-to-s3/lambda/push-to-s3-writer/tests/requirements.txt \
  python -m pytest -q terraform/environments/integration-hub-file-transfer/push-to-s3/lambda/push-to-s3-writer/tests
```

The test command uses dummy credentials and disables EC2 metadata lookup; it makes no AWS calls. Do not run `terraform init`, `terraform validate`, `terraform plan`, or `terraform apply` as part of local component validation.