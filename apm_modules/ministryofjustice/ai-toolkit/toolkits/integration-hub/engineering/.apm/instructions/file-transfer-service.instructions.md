---
description: "Integration Hub File Transfer Service Instructions. Relevant when working on the Integration Hub File Transfer service."
source: https://github.com/ministryofjustice/ai-toolkit/blob/main/toolkits/integration-hub/engineering/.apm/instructions/file-transfer-service.instructions.md
---

# File Transfer Service Instructions

## Purpose and scope

These instructions guide agents maintaining and operating the Ministry of
Justice File Transfer Service. They explain the service's design intent and
the boundaries that changes and operational actions must preserve.

The service provides secure, reliable and auditable one-way file transfers.
External-to-internal, internal-to-external and internal-to-internal transfers
follow the same principles. Organisational direction does not change the
processing model.

## Established architecture

Preserve the chosen AWS components and their responsibility boundaries:

- Lambda adapters translate native AWS events into stable, versioned service
  events.
- EventBridge routes service events to the appropriate processing components.
- S3 provides separate incoming, processing, clean, quarantine and
  investigation areas.
- GuardDuty Malware Protection for S3 supplies malware scan outcomes.
- Lambda functions manage file movement.
- DynamoDB records support idempotency,
  concurrency control and recovery.
- Clean-file dispatch requests configured actions and notifications.
  Separate executors implement delivery patterns through their existing
  EventBridge, SNS, SQS and Lambda arrangements.

Keep provider-event adaptation, lifecycle processing, dispatch and downstream
execution distinct. Do not replace AWS services or introduce alternative
orchestration.

## Design invariants

### One-way transfer, not synchronisation

There is no bidirectional flow through the service. Where systems exchange
files in both directions, treat these as independent one-way transfers.
Do not introduce synchronisation or reconciliation semantics.

### No ETL or business-content processing

The service transports files; it does not interpret their business meaning.
Do not add extraction, transformation, enrichment or business-schema
validation of file contents.

Malware scanning, transfer-integrity checks and transport metadata handling
remain in scope. Business-content processing belongs to other services.

### Preserve exact file identity and integrity

A transfer concerns an exact uploaded object version, not merely a filename
or object key. Preserve its identity and provenance throughout processing.

Lambda functions verify the recorded destination version before deleting the
exact source version. Preserve required metadata, tags and content headers,
including service-managed provenance.

Do not generalise this deletion behaviour to downstream delivery: the
existing S3 delivery patterns copy the clean source and retain it.

S3 lifecycle rules expire objects from the terminal buckets (clean,
quarantine, and investigation).

### Fail closed at the malware boundary

Only a positive clean scan outcome will lead to clean-file dispatch.
Follow the established quarantine and investigation paths for other
recognised outcomes.

Missing, failed or inconclusive scanning must never become successful
clearance. Do not bypass scanning or manufacture scan results to unblock
delivery.

### Preserve event contracts and retry semantics

Treat canonical event schemas, lifecycle identifiers and operation identities
as contracts. Preserve fileId, correlationId, causationId and the appropriate
idempotency keys through their intended transitions.

An EventBridge event ID identifies an envelope, not necessarily distinct work.
Processing and publication can be repeated. Use the existing operation-specific
idempotency and recovery mechanisms; do not claim exactly-once delivery.

### Dispatch must remain explicit and bounded

Preserve most-specific-match dispatch semantics. A missing configuration or
an intentionally empty matching configuration may correctly produce no action.

An unreadable or invalid matched configuration is an error, not permission to
fall back to a broader prefix or another destination. Executors use the exact
configuration version referenced by the request and remain constrained by
their authorised source and destination mappings.

### Preserve isolation and confidentiality

Maintain environment, transfer-identity and source/destination-prefix
boundaries. Keep upload and pickup permissions distinct and limited to their
intended purpose.

Keep file contents, credentials and private configuration out of event
payloads, logs, tickets and agent context. Events should carry identifiers and
configuration references, not secret values.

Respect each component's retention policy. Retained events or idempotency
records do not imply that the corresponding file is still available.

### Preserve recoverability and truthful outcomes

Resume failed work through its existing checkpoints and documented recovery
path. Do not erase idempotency records, bypass leases or reconstruct events
to force progress. Follow the affected component's recovery contract rather
than applying one replay procedure everywhere.

An ambiguous side effect is not evidence that nothing happened. Preserve
the evidence and escalate uncertainty rather than risk duplicate delivery
or deletion of the wrong version.

Distinguish upload acceptance, scan completion, routing, action requests,
delivery completion and recipient processing. Report only the milestone
supported by evidence. A quiet alarm or empty DLQ is not proof of delivery.

## Working within these boundaries

Prefer existing patterns, shared helpers and configuration over bespoke
branches in shared processing. Choose implementation details freely where
they preserve the architecture, contracts and invariants above.

Read the relevant component README, event schemas and operational guidance
before changing behaviour. Use existing checks to establish that intended
behaviour, failure handling and retry semantics remain intact.

Distinguish current implementation from agreed design intent and
customer-supported availability. A directory, schema example or implemented
executor does not establish that a capability is enabled or supported in
the affected environment.

If a request conflicts with an invariant or architectural boundary, pause,
explain the conflict and seek an explicit design decision before implementing.
Likewise, surface disagreements between code and documentation rather than
silently treating either as permission to weaken a boundary.

Operational authority remains governed by the user's request and existing
tool permissions; these instructions do not expand it.

## References

- [Implementation, schemas and component READMEs](https://github.com/ministryofjustice/modernisation-platform-environments/tree/main/terraform/environments/integration-hub-file-transfer)
- [Service, user and operational guidance](https://github.com/ministryofjustice/integration-hub/tree/main/source/file-transfer-service)
- [Architecture decision records](https://github.com/ministryofjustice/integration-hub/tree/main/architecture-decision-record)
