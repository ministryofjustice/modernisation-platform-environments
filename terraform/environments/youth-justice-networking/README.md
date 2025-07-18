# Service Runbook

<!-- This is a template that should be populated by the development team when moving to the modernisation platform, but also reviewed and kept up to date.
To ensure that people looking at your runbook can get the information they need quickly, your runbook should be short but clear. Throughout, only use acronyms if you’re confident that someone who has just been woken up at 3am would understand them. -->

_If you have any questions surrounding this page please post in the `#team-name` channel._

## Mandatory Information

### **Last review date:**

1st July 2025

<!-- Adding the last date this page was reviewed, with any accompanying information -->

### **Description:**

This is for the Juniper firewall network (AKA YJS CUG) that all YJB stakeholders use to exchange XML documents with the messaging system called YJSM. This serves YJB Production, Pre-Production and Test environments for YJAF.

<!-- A short (less than 50 word) description of what your service does, and who it’s for.-->

### **Service URLs:**

N/A as not an external facing system. Access is only via a Juniper

<!--  The URL(s) of the service’s production environment, and test environments if possible-->

### **Incident response hours:**

The NECSWS helpdesk hours are 24 x 7 x 365

<!-- When your service receives support for urgent issues. This should be written in a clear, unambiguous way. For example: 24/7/365, Office hours, usually 9am-6pm on working days, or 7am-10pm, 365 days a year. -->

### **Incident contact details:**

YJS Helpdesk Tel:    01429 558255
YJS Helpdesk Email:    <yjafsupport@necsws.com>

<!-- How people can raise an urgent issue with your service. This must not be the email address or phone number of an individual on your team, it should be a shared email address, phone number, or website that allows someone with an urgent issue to raise it quickly. -->

### **Service team contact:**

YJS Helpdesk Tel:    01429 558255
YJS Helpdesk Email:    <yjafsupport@necsws.com>

<!-- How people with non-urgent issues or questions can get in touch with your team. As with incident contact details, this must not be the email address or phone number of an individual on the team, it should be a shared email address or a ticket tracking system.-->

### **Hosting environment:**

Modernisation Platform

<!-- If your service is hosted on another MOJ team’s infrastructure, link to their runbook. If your service has another arrangement or runs its own infrastructure, you should list the supplier of that infrastructure (ideally linking to your account’s login page) and describe, simply and briefly, how to raise an issue with them. -->

## Optional

### **Other URLs:**

N/A

<!--  If you can, provide links to the service’s monitoring dashboard(s), health checks, documentation (ideally describing how to run/work with the service), and main GitHub repository. -->

### **Expected speed and frequency of releases:**

Typically only when new requirements are presented

<!-- How often are you able to release changes to your service, and how long do those changes take? -->

### **Automatic alerts:**

There are automated alerts for failed messages and are sent from YJSM to those on theapp distribution list

<!-- List, briefly, problems (or types of problem) that will automatically alert your team when they occur. -->

### **Impact of an outage:**

The system can tolerate some downtime as there are other mechanism to submit the data

<!-- A short description of the risks if your service is down for an extended period of time. -->

### **Out of hours response types:**

Same as in hours, call the NECSWS suppoort desk

<!-- Describe how incidents that page a person on call are responded to. How long are out-of-hours responders expected to spend trying to resolve issues before they stop working, put the service into maintenance mode, and hand the issue to in-hours support? -->

### **Consumers of this service:**

YJS Stakeholders, primarily YOTs (Youth Offending Teams) and some YOT CMS Suppliers

<!-- List which other services (with links to their runbooks) rely on this service. If your service is considered a platform, these may be too numerous to reasonably list. -->

### **Services consumed by this:**

<!-- List which other services (with links to their runbooks) this service relies on. -->

### **Restrictions on access:**

YJSM is only available via the CUG (Juniper network), at present, no other way to interact with that system

<!-- Describe any conditions which restrict access to the service, such as if it’s IP-restricted or only accessible from a private network.-->

### **How to resolve specific issues:**

Too bespoke, contact the NECSWS helpdesk

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->
