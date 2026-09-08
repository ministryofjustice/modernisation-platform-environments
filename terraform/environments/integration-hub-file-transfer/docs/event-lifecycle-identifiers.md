# Tracking a file across its lifecycle

When a file arrives in the `incoming` S3 bucket, this service emits canonical events as the file is staged, scanned and routed. Stable identifiers link those events even though the S3 bucket and object version change.

## Identifiers

**`detail.data.fileId`** is the stable logical file identifier. It is created at ingress and copied into every later event.

**`detail.metadata.correlationId`** is the primary operational search key and groups every event and action request in one file lifecycle. It currently has the same value as `fileId`, but remains a separate tracing concept.

**`detail.metadata.causationId`** is the top-level EventBridge `id` of the event that caused the current event. `FileReceived.v1` has no causation ID because it starts the canonical chain.

**`detail.metadata.idempotencyKey`** identifies a producer operation. Consumers must use it to deduplicate retries. EventBridge publication and the mover's `PUBLISHED` DynamoDB checkpoint are not atomic, so two envelopes may have different EventBridge IDs but the same deterministic idempotency key.

The top-level EventBridge **`id`** identifies one event envelope. It is not stable across separate publications and must not be used as the logical file identifier.

## Ingress

S3 sends an `Object Created` event to EventBridge when a file lands in `incoming`. The file-received adapter publishes `FileReceived.v1` to the file-transfer event bus.

The adapter calculates `fileId` and `correlationId` as a deterministic UUID derived from the bucket, key and exact S3 version ID. Its idempotency key is `bucket:key:versionId`. Two uploads at the same key therefore remain distinct files.

AWS Lambda Powertools deduplicates retries of the same native EventBridge event ID. S3 can still emit separate notifications for one object version; those notifications have different EventBridge IDs but produce the same stable file identity. Delivery is at least once.

## Staging

The STAGE Lambda mover consumes `FileReceived.v1` and claims a leased DynamoDB record keyed by `(correlationId, STAGE)`. Immutable source fields are checked whenever an existing operation is claimed.

The mover copies the exact source version to the same key in `processing`. Every positive-size object uses multipart copy, including a one-byte object. A legitimate zero-byte business object uses `CopyObject`.

The mover preserves user metadata, tags and supported content headers, adds reserved correlation and copy-token metadata, and applies the processing bucket's SSE-KMS key. It verifies the exact destination version before deleting only the exact incoming version.

When STAGE receipts are enabled, the mover creates the receipt only after source deletion. An incoming object is exempt as an existing receipt only when its key ends in `.receipt` and that exact object version has the tag `Receipt=TRUE`.

The mover publishes `FileStagedForScanning.v1` with the original `fileId` and `correlationId`, the `FileReceived.v1` EventBridge ID as `causationId`, and both exact S3 versions.

## Scanning and routing

The GuardDuty adapter reads `mft-correlation-id` from the exact processing version and requires the durable STAGE record to be `COMPLETED`. It publishes terminal scan outcomes as `FileScanResultRecorded.v1`.

The ROUTE Lambda mover consumes that event and claims a separate `(correlationId, ROUTE)` record. The canonical event is authoritative, so `detail.data.scanResultStatus` selects the route:

- `NO_THREATS_FOUND` routes to `clean`;
- `THREATS_FOUND` routes to `quarantine`; and
- `UNSUPPORTED`, `ACCESS_DENIED` or `FAILED` routes to `investigation`.

`scanResultStatusMatchesTag` is retained as diagnostic provenance from the adapter. A mismatch overrides the reported scan result and routes the object to `investigation`.

ROUTE copies and verifies the exact processing version with destination SSE-KMS encryption before deleting that exact source version. It then publishes `FileRouted.v1` with an idempotency key of `route:{route}:{destinationBucket}:{key}:{destinationVersionId}`.

## Action dispatch

The file action execution requested adapter consumes clean `FileRouted.v1` events and uses the source event's `idempotencyKey` for Lambda-level deduplication. Replaying the same logical route under a different EventBridge envelope ID therefore does not republish requests while its idempotency record exists.

Each configured operation produces a `FileActionExecutionRequested.v1` event. Its `actionExecutionId` is a deterministic UUID derived from the source route idempotency key, matched secret ARN, exact secret version ID and stable operation ID. Its output idempotency key is `action-request:{actionExecutionId}`. Rotating the configuration to a new secret version intentionally produces a new execution identity.

The requested event retains the original `fileId` and `correlationId`, and uses the `FileRouted.v1` EventBridge ID as `causationId`. One request may fan out to multiple downstream queues. Each consumer must deduplicate independently on `actionExecutionId` or the equivalent output `idempotencyKey`.

## Durable recovery

The mover records these operation checkpoints:

- `IN_PROGRESS`
- `MULTIPART_CREATED`
- `MULTIPART_ABORTED`
- `COPIED`
- `VERIFIED`
- `SOURCE_DELETED`
- optional `RECEIPT_CREATED`
- `PUBLISHED`
- `COMPLETED`

A retry resumes the recorded multipart upload, destination version or later checkpoint instead of starting the operation again. Failures are recovered through Lambda retries or DLQ redrive after the lease expires. Do not delete or reset operation records to force a replay.

Idempotency records expire after 30 days in non-production environments and 400 days in production, matching event retention.

## Following and diagnosing a file

Start operational investigation with `correlationId`: query the file-transfer event bus archive for `detail.metadata.correlationId` and CloudWatch Logs for `correlation_id` to find the complete lifecycle. To reconstruct causality, start with `FileReceived.v1` and find the event whose `causationId` matches each preceding EventBridge ID.

When two canonical events describe the same operation, compare `fileId`, `correlationId` and `idempotencyKey`. Matching values identify at-least-once delivery of the same logical operation; different source version IDs identify distinct uploads.
