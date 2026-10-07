# Authenticated file pickup from Slack

`pull-from-presigned-url` sends a Slack notification after retaining the exact clean
object version in private pickup storage. The button opens the **existing AWS Transfer
web app**, which already uses IAM Identity Center. The user signs in there and browses
to the pickup location shown in the message. No Entra application, custom OIDC client,
API callback or separate sign-in page is required.

The notification uses the documented portal entry point, not an invented file deep
link. It contains the destination bucket/key to locate the file after sign-in.

## Identity and access

The root state owns the Transfer web app, its IAM Identity Center application
assignments and the regional S3 Access Grants instance. Its assigned group catalogue
is shared through `../modules/transfer-web-app-identity-configuration`. The existing
`integration-hub` group ID is unchanged. Adding an entry to this catalogue changes
root application assignments and must be reviewed/applied there first.

This component registers only its own bucket as an Access Grants location with a
read-only IAM role. Explicit recipient configuration binds a clean source prefix to
one or more already-assigned groups. Files are stored under
`<recipient-id>/<execution-hash>/<filename>`. Each DIRECTORY_GROUP grant permits READ
only under its recipient directory, with no upload/delete permissions. Access Grants
vends scoped temporary credentials on behalf of the authenticated user. The location
role permits pickup reads through the existing Access Grants instance and KMS decrypt
through S3 only. Incoming upload grants, clean permissions and other customer buckets
are unchanged. There is no fallback grant for all MoJ users or all app users.

**Recipient maps remain empty.** The existing application assignment is not evidence
that a group should see every clean-file prefix. An approved prefix-to-group mapping
and a Slack webhook are still needed. No new application assignment is created by
this child state. Empty maps create no reader role, location or grants, and disable
queue consumption.

## URL lifetime and collection window

Slack receives a portal URL, never an S3 bearer URL. A forwarded portal link grants
no file access without the appropriate Identity Center assignment and S3 grant.
The managed Transfer web app controls its own download mechanism. The pickup bucket
retains a `s3:signatureAge` deny for signatures older than **300,000 milliseconds**,
so signed S3 requests older than five minutes are rejected even if the client signs
for longer. This is a bucket guardrail, not configuration of the managed UI's displayed
expiry. Verify actual managed-app download and retry behaviour before activation.

An S3 URL remains reusable/shareable during its effective lifetime. A request begun
before expiry can continue afterwards. The five-minute limit does **not** shorten
Identity Center sessions or Access Grants credentials; removing a grant/group may
not revoke already-issued credentials immediately. Test actual revocation behaviour.

Pickup storage has **seven-day current/noncurrent lifecycle expiry**, while clean
retention is unchanged. S3 lifecycle deletion is asynchronous, and versioned bytes
can remain beyond seven days. This managed portal does not consult the notification
receipt and therefore **does not enforce the old custom broker's exact seven-day
collection cutoff**. The receipt deadline only stops old notification retries. Do
not claim an exact deletion/access deadline or production acceptance of that change.
If an exact seven-day cutoff is mandatory, this route needs an additional enforcement
design before activation. Existing unscoped copies are not included in the new grants.

## Flow and ownership

```text
Clean dispatcher -> EventBridge -> encrypted SNS -> encrypted SQS -> notifier Lambda
                                                                   |-> exact-version pickup copy
                                                                   |-> receipt/deduplication
                                                                   `-> Slack portal link + location

Existing Transfer web app -> IAM Identity Center -> S3 Access Grants -> pickup S3
```

The notifier validates event transport, source/account/region, clean prefix, immutable
object version and immutable dispatch-secret version. It copies before notifying,
using multipart copy for large objects. Copying and storage remain in this component;
reuse of `push-to-s3-with-hosted-pickup` is a separate architectural decision.

Notification claims last 16 minutes, Lambda timeout is 15 minutes and queue visibility
90 minutes. Completed sends are deduplicated for 14 days. Saved receipts are reused
without recopying or extending their deadline. An ambiguous Slack response may cause
a duplicate notification. Copy failures never announce a file. Multipart failures
are aborted where possible; incomplete uploads have a one-day cleanup rule. Files
that cannot copy within Lambda's runtime need investigation. Events older than 12
hours are skipped because clean retention is short; monitor processing age and DLQs.

## Development onboarding

1. Reconcile this branch with current main and review the Terraform plan. Root already
   owns the identity resources; the shared-catalogue extraction should not change its
   group ID or application assignment. Deploy root first if a new assignment is needed.
2. Confirm the test user belongs to an existing assigned Identity Center group and
   can open `https://web.development.file-transfer.service.justice.gov.uk`.
3. Agree the exact clean prefix and Slack destination. Add a mapping to the development
   map in `../modules/authenticated-pickup-configuration/main.tf`, for example:

   ```hcl
   test-pickup = {
     prefix = "<approved-clean-prefix>/"
     groups = ["integration-hub"]
   }
   ```

   This is an example, not an enabled grant. The prefix must exist in the shared
   dispatch configuration. Preserve its existing delivery action. Additional group
   names must first exist in the root-owned shared assignment catalogue.
4. Apply the child component, reviewing each READ grant and its exact recipient path.
   It creates `integration-hub-file-transfer/slack-pickup/test-pickup` secret metadata.
   Store `{"url":"https://hooks.slack.com/services/..."}` there outside Terraform.
   Use a webhook approved for receiving the file bucket/path metadata. Never commit
   or log webhook credentials. Rotate in Slack and replace the secret value.
5. Update the matching dispatch secret through the approved Secrets Manager process,
   preserving the action and other notification settings:

   ```json
   "slack": {"type":"authenticated-pickup","recipient":"test-pickup"}
   ```

   This is a field inside `notifications`. Existing dispatch secret values ignore
   Terraform updates, so edit the actual secret before submitting a new transfer.
6. Upload a new non-sensitive file, confirm its retained copy and Slack message, open
   the portal, and locate the exact bucket/path from the message.

## Migration from the deployed custom page

The initial development foundation included an HTTP API, OIDC/PKCE browser page and
URL-issuing Lambda. This change removes those component-owned resources and the
`sso_callback_url` output. The old execute-api URL is retired; `portal_url` now points
to the existing Transfer app. The pickup bucket, encryption key, notifier, queues,
DynamoDB table and webhook secret names keep their Terraform addresses.

Review planned removal of the API, download Lambda/role/log group and its alarm.
Do not approve deletion of the pickup bucket or any root Transfer/Identity Center
resources. Do not apply an old saved plan. No live apply or grant is performed by
local tests or by this PR update.

## Acceptance tests before enabling customer access

- An assigned group member can see/download only the approved recipient directory;
  an app user outside that group cannot list or retrieve it, even with a forwarded link.
- A second recipient directory is inaccessible, and upload/delete operations fail.
- Small and greater-than-5-GiB files copy before notification and download intact.
- Capture a test download URL privately; a new request after five minutes fails.
  Reopening/retrying through the portal works. Verify the managed UI does not reuse
  an old cached URL or credentials signed too early for the bucket guardrail.
- Removing a grant/group has the documented credential/session revocation delay.
- CORS permits only the configured Transfer origin; notifications contain no tokens
  or signed URLs; quarantine/investigation events never notify.
- Agree lifecycle-based collection expiry explicitly if an exact seven-day cutoff
  was previously required. Inspect old unscoped objects rather than granting them.

Connect an approved operational alarm destination before production. The component's
DLQ/error alarms currently have no actions. This is not evidence of a completed live
Identity Center test; membership and the first approved pickup prefix remain onboarding
inputs, and the existing managed portal must be exercised with a real assigned user.

## Local and CI checks

```sh
terraform fmt -check -recursive terraform/environments/integration-hub-file-transfer/pull-from-presigned-url
PYTHONPATH=terraform/environments/integration-hub-file-transfer/pull-from-presigned-url/lambda/notifier \
  python3 -m unittest discover -s terraform/environments/integration-hub-file-transfer/pull-from-presigned-url/lambda/notifier/tests -v
```

The platform-owned MFT workflow is unchanged. The standalone pickup-checks workflow
runs notifier/retention tests and credential-free Terraform validation. Follow existing
component conventions: local formatting/unit tests; init/validation/plans in repository
CI. Terraform plans must confirm the root identity assignments remain unchanged.

References: [Transfer web app access grants](https://docs.aws.amazon.com/transfer/latest/userguide/webapp-access-grant.html),
[Transfer web app IAM roles](https://docs.aws.amazon.com/transfer/latest/userguide/webapp-roles.html),
[S3 presigned URL guardrails](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-presigned-url.html).
