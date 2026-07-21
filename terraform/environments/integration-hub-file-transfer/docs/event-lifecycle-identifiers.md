# Tracking a file across its lifecycle

When a file arrives in the `incoming` S3 bucket, this service starts emitting events. Those events travel through scanning, routing, and delivery, each produced by a different component. To make sense of them — whether you are debugging a stuck file or building a new consumer — you need to understand how events are tied together.

This guide explains the identifiers used, how they are set, and how to use them in practice.

## The problem these identifiers solve

A single file moves between S3 buckets as it progresses through the service. Its S3 location changes at each stage, and its object version ID changes with it. If events only recorded the current S3 location, there would be no way to link `FileReceived.v1` to `FileRouted.v1` without knowing the full chain of object copies in advance.

Instead, events carry a stable logical identity that never changes, no matter how many times the underlying object moves.

## The identifiers and what they mean

**`detail.data.fileId`** is the stable identifier for the logical file. It is set once when the file first arrives and copied into every event thereafter. If you want to find all events for a particular file, filter by this value.

**`detail.metadata.correlationId`** serves the same purpose as `fileId` at present — it groups every event in a file's lifecycle. Both are set to the same value at ingress. They are kept separate because `fileId` is owned by the data domain and `correlationId` is a tracing concept; a future workflow might produce events spanning more than one file, in which case `correlationId` would be shared while `fileId` would differ.

**`detail.metadata.causationId`** records which event caused this one. It is the EventBridge `id` of the preceding event in the chain. The very first event, `FileReceived.v1`, has no `causationId` because nothing in the canonical chain preceded it. Every later event must carry one.

**`detail.metadata.idempotencyKey`** identifies a specific producer operation so that it can be safely retried. If a Lambda function times out after publishing an event but before Lambda considers the invocation complete, EventBridge will retry it. The idempotency key prevents that retry from publishing a duplicate.

The top-level EventBridge **`id`** is different from all of the above. It identifies the event envelope itself, generated fresh by EventBridge each time an event is published. You will see it in raw event records but it is not a stable identifier across retries — use `fileId` or `correlationId` for that.

## How identifiers are set at ingress

When a file lands in the `incoming` bucket, S3 sends a native `Object Created` notification to EventBridge. A Lambda adapter picks this up and publishes `FileReceived.v1` to the file-transfer event bus.

The adapter calculates both `fileId` and `correlationId` as a deterministic UUID derived from a SHA-256 hash of the bucket name, object key and S3 version ID. This gives the same logical file the same identity even when S3 emits more than one notification for that exact object version.

The `idempotencyKey` is set to `bucket:key:versionId`, for example:

```
integration-hub-file-transfer-production-incoming:finance/april-payroll.csv:3Lg4fHkJ9bO1
```

The version ID is essential here. Two uploads of a file with the same name get different version IDs and are treated as separate files. Without the version ID, retrying a failed ingestion of a new version could incorrectly match the idempotency record from the previous version.

## What "no duplicate events" actually means

AWS Lambda Powertools records a DynamoDB entry keyed on the native S3 EventBridge event `id`. If Lambda receives the same native event a second time — because EventBridge retried a failed invocation — Powertools returns the stored result immediately without calling `put_events` again.

There is an important boundary here: Powertools only deduplicates retries of the *same native event*. If S3 emits two separate `Object Created` notifications for the same object (which can happen in rare cases), each notification has a different native event `id`, so the adapter may publish two `FileReceived.v1` events. Both events will carry the same `fileId` and `correlationId`, because both describe the same S3 object version. This is an at-least-once guarantee, not exactly-once.

Downstream consumers should therefore be idempotent on `fileId` rather than on the EventBridge `id` of the canonical event.

The file-transfer Step Functions workflow uses a separate DynamoDB record keyed by the canonical event's `detail.metadata.idempotencyKey`, namespaced for the workflow. This is operation-level idempotency: duplicate canonical events for the same bucket, key and version resume or reuse the same durable checkpoints rather than creating another destination version. The record stores the current owner, a short in-progress lease, and copy checkpoints until it expires with the event-retention period.

The workflow copies the exact S3 version identified by `detail.data.object.versionId` from `incoming` to the same key in `processing`. Objects up to 5 GB use `CopyObject`; larger objects up to 5 TB use resumable multipart copy. The destination version is checked for size, encryption, metadata and tags before the workflow deletes only the exact source version. A failed or expired execution can therefore resume from the last successful checkpoint without deleting a newer source version.

Idempotency records expire after 30 days in non-production environments and 400 days in production, matching event retention.

## Following a file through the lifecycle

Imagine `finance/april-payroll.csv` arrives in the `incoming` bucket with version ID `v1`. Here is what the event chain looks like:

1. S3 emits a native `Object Created` event with its own EventBridge `id`, call it `native-1`.
2. The file-received adapter hashes the incoming bucket, key and version ID to produce `file-1`, then publishes `FileReceived.v1`. EventBridge assigns this event `id = eb-1`. The event carries `fileId = file-1`, `correlationId = file-1`, and no `causationId`.
3. The file-transfer workflow picks up `FileReceived.v1`, stages the exact object version to `processing/finance/april-payroll.csv`, verifies the destination version, and deletes the exact source version.
4. The workflow publishes `FileStagedForScanning.v1` as an audit record that the object is ready for GuardDuty Malware Protection for S3. It copies `fileId` and `correlationId`, sets `causationId` to the `FileReceived.v1` EventBridge ID, and identifies the exact source and staged S3 versions.

The GuardDuty adapter records every terminal scan result as `FileScanResultRecorded.v1`, copying `fileId` and `correlationId` and setting `causationId` to the preceding `FileStagedForScanning.v1` EventBridge ID. The file-transfer workflow then routes that exact processing version and publishes `FileRouted.v1`, retaining the same `fileId` and `correlationId` and setting `causationId` to the scan-result event ID.

At every stage, `fileId` and `correlationId` stay the same. The S3 location changes, the object version changes, and each EventBridge `id` is unique — but you can follow the whole chain.

The workflow records the `FileStagedForScanning.v1` EventBridge ID when marking the transfer `COMPLETED`. If EventBridge accepts the event but the completion write fails, recovery can publish the event again. Consumers must therefore treat delivery as at least once and deduplicate using `detail.metadata.idempotencyKey`, which is derived from the correlation ID and exact processing version ID.

The staging workflow writes `mft-correlation-id` as reserved metadata on the processing object. The GuardDuty adapter reads that metadata from the exact bucket, key and version ID, then retrieves the durable `STAGE` record by its `(correlationId, operation)` primary key. It publishes `FileScanResultRecorded.v1` only for a completed staging record, preserving causal ordering. Each native GuardDuty event ID is processed idempotently. Repeated native notifications can republish the same canonical `scan:{correlationId}:{processingVersionId}` idempotency key, so consumers must deduplicate on that key.

The workflow treats this scan-result event as authoritative: `NO_THREATS_FOUND` routes to `clean`, `THREATS_FOUND` routes to `quarantine`, and `UNSUPPORTED`, `ACCESS_DENIED`, or `FAILED` route to `investigation`. It copies the exact processing version, preserving and verifying all source metadata and tags before deleting that exact source version. It does not compare GuardDuty status tags during routing; that final tag-status comparison is deferred.

Routing has an independent idempotency record keyed as `file-routing-workflow#{FileScanResultRecorded.idempotencyKey}`. After the source-delete checkpoint, it publishes `FileRouted.v1` with an idempotency key of `route:{route}:{destinationBucket}:{key}:{destinationVersionId}`, then records `PUBLISHED` before completing. As with staging, a checkpoint failure after EventBridge accepts the event can lead to a duplicate publication, so consumers must deduplicate on this key.

## Rules for event producers

If you are writing a component that consumes a canonical event and produces another:

- Copy `fileId` and `correlationId` from the event you consumed. Do not regenerate them.
- Set `causationId` to the `id` field of the event you consumed — the top-level EventBridge envelope ID, not any field inside `detail`.
- Choose an `idempotencyKey` that is specific to the operation you are performing, not to the file in general. For example, a scan result key might be `scan-result:{jobId}` rather than reusing `fileId`.
- Do not derive logical file identity from the current S3 bucket or key. The file moves; the identifiers do not.

## Finding events when something goes wrong

**To find all events for a file:** query the file-transfer event bus archive or CloudWatch Logs for `detail.data.fileId`. If you know the `fileId`, this gives you the complete history.

**To reconstruct the chain:** start with `FileReceived.v1`, note its EventBridge `id`, and look for the event whose `causationId` matches it. Repeat for each subsequent event.

**When `FileReceived.v1` is missing:** check Lambda logs for the file-received adapter. Each invocation logs the native S3 event `id` alongside the canonical event `id` it published. A failed invocation will also appear here.

**When you see two `FileReceived.v1` events for the same object:** compare their `fileId` values. Matching values mean both events describe the same bucket, key and version ID; check whether S3 emitted a second notification. Different values mean the object was a different version, key, or bucket.
