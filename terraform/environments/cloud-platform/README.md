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

### Grafana Cloud PDC PrivateLink endpoints

The `network` component creates local Grafana PDC API (TCP 443) and SSH gateway
(TCP 22) interface endpoints in these VPC workspaces only:

- `cloud-platform-development`, `cloud-platform-preproduction`, `cloud-platform-nonlive`
- `container-platform-{cd,hmpps,laa,octo}-nonlive`

All live/production VPCs are excluded by an explicit allow-list. These endpoints
use the `prod-gb-south-1` services shared by both Observability Platform Grafana
Cloud stacks, matching [the MP implementation](https://github.com/ministryofjustice/modernisation-platform/pull/14378).
They incur interface endpoint charges even before agents are deployed.

Endpoints use the VPC's private subnets in every AZ that the service exposes
within this VPC. Supported AZ names are discovered in the endpoint-owning account;
a service with no matching AZ fails the plan rather than selecting a default subnet.
Dedicated security groups allow only the relevant service port from the VPC's
primary and secondary (pod) CIDRs. No ingress from other Transit Gateway spokes
or new outbound security group rules are added.

Private DNS is enabled on each endpoint. The VPC module enables DNS support and
hostnames by default. Future agents must explicitly use
`-api-fqdn private-datasource-connect-api.eu-west-2.vpce.grafana.net` and
`-gateway-fqdn private-datasource-connect.eu-west-2.vpce.grafana.net`, as described
in [Grafana's PrivateLink guidance](https://grafana.com/docs/grafana-cloud/observe-and-act/connect-externally-hosted/private-data-source-connect/pdc-agent-aws-privatelink/).
Public PDC hostnames are not overridden. Existing S3/DynamoDB gateway endpoints,
the shared AWS interface endpoint Route53 Profile association and the Transit
Gateway routes remain unchanged.

For the **CP3 OpenSearch use case**, PDC is only needed once OpenSearch moves
into the VPC. At that point agents and PrivateLink endpoints are needed in the
CP account hosting the domain. Confirm that the OpenSearch data source supports
Grafana Assume Role and PDC together before rollout; that compatibility has not
been verified here. This does not imply that other private data sources do not
need PDC today. This configuration provisions endpoints only, not agents or
OpenSearch changes. Future SigV4/Assume Role access also needs working STS HTTPS
connectivity and the appropriate IAM permissions.

Before deploying, review the network plans for all seven non-production and
five live workspaces. Expect two endpoints, two security groups and four ingress
rules per selected VPC, and no PDC resources or changes to shared endpoints in
live workspaces. Confirm endpoint service access/acceptance and DNS resolution
in each CP account; do not assume that access from the MP accounts proves CP
account access.

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
