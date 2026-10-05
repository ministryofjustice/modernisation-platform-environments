# Secure clean-file download notifications

The selected design is an **authenticated Slack pickup link**, with a **five-minute
on-demand S3 URL** and **seven-day retained pickup copy**. Organisation SSO identifies
the user; a server-managed recipient mapping authorises that user or an explicit
group for the file. Slack delivers notifications and does not grant file access.

A forwarded Slack link requires sign-in and passes the same authorization check.
An authorised user can nevertheless share the resulting S3 URL during its brief
validity. S3 URLs are reusable bearer credentials, not single-use or recipient-bound
credentials. This limited sharing window is the selected tradeoff. A download begun
before expiry may continue afterwards. Strict recipient checks on every byte/range
request would require a different authenticated delivery mechanism.

The component signs only an immutable retained object version after checking current
recipient configuration and the collection deadline. It never puts S3 capabilities
in Slack. Customers can reopen the authenticated link to obtain a fresh URL while
access and collection time permit; retries do not extend retention.

The clean bucket remains a short-lived processing location. Separate private pickup
storage retains copies for seven days and applies lifecycle cleanup to current and
noncurrent versions. Application checks enforce collection expiry even while S3
cleanup or DynamoDB TTL is pending. Removing a mapping stops new URL issuance after
deployment; existing URLs remain valid for at most their remaining lifetime, and
identity-provider group changes may take until token expiry to be reflected.

The implementation follows the existing clean dispatcher contract and the standard
EventBridge → SNS → SQS → Lambda pattern, with encrypted transport, DLQs and idempotency.
It copies before notifying. The download broker separately validates API Gateway's
verified JWT claims and reads a version-specific receipt. No raw URL, token or webhook
credential is logged. The platform-owned deployment workflow is unchanged.

There are no real recipients or SSO settings enabled by default. Before activation,
the application owner must supply the approved OIDC application and access-token
claims, recipient IDs, source prefix and Slack destination. Live checks must cover
authorised and denied users, forwarding, expiry, revocation and large-file retries.
See the [component README](../pull-from-presigned-url/README.md) for configuration,
operational limits and the deployment/verification sequence.
