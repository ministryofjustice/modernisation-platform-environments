# Recovering failed file mover operations

This runbook covers failures in the Integration Hub file-transfer Lambda functions:

- `integration-hub-file-transfer-stage`, which performs the `STAGE` operation from `incoming` to `processing`; and
- `integration-hub-file-transfer-route`, which performs the `ROUTE` operation from `processing` to `clean`, `quarantine` or `investigation`.

Each mover uses AWS Lambda Powertools to deduplicate the same EventBridge event ID and a separate DynamoDB operation record keyed by `(concurrencyId, operation)`. The operation record is a leased lock and a durable recovery checkpoint. Do not delete or reset it to force a replay.

## Recovery order

Use these recovery mechanisms in order:

1. Allow Lambda's asynchronous retries to resume the operation after its lease expires.
2. Correct a transient dependency or IAM failure and redrive the original event from the Lambda dead-letter queue.
3. Redrive the original canonical event from the shared EventBridge dead-letter queue if EventBridge could not invoke Lambda.
4. Escalate for manual reconciliation if an S3 side effect or EventBridge publication is ambiguous.

Never construct a replacement event by hand. The top-level EventBridge ID, correlation ID and exact S3 version are part of the operation contract.

## Check the alarms and logs

Identify the failed operation from the Lambda, EventBridge or SQS alarm. Search the relevant Lambda log group for the source event ID or correlation ID. Do not log or retrieve object content during recovery.

Check these queues:

- the STAGE or ROUTE Lambda dead-letter queue for events accepted by Lambda but exhausted after asynchronous retries; and
- the shared file-transfer EventBridge dead-letter queue for events that EventBridge could not deliver to Lambda.

Correct the underlying problem before redriving a message.

## Inspect the operation record

The following read-only commands require AWS CLI v2 and `jq`. Run them from a trusted operator workstation with an approved AWS session.

```zsh
region="eu-west-2"
environment="<development|production>"
correlation_id="<correlation-id>"
operation="<STAGE|ROUTE>"
table_name="integration-hub-file-transfer-${environment}-file-transfer-idempotency"

key=$(
  jq -nc \
    --arg correlation_id "$correlation_id" \
    --arg operation "$operation" \
    '{
      concurrencyId: {S: $correlation_id},
      operation: {S: $operation}
    }'
)

aws dynamodb get-item \
  --region "$region" \
  --table-name "$table_name" \
  --key "$key" \
  --consistent-read \
  --output json
```

Record the status, owner, lease expiry, source bucket/key/version, destination version, multipart upload ID, copy token, receipt version and output EventBridge ID where present.

## Interpret the checkpoint

| Status | Meaning | Recovery action |
| --- | --- | --- |
| `IN_PROGRESS` | Claimed, with no durable copy checkpoint | Wait for an active lease. After expiry, redrive the original event. |
| `MULTIPART_CREATED` | A known multipart upload exists | Redrive after lease expiry. The mover lists parts and copies only missing ranges. |
| `MULTIPART_ABORTED` | A handled copy failure was aborted | Correct the failure and redrive after lease expiry. A new upload will be created. |
| `COPIED` | The exact destination version is stored | Redrive. The mover verifies that version and does not create another copy. |
| `VERIFIED` | Destination attributes have been verified | Redrive. The mover deletes only the recorded source version. |
| `SOURCE_DELETED` | The exact source version was deleted | Redrive. The mover does not read or copy the deleted source. |
| `RECEIPT_CREATED` | The optional STAGE receipt version is stored | Redrive. The mover proceeds to publication. |
| `PUBLISHED` | EventBridge accepted the completion event | Redrive. The mover only marks the operation `COMPLETED`. |
| `COMPLETED` | The operation finished | Do not redrive or remove the record. |

An unhandled timeout can leave an incomplete multipart upload. The destination buckets abort incomplete uploads after one day. Do not manually abort an upload unless its upload ID exactly matches the operation record and no invocation holds an active lease.

## Exact-version checks

Before redriving a record before `SOURCE_DELETED`, confirm that the recorded exact source version exists:

```zsh
aws s3api head-object \
  --region "$region" \
  --bucket "<source-bucket>" \
  --key "<source-key>" \
  --version-id "<source-version-id>" \
  --expected-bucket-owner "<account-id>"
```

For `COPIED` or later, inspect the exact recorded destination version. Check its size, SSE-KMS key, metadata, tags and content headers. Do not use the latest object version as a substitute.

Stop and escalate when:

- a source version is missing before `SOURCE_DELETED`;
- the destination version does not match the operation record;
- more than one destination version carries the deterministic copy token;
- multipart completion may have succeeded but no unique destination version can be identified; or
- publication may have succeeded but the operation is not `PUBLISHED`.

EventBridge acceptance and the DynamoDB `PUBLISHED` checkpoint are not atomic. A publication retry can therefore produce two envelopes with the same `detail.metadata.idempotencyKey`. This is expected at-least-once behaviour; consumers must deduplicate that key.

## Redrive a failed event

Use the AWS console or the approved operational process to redrive the original message from its DLQ. Preserve the complete message body and message attributes. A redrive is safe only after the operation lease has expired or the previous invocation has demonstrably ended.

Monitor the mover logs and operation record until it reaches `COMPLETED`. Confirm the completion event contains the stored destination version and deterministic idempotency key.

## Prohibited recovery actions

Do not:

- delete or alter the DynamoDB operation record to bypass a checkpoint;
- remove Powertools idempotency records manually;
- replay from the original source after `SOURCE_DELETED`;
- delete a destination version carrying a mover copy token without establishing the exact operation state;
- abort a multipart upload used by an active lease; or
- change a GuardDuty result tag to force a route.

When side effects are ambiguous, preserve the record and object versions. Escalation is safer than creating another destination version or deleting the wrong source version.