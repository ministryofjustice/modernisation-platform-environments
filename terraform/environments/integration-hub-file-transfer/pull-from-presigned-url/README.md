# Authenticated file pickup from Slack

The `pull-from-presigned-url` component notifies customers in Slack when an immutable
clean file has been retained for collection. The Slack button opens an organisational
SSO page. After sign-in, an explicit user/group-to-file check permits a download URL
valid for **up to five minutes**. Files remain available for **seven days** from the
start of the successful retention attempt. Customers can reopen the same Slack link
and obtain a fresh URL without operator intervention, while access and retention permit.

## Access and expiry

Slack contains an authenticated pickup link, never an S3 presigned URL. Forwarding
the Slack link does not grant access. The resulting S3 URL is a bearer credential:
anyone receiving that URL can reuse it during its brief validity. This is the selected
tradeoff; neither single-use download nor strict non-transferability is claimed.
An S3 request started before expiry can continue afterwards. A disconnected download
or new range request after expiry needs a fresh URL; the customer can obtain one
through the same authenticated link.

API Gateway validates the JWT access token's signature, issuer, audience, expiry and
required API scope. The download Lambda uses only the gateway's verified claims,
then checks an exact OIDC subject or group ID against the current recipient mapping.
Agency membership, email domain, Slack membership and knowledge of a link grant no
access. LAA, HMPPS and HMCTS users need federation/assignment in the chosen organisational
identity provider and an explicit recipient mapping.

The broker retrieves a consistent DynamoDB receipt and signs only its recorded bucket,
key and immutable version. The receipt must still match the configured source prefix.
It caps validity at the earlier of 300 seconds and the remaining collection window.
Application checks enforce the seven-day cutoff independently of asynchronous S3
lifecycle deletion and DynamoDB TTL. Bucket policy rejects signatures over five
minutes old. Files use private, encrypted, versioned pickup storage; clean-bucket
retention remains unchanged. S3 current/noncurrent versions expire after seven days,
with asynchronous lifecycle processing. Failed copy attempts may leave unannounced
versions until lifecycle cleanup.

Removing a recipient or changing its prefix prevents new URLs after configuration
deployment. A URL already issued can remain usable for its remaining lifetime.
Group membership changes can take until access-token expiry to take effect; use
short access-token lifetimes (recommend five minutes) and verify provider revocation
behaviour. The broker does not perform token introspection on every request.

## Architecture and ownership

```text
Clean file -> existing dispatcher -> EventBridge -> SNS -> SQS -> retention/notifier Lambda
                                                           |-> exact-version copy to pickup S3
                                                           |-> immutable DynamoDB receipt
                                                           `-> Slack authenticated pickup link

Browser -> OIDC code + S256 PKCE -> API Gateway JWT authorizer -> download Lambda
                                                               |-> recipient/receipt check
                                                               `-> 300-second S3 GET URL
```

The notifier validates queue/topic, event source/account/region, clean bucket/prefix,
object version and the immutable dispatch-secret version. It copies before notifying,
uses multipart copy for large objects, and requires the configured Slack recipient in
the dispatch secret. The notification worker has source-version read and destination
write access. The separate broker has receipt read and retained-version read access;
it cannot modify files, receipts, dispatch configuration or Slack secrets.

The child state owns encrypted transport and three DLQs, both Lambdas, receipt and
idempotency storage, the private pickup bucket, HTTP API, webhook secret metadata and
CloudWatch alarms. It looks up parent metadata by name and does not read parent state.
It does not replace existing delivery actions or change clean bucket notifications.

## Configuration and onboarding

**No recipients or SSO application are configured by default.** The download route
is absent without SSO, the public page reports unavailable, and event consumption is
disabled for an empty recipient map. A Terraform precondition rejects activating
recipients without SSO. Do not use placeholder IDs as real access grants.

1. Register the component in the platform environment definition; wait for generated
   state/workflow configuration and reconcile scaffolding before planning it.
2. The SSO application owner must register a public browser OIDC client using
   authorization code with S256 PKCE (no client secret), JWT access tokens accepted
   by API Gateway, and a dedicated API scope. The token endpoint must allow browser
   CORS from the component's API origin. Configure the exact `sso_callback_url`
   output as the allowed redirect; do not use wildcard redirects. Require the
   organisation's MFA/conditional-access policy. Review issuer, token audience,
   scope, claim shape and token lifetime with that owner.
3. Set `pickup_sso_by_environment` using the approved environment-specific Terraform input process:

   ```hcl
   pickup_sso_by_environment = {
     development = {
     issuer                 = "https://<approved-issuer>"
     audience               = "<API-access-token-audience>"
     client_id              = "<public-client-ID>"
     authorization_endpoint = "https://<approved-authorization-endpoint>"
     token_endpoint         = "https://<approved-token-endpoint>"
     download_scope         = "<dedicated-download-scope>"
     groups_claim           = "groups"
     }
   }
   ```

   The group claim must be a string array (or its JSON representation in API Gateway
   claims). Missing, malformed and group-overage claims deny group access; there is
   no directory lookup fallback. USER IDs are OIDC `sub` values, not email addresses
   or assumed Identity Center IDs. Confirm the actual provider's claim representation
   in development before onboarding. Do not use an ID token for the download API.
4. Add reviewed mappings to the environment in
   `../modules/authenticated-pickup-configuration/main.tf`, for example:

   ```hcl
   example-team = {
     prefix = "approved-customer/approved-prefix/"
     principals = {
       recipient_team = { type = "GROUP", id = "<approved-access-token-group-ID>" }
     }
   }
   ```

   Use a safe hyphenated recipient ID (for example `example-team`), a literal non-root
   prefix ending in `/`, and immutable provider-issued user/group IDs. The matching
   prefix must exist in `../modules/file-dispatch-configuration`. Keep its delivery
   action and set notification configuration to:

   ```hcl
   notifications = {
     email = null
     slack = { type = "authenticated-pickup", recipient = "example-team" }
     teams = null
   }
   ```

5. Existing dispatch secrets ignore Terraform secret-value updates. Update the exact
   secret through the approved Secrets Manager process, preserving other fields.
   Events bind the immutable secret version that was current at dispatch time.
   Populate the component-created `integration-hub-file-transfer/slack-pickup/<recipient>`
   secret with `{"url":"https://hooks.slack.com/services/..."}` outside Terraform.
   Use a webhook installed for the approved channel, suitable for file path metadata.
   Rotate by replacing the webhook in Slack, updating the secret, then revoking the
   previous webhook. No webhook credential is committed, output or logged.
6. Review plans against current main before applying. Test with a dedicated development
   recipient and non-sensitive files. Connect an approved operational alarm destination
   before production; alarms have no actions, matching existing delivery components.

## Verification before activation

Local tests exercise authorization, version binding, exact prefixes, malformed claims,
expiry, notification ordering, multipart copy and retry behaviour. CI additionally
validates Terraform without AWS credentials. These are not a live deployment test.

With the actual provider and a development recipient, verify:

- Intended user/group can sign in, receive the required API scope and download the
  correct version; another user receiving the Slack link is denied.
- Missing/invalid/expired tokens, wrong issuer/audience/scope and ID tokens fail at
  API Gateway. Group claims appear in the expected form, including overage behaviour.
- Small and greater-than-5-GiB clean files produce a retained copy before notification;
  quarantine/investigation files never notify. Compare downloaded bytes/checksums.
- Expired URLs fail; reopening the Slack link works without support intervention.
  Verify interrupted large-download behaviour and fresh-link retries.
- Collection deadline and removal of recipient authorization deny new URLs. Verify
  revocation timing and confirm token/URL/file-name data is absent from service logs.
- Slack failures retry, DLQs alarm, and no production notification is sent during tests.

The public landing page uses a restrictive CSP, no external scripts, PKCE and one-time
state verification. Access tokens remain in memory; only pending PKCE state is kept
in session storage. Responses disable caching/referrers. No SSO client secret is used.

## Retry and operational limits

Notification claims last 16 minutes; Lambda timeout is 15 minutes and queue visibility
90 minutes. Duplicate completed sends are suppressed for 14 days. A receipt saved
before a Slack failure is reused with the same version and collection deadline.
If Slack accepts a message but acknowledgement is lost, a duplicate message is possible.
Copy failures never announce a file. Multipart failures are aborted where possible;
incomplete uploads have a one-day lifecycle cleanup rule. Copies exceeding Lambda's
runtime need operational investigation; this implementation does not promise unlimited
file sizes or resumable copy jobs.

Events older than 12 hours are skipped to avoid retrying copies after the one-day clean
retention. Monitor processing lag and DLQs well before that limit. Reopening a Slack
link is a customer retry, not a request to extend seven-day retention. After collection
expiry, the sender must initiate a new approved transfer.

## Checks

```sh
terraform fmt -check -recursive terraform/environments/integration-hub-file-transfer/pull-from-presigned-url
PYTHONPATH=terraform/environments/integration-hub-file-transfer/pull-from-presigned-url/lambda/notifier \
  python3 -m unittest discover -s terraform/environments/integration-hub-file-transfer/pull-from-presigned-url/lambda/notifier/tests -v
PYTHONPATH=terraform/environments/integration-hub-file-transfer/pull-from-presigned-url/lambda/download \
  python3 -m unittest discover -s terraform/environments/integration-hub-file-transfer/pull-from-presigned-url/lambda/download/tests -v
node --test terraform/environments/integration-hub-file-transfer/pull-from-presigned-url/lambda/download/tests/browser.test.cjs
```

The platform-owned `.github/workflows/integration-hub-file-transfer.yml` is unchanged.
Tests and credential-free validation run in the separate
`.github/workflows/mft-pull-from-presigned-url-checks.yml`. Follow component conventions:
local formatting/unit tests; Terraform init/validation/plans through repository CI.

References: [API Gateway JWT authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-jwt-authorizer.html),
[S3 presigned URL behaviour](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-presigned-url.html),
[presigned-request guardrails](https://docs.aws.amazon.com/prescriptive-guidance/latest/presigned-url-best-practices/additional-guardrails.html).
