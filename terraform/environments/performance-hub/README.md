# Service Runbook

<!-- This is a template that should be populated by the development team when moving to the modernisation platform, but also reviewed and kept up to date.
To ensure that people looking at your runbook can get the information they need quickly, your runbook should be short but clear. Throughout, only use acronyms if you’re confident that someone who has just been woken up at 3am would understand them. -->

_If you have any questions surrounding this page please post in the `#performance-hub-dev` channel or email `performance-hub@digital.justice.gov.uk`._

## Mandatory Information

### **Last review date:**

18th October 2022

### **Description:**

The HMPPS Performance Hub is a .NET Framework application with SQL Server database, which ingests data from various sources to produce performance metrics and reports for prisons and probation.

It only holds aggreagted or anonymised information. Data ingestion is generally via manual upload of Excel and CSV files rather than direct feeds from other systems.

### **Service URLs:**

Prod: [https://hmpps-performance-hub.service.justice.gov.uk/](https://hmpps-performance-hub.service.justice.gov.uk/)
Preprod: [https://staging.hmpps-performance-hub.service.justice.gov.uk/](https://staging.hmpps-performance-hub.service.justice.gov.uk/)

### **Incident response hours:**

Office hours, usually 8am-5pm on working days

### **Incident contact details:**

Email: `performance-hub@digital.justice.gov.uk` or `hubusers@justice.gov.uk`
Slack: `#performance-hub-dev`

### **Service team contact:**

As above - email: `performance-hub@digital.justice.gov.uk` or `hubusers@justice.gov.uk`. Slack `#performance-hub-dev`

Also via MS Teams: ["HMPPS Performance Hub"](https://teams.microsoft.com/l/channel/19%3a47f17e662a8a4719acf0eb2ca6755577%40thread.tacv2/Hub%2520-%2520General%2520and%2520Administration?groupId=bc48488e-a80a-4e39-8363-033022d67111&tenantId=c6874728-71e6-41fe-a9e1-2e8c36776ad8) channel.

### **Hosting environment:**

Modernisation Platform

## Optional

### **Other URLs:**

GitHub repo: [https://github.com/ministryofjustice/performance-hub](https://github.com/ministryofjustice/performance-hub)

GOV.UK Notify account: [https://www.notifications.service.gov.uk/services/1c1d15f2-46b4-4167-a8f1-18f5d65bd6f9](https://www.notifications.service.gov.uk/services/1c1d15f2-46b4-4167-a8f1-18f5d65bd6f9)

### **Expected speed and frequency of releases:**

The typical release cycle is weekly to preprod and monthly to prod.

### **Automatic alerts:**

Unhandled exceptions and serious errors generate email alerts to performance-hub@digital.justice.gov.uk

### **Impact of an outage:**

Short-term: minimal. The Performance Hub works on generally monthly reporting cycles, so a downtime of a few hours or even a couple of days is an inconvenience, not a disaster.

Contact `hubusers@justice.gov.uk` for assitance in notifying key users and stakeholders of an outage.

### **Out of hours response types:**

There are no official out of hours response arrangements (see ["imapct of an outage"](#impact-of-an-outage) above).

### **Consumers of this service:**

There are no direct consumers of the application. The Performance Hub does periodically drop data exports into an Analytical Platform landing bucket (a "push" to the AP rather than a "pull"), but the AP itself does not depend on this data.

### **Services consumed by this:**

The Performance Hub periodically performs automatic overnight data imports of data dropped into an Analyical Platform bucket. There are "manual" alternatives to this if it fails - users can upload data into the application directly.

There is also a dependency on the GOV.UK Notify serice (see ["other URLs"](#other-urls) above).
