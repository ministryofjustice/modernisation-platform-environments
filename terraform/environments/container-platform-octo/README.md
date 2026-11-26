# Service Runbook

<!-- This is a template that should be populated by the development team when moving to the modernisation platform, but also reviewed and kept up to date.
To ensure that people looking at your runbook can get the information they need quickly, your runbook should be short but clear. Throughout, only use acronyms if you’re confident that someone who has just been woken up at 3am would understand them. -->

_If you have any questions surrounding this page please post in the `#team-name` channel._

## Mandatory Information

### **Last review date:**

<!-- Adding the last date this page was reviewed, with any accompanying information -->

### **Description:**

<!-- A short (less than 50 word) description of what your service does, and who it’s for.-->

### **Service URLs:**

<!--  The URL(s) of the service’s production environment, and test environments if possible-->

### **Incident response hours:**

<!-- When your service receives support for urgent issues. This should be written in a clear, unambiguous way. For example: 24/7/365, Office hours, usually 9am-6pm on working days, or 7am-10pm, 365 days a year. -->

### **Incident contact details:**

<!-- How people can raise an urgent issue with your service. This must not be the email address or phone number of an individual on your team, it should be a shared email address, phone number, or website that allows someone with an urgent issue to raise it quickly. -->

### **Service team contact:**

<!-- How people with non-urgent issues or questions can get in touch with your team. As with incident contact details, this must not be the email address or phone number of an individual on the team, it should be a shared email address or a ticket tracking system.-->

### **Hosting environment:**

Modernisation Platform

<!-- If your service is hosted on another MOJ team’s infrastructure, link to their runbook. If your service has another arrangement or runs its own infrastructure, you should list the supplier of that infrastructure (ideally linking to your account’s login page) and describe, simply and briefly, how to raise an issue with them. -->

## Optional

### Grafana Cloud private data source connect (PDC)

`observability_platform.tf` deploys the tenant module's Grafana access roles and
PDC agents for the **development** Grafana Cloud stack in `container-platform-octo-nonlive`
only. `container-platform-octo-live` creates no resources.

Apply the central Octo nonlive opt-in first. Before deploying the agents, confirm
that the bootstrap journal is `completed` and the central secret has a single
`AWSCURRENT` version. ECS reads the token from that secret; do not copy it. See
the [central rollout runbook](../observability-platform/docs/grafana-cloud/pdc-token-rotation.md).

The agents run in the CP3 VPC's `SubnetType=Private` subnets, not its Transit
Gateway attachment subnets or the stub VPC in this folder. From those private
subnets, verify that both names below resolve to the
[shared hub endpoints](https://github.com/ministryofjustice/modernisation-platform/pull/14437)
through the `centralised-endpoints` Route 53 Profile:

| Endpoint | Private DNS name | Connectivity check |
| --- | --- | --- |
| PDC API | `private-datasource-connect-api.eu-west-2.vpce.grafana.net` | Verify TLS on TCP 443 |
| PDC gateway | `private-datasource-connect.eu-west-2.vpce.grafana.net` | Connect on TCP 22 |

Fargate relies on CP3 egress via the Transit Gateway to pull
`docker.io/grafana/pdc-agent`; confirm the pull works before deploying. No private
data-source targets are configured. Identify a target and configure its connectivity
before testing a private query.

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
