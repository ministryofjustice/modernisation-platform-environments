# File action dispatch

After a file is routed to the clean bucket, the file action dispatcher finds the most specific dispatch configuration for the destination object key and publishes one `FileActionExecutionRequested.v1` event for each configured operation.

## Configuration

Terraform creates dispatch secrets from `file_dispatch_prefixes` in `locals-dispatch.tf`. The identity and configured prefix form an opaque full-object-key prefix. For example, identity `example-transfer-identity` and prefix `/app-1/` match keys beneath `example-transfer-identity/app-1/`.

Each secret contains an `operations` list:

```json
{
  "operations": [
    {
      "id": "send-to-consumer-a",
      "action": "send-to-consumer",
      "value": "sensitive action configuration"
    }
  ]
}
```

`id` must be stable for the logical operation. `action` becomes `actionDefinitionId` in the requested event and allows EventBridge to route the request to an action-specific target. `value` remains in Secrets Manager and is retrieved by the downstream executor using the secret ARN, exact version ID and operation ID from the event.

Validate duplicate or conflicting operations when populating a secret. The dispatcher deliberately does not compare or deduplicate entries; every structurally valid list entry produces a request.

## Matching

The dispatcher tries the complete destination object key first, followed by parent prefixes at slash boundaries from longest to shortest. For `identity/group/reports/test.csv`, it tries:

1. `identity/group/reports/test.csv`
2. `identity/group/reports/`
3. `identity/group/`
4. `identity/`

The first existing secret wins. A missing candidate is expected and lookup continues. If no candidate exists, processing succeeds without publishing an event. An unreadable or malformed matched secret fails the invocation so Lambda retries and dead-letter handling apply.

Only clean `FileRouted.v1` events for the configured clean bucket reach the dispatcher. Quarantine and investigation routes do not produce action requests.

## Delivery and idempotency

One requested event may be routed to multiple downstream queues, for example an action queue and a notification queue. Every downstream consumer must use `actionExecutionId` or `detail.metadata.idempotencyKey` to make processing idempotent. Consumers handling the same request share the file lifecycle `correlationId`, while separate configured operations have separate `actionExecutionId` values.

EventBridge publication is at least once. If part of a publication batch succeeds before another entry fails, the dispatcher retries the source event and may republish successful requests under new EventBridge envelope IDs. The deterministic action execution identity allows each downstream consumer to perform the action or notification once.

## Security boundary

The dispatcher trusts the canonical `FileRouted.v1` input selected by its EventBridge rule. It validates the matched secret's JSON structure and required string fields. Action-specific interpretation of `value` belongs to the downstream executor. Secret values must not be written to EventBridge, CloudWatch Logs or dead-letter queues.

Dispatcher logs use `correlation_id` as the primary lifecycle search field and include only non-sensitive object, secret-version and action-request identifiers. They never include an operation's `value`.