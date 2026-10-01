# Secure clean-file download notifications

Status: updated following David's feedback on 1 October 2026. Organisation SSO is
selected; the proposed component is now `pull-from-presigned-url`. The draft is an
inactive notification foundation. The goal is to prevent inappropriate sharing/use
of long-lived presigned URLs. An SSO broker issuing a short-lived URL may be suitable
if its residual sharing risk and lifetime are explicitly accepted; strict
recipient-only retrieval still requires authenticated streaming. The component
README records these options and the clean-bucket retention constraint. The original
assessment below explains the stronger recipient-only interpretation and must not
be read as a final decision to require streaming.

## Decision required

The story requires access restricted to the intended recipient, with the explicit
condition: "If this isn't possible, we don't do this at this juncture".

Do not restore the prototype's raw S3 presigned URL in Slack. S3 authenticates a
presigned request as its signer, not the person clicking the link. Anyone holding
that URL can reuse it until it expires. A short expiry or an IP restriction reduces
exposure but does not identify a recipient. A Slack direct message alone does not
change this property.

A one-time exchange token is not a one-time S3 download. A conditional DynamoDB
update can ensure that a token is exchanged once, but the resulting presigned URL
remains reusable. Deleting an object after an access event is not an atomic access
control and would also interfere with retention, retries and other delivery actions.
Do not describe either approach as recipient-only or exactly-once delivery.

## Evidence from the implementation

The historical `modules/send-presigned-url` prototype at commit
`e948e4a060609228a39743c132dbbade5b3640ae` subscribed to clean-bucket S3 events via
SNS and SQS. Its Lambda called `generate_presigned_url("get_object")`, included
that URL in an SNS notification, and delivered it to Slack through AWS Chatbot.
Its DynamoDB idempotency mechanism deduplicated notifications, not downloads.

The current dispatcher already emits `FileActionExecutionRequested.v1` only after
clean routing. It carries the exact object version, execution ID, notification
names and an immutable Secrets Manager configuration reference. Use this contract
instead of adding another owner of the clean bucket's S3 notification configuration.

The existing `push-to-s3-with-hosted-pickup` component copies the exact clean version
to a dedicated customer bucket with a configured retention period. Customer reader
roles currently deny all assumption until the customer principal is agreed. The
existing Transfer web app uses Identity Center, but its current Access Grants cover
incoming upload prefixes, not hosted pickup or clean-file download access.

## Options to agree

| Option | Access property | Story fit |
| --- | --- | --- |
| Raw S3 presigned URL in Slack | Anyone holding the URL can download repeatedly until expiry | Rejected by the stated access requirement |
| Single-exchange token that redirects to S3 | Token exchanged once; resulting URL remains a reusable bearer credential | Does not satisfy recipient-only or single-use download requirements |
| Slack notification linking to an authenticated download service | Service authorises the recipient and exact object version on every download/range request; no reusable S3 URL is exposed | Recommended direction for a strict recipient-only requirement, subject to identity and large-file design |
| Notification plus hosted pickup through an agreed customer AWS role | AWS authorises retrieval against the customer's role and prefix | Fits machine customers, but changes the presigned-link user experience |

For a browser service, agree an organisation SSO identity or verified Slack identity
and a server-managed mapping from that identity to authorised files. A Slack channel
ID, an uploader-supplied client ID or possession of the notification must never be
the authorisation decision. Also agree whether the recipient is one person or an
authorised customer group.

The existing Transfer web app is worth evaluating for authenticated pickup, but
must not be assumed to satisfy strict non-transferability without verifying its
actual download mechanism. A login page followed by a reusable S3 redirect still
has the bearer-link limitation.

## Proposed component boundary after the decision

1. Register a separate component in the platform environment definition and use its
   generated backend/provider files. Keep its Terraform state separate from root,
   following the two existing delivery components.
2. Consume the shared dispatch-configuration module. Bind authorised secret ARNs,
   customer prefixes and recipient identities through managed configuration. Empty
   configuration must create no customer access grants.
3. Route the relevant clean-file dispatch event through EventBridge to encrypted
   SNS, encrypted SQS and Lambda. If availability depends on a hosted copy, notify
   only after the successful copy is confirmed; a request event is not proof of
   completed delivery.
4. Validate event source, account, bucket, prefix, exact object version and exact
   secret version. Use allowlisted notification destinations from Secrets Manager.
   Keep credentials, tokens and download URLs out of logs and events.
5. Send an opaque link to the agreed authenticated service. The notifier should not
   have S3 download/signing permissions when it only needs to send notifications.
6. Preserve the existing patterns for partial batch failures, encrypted transport
   DLQs, bounded retries, metrics and alarms. Deduplicate notifications separately
   from download sessions and existing action-completion markers. External Slack
   delivery and a DynamoDB write cannot be assumed to be one atomic operation.

A strict authenticated download service must handle the existing large-file use
case (already tested above 5 GiB), streaming, Range requests, interruption and
resume. Select a delivery implementation only after validating its size, timeout
and authentication behaviour; do not assume a buffered Lambda response will work.
If single-use is selected, define it as a controlled download session with explicit
retry/resume rules, not a guarantee that the recipient received the bytes exactly
once. An authorised recipient can still copy a file after downloading it.

## Self-service retry and notification reissue

Allow the authenticated recipient to request a new notification or download session
for a file they are still entitled to access. Re-check object availability, exact
version, retention and current authorisation. Rate-limit and audit the operation.
Use a new notification/session identifier without replaying the original dispatch
action or copying the file again. Expired/deleted files must fail clearly; renewal
must not silently extend retention. Unauthenticated link previews must neither
consume a session nor trigger a download.

## Acceptance and test gates

- Recipient identity, recipient-to-file mapping and allowed sharing semantics agreed.
- Component registration, generated files and SNS > SQS > Lambda plan reviewed.
- Forwarded link rejected for another authenticated user; unauthenticated access denied.
- Tampered file/customer/version references and unconfigured destinations rejected.
- Quarantine and investigation events never notify or expose files.
- Duplicate events, partial failures, throttling and DLQ recovery tested.
- Large-file downloads and interruption/resume tested with the chosen access model.
- Session replay, concurrent redemption and self-service reissue tested if applicable.
- Retention expiry and revoked recipient access enforced during reissue.
- No raw download credentials in Slack, logs, EventBridge or DLQs.

## References

- [Historical prototype](https://github.com/ministryofjustice/modernisation-platform-environments/tree/e948e4a060609228a39743c132dbbade5b3640ae/terraform/environments/integration-hub/managed-file-transfer/modules/send-presigned-url)
- [AWS: presigned URL semantics](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-presigned-url.html)
- [AWS: single-exchange tokens](https://aws.amazon.com/blogs/storage/implement-single-exchange-tokens-for-short-lived-amazon-s3-presigned-urls-with-terraform/)
- [Dispatch contract](file-action-dispatch.md)
- [Hosted pickup component](../push-to-s3-with-hosted-pickup/README.md)
