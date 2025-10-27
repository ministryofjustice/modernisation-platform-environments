# Service Runbook

<!-- This is a template that should be populated by the development team when moving to the modernisation platform, but also reviewed and kept up to date.
To ensure that people looking at your runbook can get the information they need quickly, your runbook should be short but clear. Throughout, only use acronyms if you’re confident that someone who has just been woken up at 3am would understand them. -->

_If you have any questions surrounding this page please post in the `#laa-ccms-support` channel._

## Mandatory Information

### **Last review date:**

28-Jun-2023

<!-- Adding the last date this page was reviewed, with any accompanying information -->

### **Description:**

CCMS contacts, availability and other details for incidents

<!-- A short (less than 50 word) description of what your service does, and who it’s for.-->

### **Service URLs:**

CCMS EBS PROD - <https://ccmsebs.legalservices.gov.uk>

All other environment details are in the below link
<https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/4396647104/MP+Modernisation+Platform+EBS+Environment+Details>

<!--  The URL(s) of the service’s production environment, and test environments if possible-->

### **Incident response hours:**

09:00 am to 5:00 pm Monday to Friday

<!-- When your service receives support for urgent issues. This should be written in a clear, unambiguous way. For example: 24/7/365, Office hours, usually 9am-6pm on working days, or 7am-10pm, 365 days a year. -->

### **Incident contact details:**

Team can be reached on slack channel #laa-ccms-support.
Please tag the primary/platforms DM in case of platforms P1/P2 incidents or a secondary DM if the primary/platforms DM is unavailable

<!-- How people can raise an urgent issue with your service. This must not be the email address or phone number of an individual on your team, it should be a shared email address, phone number, or website that allows someone with an urgent issue to raise it quickly. -->

### **Service team contact:**

CCMS Platforms (Primary) -> <rob.murley@digital.justice.gov.uk>
Civil Applications (Secondary) -> <ieuan.jones@digital.justice.gov.uk>
Civil Billing & payments (Secondary) -> <aruna.vemulamanda@digital.justice.gov.uk>

<!-- How people with non-urgent issues or questions can get in touch with your team. As with incident contact details, this must not be the email address or phone number of an individual on the team, it should be a shared email address or a ticket tracking system.-->

### **Hosting environment:**

EBS DB -     ec2-ccms-ebs-production-ebsdb

EBS Apps -   ec2-ccms-ebs-production-ebsapps-1
             ec2-ccms-ebs-production-ebsapps-2

Webgate -    ec2-ccms-ebs-production-webgate-1
             ec2-ccms-ebs-production-webgate-2

Accessgate - ec2-ccms-ebs-production-accessgate-1
             ec2-ccms-ebs-production-accessgate-2

### **Migration RunBook:**

<https://dsdmoj.atlassian.net/wiki/spaces/~635fb1501db4d2ebcf649a1c/pages/4411392032/EBS+Migration+Runbook+-+Prod>

<https://dsdmoj.atlassian.net/wiki/spaces/CCMS/pages/4172054611/CCMS+DBA>

Modernisation Platform

<!-- If your service is hosted on another MOJ team’s infrastructure, link to their runbook. If your service has another arrangement or runs its own infrastructure, you should list the supplier of that infrastructure (ideally linking to your account’s login page) and describe, simply and briefly, how to raise an issue with them. -->

## Optional

### **Other URLs:**

<!--  If you can, provide links to the service’s monitoring dashboard(s), health checks, documentation (ideally describing how to run/work with the service), and main GitHub repository. -->

### **Expected speed and frequency of releases:**

<!-- How often are you able to release changes to your service, and how long do those changes take? -->

### **Automatic alerts:**

<!-- List, briefly, problems (or types of problem) that will automatically alert your team when they occur. -->

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

### **How to resolve specific issues:**

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->
