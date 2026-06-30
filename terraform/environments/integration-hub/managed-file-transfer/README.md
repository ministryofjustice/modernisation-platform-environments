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

A proof of concept managed file transfer service for the Integration Hub. It lets external partners upload files over SFTP and FTPS (or a browser-based web app), scans every file for malware with Amazon GuardDuty, and routes clean files onward so the team can collect them.

### **Service URLs:**

<!--  The URL(s) of the service’s production environment, and test environments if possible-->

DNS follows the pattern `<endpoint>.<environment>.managed-file-transfer.service.justice.gov.uk` in non-production, and `<endpoint>.managed-file-transfer.service.justice.gov.uk` in production. The `<endpoint>` host names are:

| Host | Purpose |
| --- | --- |
| `sftp.*` | AWS Transfer Family SFTP endpoint |
| `ftps.*` | AWS Transfer Family FTPS endpoint |
| `web.*` | AWS Transfer Family web app (browser uploads) |
| `api.*` | API access, provisioned by the adjacent `api-platform` Terraform stack |

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
7. **Notification and downstream delivery.** When a clean object lands, the `send-presigned-url` module generates a time-limited presigned download URL, posts it to Slack, and publishes a client-facing notification event to SNS for downstream consumers. Optionally, the same Lambda can call a client-owned API to request a presigned destination URL and then push the clean file to that destination.

All buckets are KMS-encrypted, versioned, block public access, and have short (one day) lifecycle expiry as befits a transfer staging area.

## Optional

### **Other URLs:**

<!--  If you can, provide links to the service’s monitoring dashboard(s), health checks, documentation (ideally describing how to run/work with the service), and main GitHub repository. -->

- Main repository: [ministryofjustice/modernisation-platform-environments](https://github.com/ministryofjustice/modernisation-platform-environments) — this service lives under `terraform/environments/integration-hub/managed-file-transfer`.
- Custom identity provider documentation: [docs/custom-idp.md](docs/custom-idp.md)
- Monitoring: CloudWatch (structured Transfer logs, Lambda logs, saved Logs Insights queries and alarms) in the Integration Hub AWS account.

### **Expected speed and frequency of releases:**

<!-- How often are you able to release changes to your service, and how long do those changes take? -->

### **Automatic alerts:**

<!-- List, briefly, problems (or types of problem) that will automatically alert your team when they occur. -->

CloudWatch alarms publish to high- and low-priority SNS topics, which feed Amazon Q / AWS Chatbot in Slack. They cover:

- **Lambda health** — errors, throttles and duration for the custom identity provider, file-movement Lambdas and clean-file notification Lambda.
- **Queue health** — stale or accumulating messages on the S3 notification, GuardDuty event and clean-file notification queues.
- **Dead-letter queues** — any message arriving on a dead-letter queue.
- **GuardDuty Malware Protection for S3** — failed, skipped or infected object scans.
- **Transfer ingress volume** — unexpectedly high file ingress for the MVP.

## Client notification testing

For the API upload flow, clean files now also emit a downstream consumer notification with the client ID, transfer ticket, file details, and a presigned download URL.

In development, Terraform provisions a `products-poc` test SQS subscription for this SNS topic. Useful outputs are:

- `terraform output clean_file_client_notification_topic_arn`
- `terraform output products_poc_clean_file_notification_test_queue_url`

You can poll the queue with:

```bash
scripts/poll-clean-file-notification.sh \
  --profile integration-hub-development \
  --queue-url "$(terraform output -raw products_poc_clean_file_notification_test_queue_url)"
```

## Client-managed destination delivery

Some consumers want the platform to deliver the clean file onward rather than only notifying them. For that case, configure `client_destination_delivery` in `application_variables.json`, keyed by `clientId`:

```json
{
  "client_destination_delivery": {
    "products-poc": {
      "enabled": true,
      "request_url": "https://consumer.example.justice.gov.uk/mft/presigned-destination",
      "request_method": "POST",
      "request_timeout_seconds": 30,
      "request_auth_secret_name": "integration-hub-products-poc-destination-api-auth"
    }
  }
}
```

If `request_auth_secret_name` is set, the Lambda reads that Secrets Manager value and merges `headers` from the secret JSON into the API request. Expected secret shape:

```json
{
  "headers": {
    "Authorization": "Bearer <token>",
    "x-api-key": "<optional-key>"
  }
}
```

The consumer API receives a JSON payload in this shape:

```json
{
  "clientId": "products-poc",
  "transferTicket": "12345678-1234-1234-1234-123456789012",
  "fileName": "example.csv",
  "contentLengthBytes": 123,
  "contentType": "text/csv",
  "source": {
    "bucket": "integration-hub-clean-...",
    "key": "products-poc/uploads/2026/06/30/example.csv",
    "versionId": "..."
  }
}
```

The consumer API must return JSON containing either a top-level upload target or an `upload` object:

```json
{
  "upload": {
    "url": "https://destination.example.test/presigned-put",
    "method": "PUT",
    "headers": {
      "Content-Type": "text/csv"
    }
  }
}
```

The platform then streams the clean object from S3 to that presigned destination. Because Lambda retries can happen after partial progress, the consumer API should treat `transferTicket` as an idempotency key and tolerate a repeated request for a fresh presigned upload target.

### **Impact of an outage:**

<!-- A short description of the risks if your service is down for an extended period of time. -->

If the identity provider Lambda or the Transfer server is unavailable, partners cannot authenticate or upload files. If the post-scan pipeline is down, files remain in the `unscanned`/`processing` buckets and are not delivered, but short bucket lifecycle rules mean undelivered files expire after one day. As a proof of concept the service carries no production data.

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
- FTPS passive mode is configured with a single, automatically selected, `passive_ip`. Even though the Transfer server endpoint is deployed across multiple subnets with multiple Elastic IPs, the passive-mode response advertises only that one IP. Treat this as an FTPS passive-mode limitation of the current design when troubleshooting data-connection behaviour.

### **How to resolve specific issues:**

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->
