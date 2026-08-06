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

> *.managed-file-transfer.service.justice.gov.uk

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

You can see the CloudWatch alarms configured for the service [here](./locals-cloudwatch.tf).
As the service matures we will integrate alarms with PagerDuty to ensure that the right people are notified when an alarm is triggered.

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
