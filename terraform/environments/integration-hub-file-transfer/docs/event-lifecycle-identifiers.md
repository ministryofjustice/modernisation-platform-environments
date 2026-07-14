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

The adapter calculates both `fileId` and `correlationId` as a SHA-256 digest of the bucket name, object key and S3 version ID. This gives the same logical file the same identity even when S3 emits more than one notification for that exact object version.

The `idempotencyKey` is set to `bucket:key:versionId`, for example:

```
integration-hub-file-transfer-production-incoming:finance/april-payroll.csv:3Lg4fHkJ9bO1
```

The version ID is essential here. Two uploads of a file with the same name get different version IDs and are treated as separate files. Without the version ID, retrying a failed ingestion of a new version could incorrectly match the idempotency record from the previous version.

## What "no duplicate events" actually means

AWS Lambda Powertools records a DynamoDB entry keyed on the native S3 EventBridge event `id`. If Lambda receives the same native event a second time — because EventBridge retried a failed invocation — Powertools returns the stored result immediately without calling `put_events` again.

There is an important boundary here: Powertools only deduplicates retries of the *same native event*. If S3 emits two separate `Object Created` notifications for the same object (which can happen in rare cases), each notification has a different native event `id`, so the adapter may publish two `FileReceived.v1` events. Both events will carry the same `fileId` and `correlationId`, because both describe the same S3 object version. This is an at-least-once guarantee, not exactly-once.

Downstream consumers should therefore be idempotent on `fileId` rather than on the EventBridge `id` of the canonical event.

Idempotency records expire after 30 days in non-production environments and 400 days in production, matching event retention.

## Following a file through the lifecycle

Imagine `finance/april-payroll.csv` arrives in the `incoming` bucket with version ID `v1`. Here is what the event chain looks like:

1. S3 emits a native `Object Created` event with its own EventBridge `id`, call it `native-1`.
2. The file-received adapter hashes the incoming bucket, key and version ID to produce `file-1`, then publishes `FileReceived.v1`. EventBridge assigns this event `id = eb-1`. The event carries `fileId = file-1`, `correlationId = file-1`, and no `causationId`.
3. The scanning component picks up `FileReceived.v1` and stages the file to `processing/finance/april-payroll.csv` (a new S3 key and version). It publishes `FileStagedForScanning.v1` with `id = eb-2`, `fileId = file-1`, `correlationId = file-1`, and `causationId = eb-1`.
4. The scanner records a clean result and publishes `FileScanResultRecorded.v1` with `id = eb-3` and `causationId = eb-2`.
5. The router delivers the file and publishes `FileRouted.v1` with `id = eb-4` and `causationId = eb-3`.

At every stage, `fileId` and `correlationId` stay the same. The S3 location changes, the object version changes, and each EventBridge `id` is unique — but you can follow the whole chain.

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
