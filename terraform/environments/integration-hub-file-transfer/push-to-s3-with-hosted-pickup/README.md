# Push to S3 with hosted pickup

This component implements the Integration Hub `push-to-s3-with-hosted-pickup` supported pattern in a separate Terraform state in the same AWS account as the parent file-transfer component. It operates only in `eu-west-2`.

## Architecture

The component independently consumes `../modules/file-dispatch-configuration` with `environment = local.environment` and selects entries whose action name is `push-to-s3-with-hosted-pickup`. All maps and per-entry resources support an empty selection, so the component works with zero configured entries.

One shared pipeline handles every selected entry:

1. An EventBridge rule on the existing `integration-hub-file-transfer` custom bus selects matching `FileActionExecutionRequested.v1` events.
2. EventBridge publishes to an encrypted SNS topic. Exhausted EventBridge or SNS deliveries use an encrypted SQS dead-letter queue.
3. SNS sends wrapped notifications to an encrypted SQS queue.
4. The queue invokes one Lambda function with partial batch responses. Transient failures are retried and eventually moved to the dead-letter queue.
5. Lambda fetches the exact dispatch secret version, validates it against Terraform-authorised configuration, and assumes the exact mover role mapped to that secret ARN.
6. The mover role performs an S3-managed, multipart-capable copy of the exact clean object `VersionId` to its dedicated hosted bucket. The source object is retained.
7. Lambda publishes `FileActionExecutionCompleted.v1` directly to the existing custom bus.

The parent schema registry already defines and accepts `FileActionExecutionCompleted.v1`, and the Lambda publishes that schema directly over EventBridge. A `file-action-execution-completed-adapter` would have no transport or schema conversion to perform, so this component does not add a redundant adapter.

The Lambda is not attached to a VPC because it uses AWS service endpoints and does not require private-network access.

## Configuration contract

Configuration belongs in the shared file-dispatch configuration module. Do not add entries in this component. The exact secret shape is:

```hcl
action = {
  name = "push-to-s3-with-hosted-pickup"
  push_to_s3_with_hosted_pickup = {
    destination_prefix = "pickup/"
    retention_days     = 30
  }
}
notifications = {
  email = null
  slack = null
  teams = null
}
```

`destination_prefix` may be empty or must end with `/`; it must not start with `/`. `retention_days` must be a positive whole number.

The parent state creates predictable dispatch secrets. This state looks up only secret metadata and never reads secret values. At runtime, Lambda requests the exact `secretVersionId` carried by the event. ARN-keyed environment mappings bind that secret to one mover role, one clean source prefix, and one Terraform-authorised hosted destination. A secret is rejected if its destination prefix or retention period differs from Terraform. The bucket name, Region and KMS key are supplied only by Terraform and cannot be redirected through secret content.

The parent deliberately ignores secret-value changes. After changing an existing action in the shared Terraform configuration, update the corresponding secret value manually to match before sending files. A newly added entry receives its initial non-sensitive action value when the parent state first creates the secret.

When no hosted pickup entries are configured, the shared pipeline still deploys but no buckets, hosted KMS keys, or mover roles are created. Any matching event is rejected as unauthorised rather than being delivered to a fallback destination.

## Names and isolation

Shared pipeline resources use this base name:

```text
integration-hub-file-transfer-<environment>-push-to-s3-with-hosted-pickup
```

Each selected dispatch entry receives resources named from its stable 12-character entry ID:

```text
Bucket:     ihft-<environment>-hosted-pickup-<account-id>-<entry-id>
KMS alias: alias/s3/ihft-<environment>-hosted-pickup-<account-id>-<entry-id>
Mover role: ihft-<environment>-hosted-pickup-<entry-id>
```

The Lambda execution role cannot read the clean bucket or write hosted objects. It can read only selected dispatch secrets and assume only the mapped mover roles. Each mover role trusts only the predictable shared Lambda execution role, reads only its configured clean source prefix, copies the exact event `VersionId`, writes only its own destination prefix, and uses only the clean source key plus its dedicated hosted key. It has no permissions for another entry's hosted bucket or KMS key.

Every hosted bucket is a general purpose S3 bucket with bucket-owner-enforced ownership, no ACLs, all public access blocked, versioning, SSE-KMS with an S3 Bucket Key, TLS enforcement, and denial of missing or incorrect encryption headers and KMS keys. Its lifecycle expires current and noncurrent versions after `retention_days` and aborts incomplete multipart uploads after one day.

## Retention and costs

Each entry creates a dedicated S3 bucket, customer-managed KMS key, IAM role and policy. Costs include S3 storage and requests, KMS key and API usage, Lambda, EventBridge, SNS, SQS, DynamoDB and CloudWatch Logs. Versioning means overwritten or deleted objects remain billable as noncurrent versions until lifecycle expiry. Lifecycle expiration is asynchronous, so objects and charges can remain briefly after their configured expiry date. Longer retention periods directly increase stored byte-days; incomplete multipart uploads are limited by the one-day abort rule.

## Deferred customer pickup role

No externally assumable customer pickup or read role is created. The trusted principal contract for the retrieving workload has not been agreed, so adding a trust policy now would require an unsafe permissive placeholder. Once the customer principal contract is agreed, add a dedicated read-only role per entry with trust restricted to that exact principal and permissions restricted to that entry's bucket, destination prefix and KMS key.

## Deployment order

1. Update and deploy the parent `integration-hub-file-transfer` state. It creates the custom bus, clean bucket and key, and predictable dispatch secrets.
2. Populate any deferred notification values through the approved Secrets Manager process without changing the Terraform-authorised hosted prefix or retention period.
3. Deploy this `push-to-s3-with-hosted-pickup` state. It resolves parent resources by predictable AWS metadata lookups and does not consume parent Terraform state.
4. Confirm the `hosted_pickup_destinations` output and validate delivery with a non-sensitive test file.
5. Confirm the exact source version remains present, the hosted object uses the dedicated key, and a completion event is emitted.

Destroy or update this child state before removing parent resources. Removing the parent bus, clean bucket, keys or dispatch secrets first will make metadata lookups fail.

## Local validation

Run from the repository root without contacting AWS:

```shell
terraform fmt -check -recursive terraform/environments/integration-hub-file-transfer/push-to-s3-with-hosted-pickup
PYTHONPATH=terraform/environments/integration-hub-file-transfer/push-to-s3-with-hosted-pickup/lambda/file-mover \
  uv run --with pytest --with boto3 --with aws-lambda-powertools python -m pytest -q \
  terraform/environments/integration-hub-file-transfer/push-to-s3-with-hosted-pickup/lambda/file-mover/tests
python3 -m py_compile \
  terraform/environments/integration-hub-file-transfer/push-to-s3-with-hosted-pickup/lambda/file-mover/file_mover.py \
  terraform/environments/integration-hub-file-transfer/push-to-s3-with-hosted-pickup/lambda/file-mover/handler.py
```

Do not run `terraform init`, `terraform plan`, or `terraform apply` as part of local component validation.