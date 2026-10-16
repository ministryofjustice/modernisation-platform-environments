# Service Runbook

<!-- This is a template that should be populated by the development team when moving to the modernisation platform, but also reviewed and kept up to date.
To ensure that people looking at your runbook can get the information they need quickly, your runbook should be short but clear. Throughout, only use acronyms if you’re confident that someone who has just been woken up at 3am would understand them. -->

_If you have any questions surrounding this page please post in the `#ask-integration-hub` channel._

## Mandatory Information

### **Last review date:**

2026-07-22

### **Description:**

A one-way managed file transfer service, provided by the Integration Hub, to all MOJ agencies.

### **Service URLs:**

> ftps.file-transfer.service.justice.gov.uk
> sftp.file-transfer.service.justice.gov.uk
> web.file-transfer.service.justice.gov.uk

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

<!--  If you can, provide links to the service’s monitoring dashboard(s), health checks, documentation (ideally describing how to run/work with the service), and main GitHub repository. -->

### **Expected speed and frequency of releases:**

We expect to make regular changes until October 1st, 2026.

### **Automatic alerts:**

The [parent CloudWatch alarms](./locals-cloudwatch.tf) and the [push-to-s3](./push-to-s3/locals-cloudwatch.tf) and [hosted pickup](./push-to-s3-with-hosted-pickup/locals-cloudwatch.tf) delivery alarms publish to encrypted SNS topics connected to PagerDuty. In production, dead-letter backlogs and terminal delivery failures go to `#integration-hub-high-priority-alerts`; other delivery alarms go to `#integration-hub-low-priority-alerts`. Outside production, high-priority alarms go to the low-priority channel and low-priority alarms do not notify. Connected infrastructure alarms notify PagerDuty when they return to OK. Terminal delivery failure alarms do not send OK notifications: a quiet metric does not mean the file was delivered, so resolve those PagerDuty incidents after investigation. Both PagerDuty services currently share the same member escalation policy; the channel names do not imply different paging cover or out-of-hours support.

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

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->

See [file action dispatch](./docs/file-action-dispatch.md) for dispatch configuration, matching and failure behaviour.

### **How to trigger the deploy workflow for Lambda changes:**

The Lambda code under `lambda/` is packaged by Terraform (`lambda.tf`), so it only deploys through the `integration-hub-file-transfer` workflow.

Keep the Lambda module's default `recreate_missing_package = true` and `trigger_on_package_timestamp = true` in this Terraform root. Each GitHub Actions job starts without local ZIP artefacts, even when Terraform state records a successful build from an earlier failed apply. Disabling timestamp triggers prevents those missing packages from being rebuilt. STAGE and ROUTE use distinct `hash_extra` values because concurrent builds from the same source directory must not write to the same ZIP.

These modules build their own packages and use `ignore_source_code_hash = true`: their generated ZIP filenames already contain a hash of the source and packaging inputs, and changes to those filenames trigger deployments. This avoids recalculating a ZIP hash that can change from an old planned value to a new value when a missing package is rebuilt during apply. Keep missing-package recovery enabled; ignoring the ZIP hash does not recreate a missing file by itself. This relies on changes being reflected in the hashed inputs, so dependency updates must also update the relevant dependency manifests.

The workflow only plans and applies `root` when a file directly in this folder changes. Changes under `lambda/`, `docs/` or `schemas/` alone are skipped, so they would not deploy.

When you change Lambda code, also update the date below so the workflow runs and deploys the new code:

Lambda last changed: 2026-10-15
