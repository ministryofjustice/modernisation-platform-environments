# Service Runbook

<!-- This is a template that should be populated by the development team when moving to the modernisation platform, but also reviewed and kept up to date.
To ensure that people looking at your runbook can get the information they need quickly, your runbook should be short but clear. Throughout, only use acronyms if you’re confident that someone who has just been woken up at 3am would understand them. -->

_If you have any questions surrounding this page please post in the `#ask-integration-hub` channel._

## Mandatory Information

### **Last review date:**

<!-- Adding the last date this page was reviewed, with any accompanying information -->

22 June 2026

### **Description:**

<!-- A short (less than 50 word) description of what your service does, and who it’s for.-->

A proof of concept managed file transfer service for the Integration Hub. It lets external partners upload files over SFTP and FTPS (or a browser-based web app), scans every file for malware with Amazon GuardDuty, and applies preset patterns clean files are ready to collect.

### **Service URLs:**

<!--  The URL(s) of the service’s production environment, and test environments if possible-->

DNS follows the pattern `<endpoint>.<environment>.managed-file-transfer.service.justice.gov.uk` in non-production, and `<endpoint>.managed-file-transfer.service.justice.gov.uk` in production. The `<endpoint>` host names are:

| Host | Purpose |
| --- | --- |
| `sftp.*` | AWS Transfer Family SFTP endpoint |
| `ftps.*` | AWS Transfer Family FTPS endpoint |
| `web.*` | AWS Transfer Family web app (browser uploads) |
| `api.*` | Reserved for future API access (not yet provisioned) |

For example, the development SFTP endpoint resolves at `sftp.development.managed-file-transfer.service.justice.gov.uk`.

### **Incident response hours:**

<!-- When your service receives support for urgent issues. This should be written in a clear, unambiguous way. For example: 24/7/365, Office hours, usually 9am-6pm on working days, or 7am-10pm, 365 days a year. -->

Office hours, usually 9am–5pm on working days. As a proof of concept there is no out-of-hours support.

### **Incident contact details:**

<!-- How people can raise an urgent issue with your service. This must not be the email address or phone number of an individual on your team, it should be a shared email address, phone number, or website that allows someone with an urgent issue to raise it quickly. -->

Raise urgent issues in the `#ask-integration-hub` Slack channel.

### **Service team contact:**

<!-- How people with non-urgent issues or questions can get in touch with your team. As with incident contact details, this must not be the email address or phone number of an individual on the team, it should be a shared email address or a ticket tracking system.-->

For non-urgent questions, contact the team in the `#ask-integration-hub` Slack channel.

### **Hosting environment:**

Modernisation Platform

<!-- If your service is hosted on another MOJ team’s infrastructure, link to their runbook. If your service has another arrangement or runs its own infrastructure, you should list the supplier of that infrastructure (ideally linking to your account’s login page) and describe, simply and briefly, how to raise an issue with them. -->

## Architecture overview

The service is built entirely from AWS managed services, provisioned with Terraform in this directory.

1. **Ingress.** Partners connect to an AWS Transfer Family server over SFTP or FTPS (FTPS uses an ACM certificate), or upload through the AWS Transfer Family web app. The server runs on a VPC endpoint with a static Elastic IP.
2. **Authentication.** The Transfer server delegates authentication to a custom identity provider (a Lambda function backed by DynamoDB and Secrets Manager). See [docs/custom-idp.md](docs/custom-idp.md) for full detail.
3. **Landing.** Authenticated users can only write to their own logical home directory in the `unscanned` S3 bucket.
4. **Move to scanning.** An S3 event notification puts a message on an SQS queue; the `unscanned-to-processing` Lambda moves the object into the `processing` bucket (idempotently, using a DynamoDB table).
5. **Malware scanning.** GuardDuty Malware Protection for S3 scans every object in the `processing` bucket and tags it with the result.
6. **Post-scan routing.** EventBridge rules react to the scan result and a Lambda moves the object to:
   - `clean` — `NO_THREATS_FOUND`
   - `quarantine` — `THREATS_FOUND`
   - `investigation` — `UNSUPPORTED`, `ACCESS_DENIED` or `FAILED`
7. **Notification.** When a clean object lands, the `send-presigned-url` module generates a time-limited presigned download URL and posts it to Slack.

All buckets are KMS-encrypted, versioned, block public access, and have short (one day) lifecycle expiry as befits a transfer staging area.

## Optional

### **Other URLs:**

<!--  If you can, provide links to the service’s monitoring dashboard(s), health checks, documentation (ideally describing how to run/work with the service), and main GitHub repository. -->

- Main repository: [ministryofjustice/modernisation-platform-environments](https://github.com/ministryofjustice/modernisation-platform-environments) — this service lives under `terraform/environments/integration-hub/managed-file-transfer`.
- Custom identity provider documentation: [docs/custom-idp.md](docs/custom-idp.md)
- Monitoring: CloudWatch (structured Transfer logs, Lambda logs and alarms) in the Integration Hub AWS account.

### **Expected speed and frequency of releases:**

<!-- How often are you able to release changes to your service, and how long do those changes take? -->

### **Automatic alerts:**

<!-- List, briefly, problems (or types of problem) that will automatically alert your team when they occur. -->

CloudWatch alarms are configured for the custom identity provider Lambda:

- **Errors** — any function error.
- **Throttles** — any throttled invocation (concurrency exhausted).
- **Duration** — average runtime approaching the 30-second authentication timeout.

### **Impact of an outage:**

<!-- A short description of the risks if your service is down for an extended period of time. -->

If the identity provider Lambda or the Transfer server is unavailable, partners cannot authenticate or upload files. If the post-scan pipeline is down, files remain in the `unscanned`/`processing` buckets and are not delivered, but short bucket lifecycle rules mean undelivered files expire after one day. As a proof of concept the service carries no production data.

### **Impact of an outage:**

<!-- A short description of the risks if your service is down for an extended period of time. -->

### **Out of hours response types:**

<!-- Describe how incidents that page a person on call are responded to. How long are out-of-hours responders expected to spend trying to resolve issues before they stop working, put the service into maintenance mode, and hand the issue to in-hours support? -->

### **Consumers of this service:**

<!-- List which other services (with links to their runbooks) rely on this service. If your service is considered a platform, these may be too numerous to reasonably list. -->

### **Services consumed by this:**

<!-- List which other services (with links to their runbooks) this service relies on. -->

### **Restrictions on access:**

<!-- Describe any conditions which restrict access to the service, such as if it’s IP-restricted or only accessible from a private network.-->

- Each user is restricted to their own logical home directory and may only upload (not download or list other users' files) to the `unscanned` bucket.
- The custom identity provider supports per-user and per-provider IPv4 allow lists (`ingress_cidr_blocks`). In development this currently defaults to `0.0.0.0/0` and will be tightened before any real use.
- The web app is gated behind AWS IAM Identity Center and S3 Access Grants.

### **How to resolve specific issues:**

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->
