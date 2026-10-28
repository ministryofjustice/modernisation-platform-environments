# Service Runbook

<!-- This is a template that should be populated by the development team when moving to the modernisation platform, but also reviewed and kept up to date.
To ensure that people looking at your runbook can get the information they need quickly, your runbook should be short but clear. Throughout, only use acronyms if you’re confident that someone who has just been woken up at 3am would understand them. -->

_If you have any questions surrounding this page please post in the `#ask-integration-hub` channel._

## Mandatory Information

### **Last review date:**

2026-10-19

### **Description:**

A one-way managed file transfer service, provided by the Integration Hub, to all MOJ agencies.

### **Service URLs:**

- ftps.file-transfer.service.justice.gov.uk
- sftp.file-transfer.service.justice.gov.uk
- <https://web.file-transfer.service.justice.gov.uk>

### **Incident response hours:**

Office hours, usually 9am-5pm on week days

### **Incident contact details:**

_If you have an urgent issue with the service, please post in the `#ask-integration-hub` channel._

### **Service team contact:**

You can contact the Integration Hub team via the `#ask-integration-hub` channel on Slack.

### **Hosting environment:**

Modernisation Platform

## Optional

### **Other URLs:**

[Service documentation](https://user-guide.integration-hub.service.justice.gov.uk/file-transfer-service/)

### **Expected speed and frequency of releases:**

We expect to make regular changes until March 1st, 2027.

### **Automatic alerts:**

The [parent CloudWatch alarms](./locals-cloudwatch.tf), [push-to-s3](./push-to-s3/locals-cloudwatch.tf), [hosted pickup](./push-to-s3-with-hosted-pickup/locals-cloudwatch.tf) and [push-to-sftp](./push-to-sftp/locals-cloudwatch.tf) delivery alarms, and [presigned URL pickup alarms](./pull-from-presigned-url/locals-cloudwatch.tf) publish to encrypted SNS topics connected to PagerDuty. In production, dead-letter backlogs and terminal delivery failures go to `#integration-hub-high-priority-alerts`; other delivery alarms go to `#integration-hub-low-priority-alerts`. Outside production, high-priority alarms go to the low-priority channel and low-priority alarms do not notify. Connected infrastructure alarms notify PagerDuty when they return to OK. Terminal delivery failure alarms do not send OK notifications: a quiet metric does not mean the file was delivered, so resolve those PagerDuty incidents after investigation. Both PagerDuty services currently share the same member escalation policy; the channel names do not imply different paging cover or out-of-hours support.

### **Impact of an outage:**

At present no impact as the service is under development.

### **Out of hours response types:**

No out-of-hours support at present.

### **Consumers of this service:**

None yet; the service is still under development.

### **Services consumed by this:**

None yet; the service is still under development.

### **Restrictions on access:**

You must be a Ministry of Justice service. You may request access on behalf of a third party which needs to send files to you.

### **How to resolve specific issues:**

See the [service guidance](https://user-guide.integration-hub.service.justice.gov.uk/file-transfer-service/operations/) for file investigations, dead-letter queue recovery, file action dispatch and user authentication troubleshooting. Keep detailed guidance in the user guide rather than duplicating it here.

See the [push-to-sftp component](./push-to-sftp/README.md) for SFTP deployment prerequisites, credentials and delivery recovery boundaries.

### **How to trigger the deploy workflow for Lambda changes:**

The Lambda code under `lambda/` is packaged by Terraform (`lambda.tf`), so it only deploys through the `integration-hub-file-transfer` workflow.

For push and pull request events, the workflow only includes `root` in its plan/apply matrix when a file directly in this folder changes. Changes under `lambda/` or `schemas/` alone do not include `root`, so they would not deploy the Lambda code.

When you change Lambda code, also update the date below so the workflow runs and deploys the new code:

Lambda last changed: 2026-10-14
