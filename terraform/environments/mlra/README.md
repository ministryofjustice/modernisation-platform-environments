# Service Runbook

<!-- This is a template that should be populated by the development team when moving to the modernisation platform, but also reviewed and kept up to date.
To ensure that people looking at your runbook can get the information they need quickly, your runbook should be short but clear. Throughout, only use acronyms if you’re confident that someone who has just been woken up at 3am would understand them. -->

_If you have any questions surrounding this page please post in the `#ask-laa-ops` channel._

## Mandatory Information

### **Last review date:**

<!-- Adding the last date this page was reviewed, with any accompanying information -->

### **Description:**

<!-- A short (less than 50 word) description of what your service does, and who it’s for.-->

MLRA (Means Assessment Administration Tool - Libra Record Access) is a web enabled application used to process criminal legal aid applications in the Magistrates and Crown Courts.

Also used for assessing if defendants are entitled to legal aid for criminal cases. End users consist of approximately 400 criminal case workers.

### **Service URLs:**

<!--  The URL(s) of the service’s production environment, and test environments if possible-->

Production - <https://maat-libra-administration-tool.service.justice.gov.uk/mlra/>

Also <https://mlra.legalservices.gov.uk/mlra/> redirects to the above URL. This is hosted in the LAA Landing Zone.

### **Incident response hours:**

<!-- When your service receives support for urgent issues. This should be written in a clear, unambiguous way. For example: 24/7/365, Office hours, usually 9am-6pm on working days, or 7am-10pm, 365 days a year. -->

9am to 5pm Monday to Friday except Bank Holidays.

### **Incident contact details:**

<!-- How people can raise an urgent issue with your service. This must not be the email address or phone number of an individual on your team, it should be a shared email address, phone number, or website that allows someone with an urgent issue to raise it quickly. -->

## laa-crime-apps is the slack channel for raising any issues with the product team

### **Service team contact:**

<!-- How people with non-urgent issues or questions can get in touch with your team. As with incident contact details, this must not be the email address or phone number of an individual on the team, it should be a shared email address or a ticket tracking system.-->

## laa-crime-apps

### **Hosting environment:**

Modernisation Platform

<!-- If your service is hosted on another MOJ team’s infrastructure, link to their runbook. If your service has another arrangement or runs its own infrastructure, you should list the supplier of that infrastructure (ideally linking to your account’s login page) and describe, simply and briefly, how to raise an issue with them. -->

## Optional

### **Other URLs:**

<!--  If you can, provide links to the service’s monitoring dashboard(s), health checks, documentation (ideally describing how to run/work with the service), and main GitHub repository. -->

<https://github.com/ministryofjustice/laa-mlra-application>

### **Expected speed and frequency of releases:**

<!-- How often are you able to release changes to your service, and how long do those changes take? -->

Application releases between once a month to once a quarter.

### **Automatic alerts:**

<!-- List, briefly, problems (or types of problem) that will automatically alert your team when they occur. -->

Alerts routed to #laa-alerts-mlra-non-prod & #laa-alerts-mlra-prod

### **Impact of an outage:**

<!-- A short description of the risks if your service is down for an extended period of time. -->

LAA Digital will classify any outage of the entire application as a P1 incident.

### **Out of hours response types:**

<!-- Describe how incidents that page a person on call are responded to. How long are out-of-hours responders expected to spend trying to resolve issues before they stop working, put the service into maintenance mode, and hand the issue to in-hours support? -->

Out of hours for specific needs such as a release that requires sys admin input are agreed in advance with the product team.

### **Consumers of this service:**

<!-- List which other services (with links to their runbooks) rely on this service. If your service is considered a platform, these may be too numerous to reasonably list. -->

MLRA connects to Infox - which is the LAA's interface between MLRA & HMCTS' Libra system - <https://github.com/ministryofjustice/laa-infoX-application>

Also MLRA uses MAAT DB for all of it's data storage - <https://github.com/ministryofjustice/laa-maat-database>

### **Services consumed by this:**

<!-- List which other services (with links to their runbooks) this service relies on. -->

None.

### **Restrictions on access:**

<!-- Describe any conditions which restrict access to the service, such as if it’s IP-restricted or only accessible from a private network.-->

Access to the application is limited to pre-defined CIDRS namely MOJ internal networks.

### **How to resolve specific issues:**

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->

Historically most issues have resolved around the pipeline being unable to update the cloudformation stack due to drift caused by manual changes of the infrastructure. This should not be the case with Mod Platform. There may also be requirements to upload a new source image to the ECR in mlra-development.
