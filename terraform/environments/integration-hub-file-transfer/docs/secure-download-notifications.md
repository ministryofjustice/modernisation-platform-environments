# Secure clean-file download notifications

Use the existing AWS Transfer web app with IAM Identity Center and S3 Access Grants.
Slack links to that portal and supplies the retained file's bucket/path. The application
already has directory-group assignments; reuse their IDs from the shared catalogue.
No new Entra application, OIDC browser client or custom callback is required.

Application assignment permits sign-in. A separate, explicit READ Access Grant permits
access to a recipient's pickup directory. These are distinct permissions: existing
app membership does not automatically grant access to all retained files. No pickup
recipient is enabled by default, and groups must be mapped to approved source prefixes.

The notifier copies the immutable clean version into a recipient/execution directory
before announcing it. Clean retention is unchanged. The child state owns pickup storage
and its location/grants; the root owns the Transfer app, assignments and Access Grants
instance. Existing incoming READWRITE grants are not widened.

The private pickup bucket rejects signatures older than five minutes. This bounds S3
signed requests; it does not shorten Identity Center sessions or temporary Access
Grants credentials. A generated URL remains a shareable bearer credential until its
effective expiry, and in-progress downloads may continue. Live tests must establish
managed-client compatibility, retries, denied users and actual revocation timing.

Seven-day S3 lifecycle expiry replaces the former custom broker's precise receipt
cutoff for portal downloads. Deletion is asynchronous and noncurrent versions may
remain longer. An exact seven-day access/deletion guarantee is not provided by this
model. Agree that distinction before enabling a recipient that requires a hard cutoff.

The custom HTTP API, browser page and signing Lambda are removed from the PR, with
planned retirement of their deployed development resources. Storage and transport
remain. Reuse of the hosted-pickup delivery component is a separate decision.

See the [component README](../pull-from-presigned-url/README.md) for onboarding,
migration and acceptance checks. No production rollout or live recipient grant has
been performed as part of this change.
