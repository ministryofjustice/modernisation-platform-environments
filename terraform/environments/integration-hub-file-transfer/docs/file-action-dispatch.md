# File action execution requested adapter

After a file is routed to the clean bucket, the file action execution requested adapter finds the most specific dispatch configuration for the destination object key and publishes one `FileActionExecutionRequested.v1` event for that configuration.

## Configuration

Terraform creates dispatch secrets from `file_dispatch_prefixes` in `locals-dispatch.tf`. The identity and configured prefix form an opaque full-object-key prefix. For example, identity `example-transfer-identity` and prefix `/app-1/` match keys beneath `example-transfer-identity/app-1/`.

Each secret contains an optional action and the supported notification destinations:

```json
{
  "action": {
    "name": "place-on-sqs",
    "queueArn": "arn:aws:sqs:eu-west-2:123456789012:destination"
  },
  "notifications": {
    "email": "consumer@example.invalid",
    "slack": null,
    "teams": "https://example.invalid/teams-webhook"
  }
}
```

`action` is either `null` or an object with a non-empty `name`. Other properties are private configuration interpreted by the selected executor. Each notification is either `null` or its private destination value. Null means that action or notification is not configured.

The dispatcher publishes at most one event for a matched secret. The event includes only `action.name`, the names of configured notification types, and an immutable reference to the exact secret version. Action configuration and notification destinations remain in Secrets Manager. A notification-only secret is valid; a secret with no action and no notification destinations is a successful no-op.

## Matching

The dispatcher tries the complete destination object key first, followed by parent prefixes at slash boundaries from longest to shortest. For `identity/group/reports/test.csv`, it tries:

1. `identity/group/reports/test.csv`
2. `identity/group/reports/`
3. `identity/group/`
4. `identity/`

The first existing secret wins. A missing candidate is expected and lookup continues. If no candidate exists, processing succeeds without publishing an event. An unreadable or malformed matched secret fails the invocation so Lambda retries and dead-letter handling apply.

Only clean `FileRouted.v1` events for the configured clean bucket reach the dispatcher. Quarantine and investigation routes do not produce action requests.

## Delivery and idempotency

EventBridge rules can route requested events using `detail.data.action.name` or configured names in `detail.data.notifications`. The exact routing rules and action-specific configuration are intentionally deferred until executors are introduced.

Every downstream consumer must use `actionExecutionId` or `detail.metadata.idempotencyKey` to make processing idempotent. EventBridge publication is at least once. The dispatcher derives a deterministic execution identity from the source idempotency key and exact secret identity, so a retry may create a new EventBridge envelope while retaining the same logical request identity.

## Security boundary

The dispatcher trusts the canonical `FileRouted.v1` input selected by its EventBridge rule. It validates the matched secret's JSON structure and action name. Action-specific interpretation belongs to downstream executors, which retrieve the exact secret using `configurationReference.secretArn` and `configurationReference.secretVersionId`.

Secret values must not be written to EventBridge, CloudWatch Logs or dead-letter queues. Dispatcher logs include only non-sensitive object identifiers, secret-version identifiers, the action name and configured notification type names.