# Authenticated pickup notifications in Slack

This component sends an organisation-SSO pickup link when the existing dispatcher
reports a clean file. The link opens the existing MFT Transfer Family web app; it
is not a presigned S3 URL or a direct download capability. Users select the file at
the location shown in the notification. No undocumented file deep-link is assumed.

## Confirmed blocker: managed portal download path

On 30 September 2026, inspection of the deployed development portal's public
JavaScript (`1.0.2614.0/main.js`) showed that its single-file download handler calls
the storage GetUrl operation and opens the returned expiring URL in a new browser
window. It therefore exposes a bearer S3 URL after sign-in. This does not satisfy
the agreed recipient-only requirement.

**This PR is an inactive notification foundation, not a completed download service.**
The shared configuration rejects all nonempty recipient maps at Terraform plan time.
No root Access Grants, IAM pickup role or clean-bucket policy/CORS changes are included.
Do not remove the activation precondition until an approved organisation-SSO streaming
endpoint is integrated and tested. The endpoint must authorise the user and file on
each download/range request without returning a presigned redirect. The identity
provider/application registration and recipient mappings are outstanding inputs.

## Status and activation gates

Implementation is prepared with **no configured recipients**. It does not currently
send Slack messages or grant new file access. The separate platform registration
must be merged and generated component files reconciled before a plan/apply.

Before enabling a recipient, agree their exact Identity Center user/group IDs,
clean prefix, and Slack destination. Agency names or Slack membership alone never
grant access. LAA, HMPPS and HMCTS users must be provisioned/federated into the
existing Identity Center directory and assigned to the web app.

A live browser test of the replacement endpoint must verify authorised download,
unauthorised forwarded-link denial, large-file streaming/resume and revocation.
No claim of protection against an authorised recipient redistributing downloaded
bytes is made.

## Architecture and state ownership

`FileRouted.v1 (clean) -> existing dispatcher -> FileActionExecutionRequested.v1 -> EventBridge -> SNS -> SQS -> Lambda -> Slack`

The EventBridge rule selects only Slack requests for configured dispatch secret
ARNs. The Lambda validates the queue, SNS topic, event source/account/region, clean
bucket, authorised prefix, object version and immutable dispatch secret version.
The secret must explicitly select the configured recipient. Credentials remain in
a separate Secrets Manager secret and are never placed in messages or logs.

The existing root remains unchanged. The shared configuration reserves the recipient
mapping contract for the future authenticated service; it currently rejects activation.
No code in this component authorises browser downloads.

This child state owns encrypted SNS/SQS, three transport DLQs, Lambda, notification
idempotency, webhook secret metadata and CloudWatch alarms. It looks up parent AWS
metadata by name; it does not read parent Terraform state. Its Lambda has no S3
permissions and cannot fetch or sign a download. No AWS console role is required
for recipients.

This consumes clean-file dispatch directly, so it does not announce successful
hosted copies or customer-owned destination delivery. It can coexist with the two
existing delivery actions. Access is to the current file shown by the portal,
not a guaranteed deep link to the event's exact historical version. Do not use
mutable file names where recipients require immutable version-specific delivery.

## Configure a recipient

Add a reviewed entry to the appropriate environment in
`../modules/authenticated-pickup-configuration/main.tf`. Example only:

```hcl
products = {
  prefix = "products-poc/uploads/"
  principals = {
    recipient_team = {
      type = "GROUP" # or USER
      id   = "<approved Identity Center ID>"
    }
  }
}
```

The prefix must also exist in `../modules/file-dispatch-configuration`. Preserve
its existing action. Set its initial Slack configuration to:

```hcl
notifications = {
  email = null
  slack = { type = "authenticated-pickup", recipient = "products" }
  teams = null
}
```

Existing dispatch secrets ignore Terraform secret-value changes: update the exact
existing secret through the approved Secrets Manager process, preserving its other
fields. Events reference the immutable secret version at dispatch time. The new
component creates `integration-hub-file-transfer/slack-pickup/products` metadata;
populate its value with `{"url":"https://hooks.slack.com/services/..."}` outside
Terraform. Use a webhook installed for the approved Slack channel; that channel
may receive file names/paths and must be suitable for that metadata. Webhook values
are neither configuration-file fields nor Terraform outputs. No placeholder
credentials are installed. Rotate a webhook by issuing a replacement in Slack,
updating this secret, and revoking the old webhook in Slack. The worker fetches the
current webhook on each attempt, so rotation needs no redeployment. Secrets Manager
cannot automatically rotate an externally issued Slack incoming webhook.

## Deployment and verification

1. Register `slack-notifications` in the platform environment definition. Wait for
   state provisioning/generated files and reconcile the scaffold in this directory.
2. Integrate the approved SSO identity provider with a streaming download endpoint,
   implement recipient-to-file authorisation, and replace the managed portal URL.
3. Verify authorised/unauthorised browser paths, forwarding, expiry, revocation and
   large-file interruption/resume. Only then remove the activation precondition.
4. Populate the dispatch and webhook secrets, then review/apply this component.
   Root and child configuration changes can be selected by the same workflow, so
   approve root first and rerun the child plan if its metadata lookups run too early.
5. Route a non-sensitive clean file and confirm the Slack message, sign-in, prefix
   isolation and download. Verify quarantine/investigation produce no messages.
6. Monitor DLQs, processing age and errors. Connect an approved operational alarm
   destination before production; alarms currently have no actions, matching the
   existing delivery components.

No live Slack message or grant is part of the local test suite. Recipient removal must revoke download-service authorisation as well as notification
routing. Test and document session revocation behaviour before enabling recipients.

## Retry, retention and failure behaviour

The intended notification URL is a stable SSO download-service URL. An authorised recipient can
reopen it and retry without asking an operator to mint another link. The download service must check access and
file availability; that service is not part of this foundation. Link reuse does not extend
retention. The current clean bucket expires current and noncurrent versions after
one day, with asynchronous lifecycle removal. The worker skips dispatch events
older than 12 hours rather than sending old DLQ notifications; this is an age guard,
not a guarantee that a file still exists. A file may have been deleted meanwhile.
For longer pickup retention, design the grant against the hosted pickup bucket and
trigger notifications from verified successful copy completion instead.

A DynamoDB conditional claim deduplicates completed sends for 14 days and prevents
concurrent sends while a two-minute lease is active. Lambda timeout is one minute;
SQS visibility is six minutes, with five attempts. Slack errors, rate limits and
network failures retry through partial batch responses. If Slack accepts a message
but the response or completion write is lost, a duplicate is possible. Exactly-once
Slack delivery is not claimed. Dead-letter messages never contain webhook values.

## Local checks

```sh
terraform fmt -check -recursive terraform/environments/integration-hub-file-transfer/slack-notifications
PYTHONPATH=terraform/environments/integration-hub-file-transfer/slack-notifications/lambda/notifier \
  python3 -m unittest discover \
  -s terraform/environments/integration-hub-file-transfer/slack-notifications/lambda/notifier/tests -v
```

Follow the existing component convention: local checks are formatting and unit
tests. Run Terraform validation/plans through the repository workflow after the
component is registered. Do not use local init/plan/apply for this component.

References: [Identity Center](https://docs.aws.amazon.com/transfer/latest/userguide/webapp-identity-center.html),
[S3 Access Grants](https://docs.aws.amazon.com/transfer/latest/userguide/webapp-access-grant.html),
[presigned-request guardrails](https://docs.aws.amazon.com/prescriptive-guidance/latest/presigned-url-best-practices/additional-guardrails.html).
