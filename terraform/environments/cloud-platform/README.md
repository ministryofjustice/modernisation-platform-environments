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

### Grafana Cloud Private Data Source Connect

The `network` component deploys one Observability Platform tenant module per
account, using the **development** Grafana Cloud stack for all twelve CP3
workspaces: `cloud-platform-{development,preproduction,nonlive,live}` and
`container-platform-{octo,laa,hmpps,cd}-{nonlive,live}`. This includes the live
accounts. Do not deploy the tenant module from another component in these
accounts: its IAM roles, ECS cluster and service have fixed account-wide names.

The PDC service runs the module's default three Fargate tasks in
`module.cluster_vpc.private_subnets`, not the Transit Gateway attachment or pod
subnets. Private data-source targets default to the account's primary VPC CIDR
on TCP 443; the current development OpenSearch domain is public, so it is not a
private target. No private Grafana data source is created by this module.
The default CloudWatch data sources use its `grafana-cloud` IAM role instead.
The module also allows outbound TCP 22 and 443 to `0.0.0.0/0` for Grafana and AWS
APIs and image retrieval, so `allowed_targets` is additive, not a restrictive
data-source allowlist. Existing Transit Gateway egress provides the Docker Hub
image-pull path.

Deploy in this order; the OP and CP3 workflows do not enforce cross-account
ordering:

1. Apply the development [OP tenant configuration](../observability-platform/grafana-cloud-tenant-environment-configurations.tf)
   with `pdc_enabled = true` for all twelve accounts. Confirm each
   `grafana-cloud/pdc/<account ID>` secret in `observability-platform-development`
   has an `AWSCURRENT` version using metadata only; do not retrieve the token.
   Follow the [PDC token lifecycle runbook](../observability-platform/docs/grafana-cloud/pdc-token-rotation.md)
   for the active bootstrap and rotation process.
2. Confirm the shared endpoint hub from
   [ministryofjustice/modernisation-platform#14437](https://github.com/ministryofjustice/modernisation-platform/pull/14437)
   and its DNS-name correction are deployed. From CP3 private subnets,
   `pdc-grafana-datasources-api.eu-west-2.vpce.grafana.net` and
   `pdc-grafana-datasources.eu-west-2.vpce.grafana.net` must resolve to the hub
   endpoints and accept TCP 443 and 22 respectively. CP3 already associates
   the hub's Route 53 Profile and routes `10.20.240.0/20` through the Transit Gateway.
3. Deploy the CP3 `network` components, then confirm three running tasks per
   account and connected agents in each Grafana PDC network. Check the agent
   logs and image retrieval if tasks do not start.

### **Restrictions on access:**

<!-- Describe any conditions which restrict access to the service, such as if it’s IP-restricted or only accessible from a private network.-->

### **How to resolve specific issues:**

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->
