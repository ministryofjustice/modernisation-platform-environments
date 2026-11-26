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

The `network` component owns the Observability Platform (OP) tenant module for
all twelve CP3 workspaces: `cloud-platform-{development,preproduction,nonlive,live}`
and `container-platform-{octo,laa,hmpps,cd}-{nonlive,live}`. Do not deploy the
tenant module from another component in these accounts: its IAM roles, ECS
cluster and service have fixed account-wide names.

#### Grafana Cloud stacks

`local.pdc_tenant_workspaces` in
[`network/observability_platform.tf`](network/observability_platform.tf) maps
every workspace to its Grafana Cloud stack and whether the tenant is enabled.
The OP account is derived from the stack (`observability-platform-<stack>`), so
an account's token secret, KMS key, restarter-role trust and stack always come
from the same OP environment.

| Workspace | Grafana Cloud stack | OP account | Tenant |
| --- | --- | --- | --- |
| `cloud-platform-development` | development | `observability-platform-development` | Enabled |
| `cloud-platform-{preproduction,nonlive,live}` | production | `observability-platform-production` | Disabled |
| `container-platform-{octo,laa,hmpps,cd}-nonlive` | production | `observability-platform-production` | Disabled |
| `container-platform-{octo,laa,hmpps,cd}-live` | production | `observability-platform-production` | Disabled |

The **whole module** is gated on `enabled`: disabled workspaces create no tenant
IAM roles, policy attachments or PDC resources. An enabled account must match an
account with `pdc_enabled = true` in the same stack's
[OP tenant configuration](../observability-platform/grafana-cloud-tenant-environment-configurations.tf),
which also creates its CloudWatch data source and its `grafana-cloud/pdc/<account ID>`
token secret. Do not add CloudWatch data sources for disabled accounts: they
would reference the missing `grafana-cloud` role.

The module's `moved` block preserves existing resources in enabled workspaces
when adding its count index. Never disable an enabled account or change its
stack: either would destroy or replace its tenant resources. If a disabled
workspace already has tenant resources in state, stop and reconcile its
ownership before deployment rather than approving a destroy. Never import
resources owned by another component.

The PDC service runs the module's default three Fargate tasks in
`module.cluster_vpc.private_subnets`, not the Transit Gateway attachment or pod
subnets. Private data-source targets default to the account's primary VPC CIDR
on TCP 443; the current development OpenSearch domain is public, so it is not a
private target. No private Grafana data source is created by this module.
The module also allows outbound TCP 22 and 443 to `0.0.0.0/0` for Grafana and AWS
APIs and image retrieval, so `allowed_targets` is additive, not a restrictive
data-source allowlist. Existing Transit Gateway egress provides the Docker Hub
image-pull path. Both stacks use the same Grafana Cloud cluster, so the same
PDC PrivateLink endpoints serve either stack.

#### Rollout order

`cloud-platform-development` on the development stack comes first. Enable a
production-stack account only after **both**:

1. **OP production is verified for that account.** OP production supports PDC
   (rotator, enrolment, alerts and tenant configuration). The account has
   `pdc_enabled = true` in the production tenant configuration. Using metadata
   only (never retrieve the token), its bootstrap journal is `completed`, its
   secret has a single version labelled only `AWSCURRENT`, and its enrolment
   rule, target, Lambda permissions and delivery alarm exist.
2. **The CP3 private-subnet preflight passes in that account.** From its
   private subnets, the hub DNS names resolve to the shared endpoints, TLS on
   443 and TCP on 22 connect, and the agent image can be pulled.

Then enable **one account per pull request** by setting its `enabled = true`,
without changing its stack. This matters most for the `container-platform-*`
workspaces, whose network applies run on merge without an approval gate. The
central token rotator has a reserved concurrency of one, so wait for each
account's enrolment to reach `enrolled` (first rotation done, agents
reconnected) before enabling the next.

Before changing the mapping, update `ENABLED` and `DEVELOPMENT_STACK` in
[`network/tests/run_pdc_tenant_tests.py`](network/tests/run_pdc_tenant_tests.py)
and run it:

```bash
python3 terraform/environments/cloud-platform/network/tests/run_pdc_tenant_tests.py
```

It plans the real gate in all twelve workspaces against a mocked AWS provider,
without a backend or credentials. Enabled workspaces must plan exactly 20 tenant
creates, with their stack's OP account and stack ID, three private Fargate tasks
and the VPC primary CIDR target. Disabled workspaces must have no changes. It then
force-enables each disabled workspace, without ever applying, to prove its
token secret, KMS access, restarter trust and stack all use its own stack's OP
account.

#### Apply order

The OP and CP3 workflows run independently. OP and `cloud-platform-*` applies
require GitHub environment approval; the eight `container-platform-*` network
applies do not. These gates therefore apply to **apply approvals as well as
merges**. Never approve an older run's apply after a newer run for the same
environment.

| Account | Workflow | Network apply environment | Approval |
| --- | --- | --- | --- |
| `cloud-platform-development` | `cloud-platform.yml`, on the pull request and on `main` | `cloud-platform-development-network` | Required |
| `cloud-platform-{preproduction,nonlive,live}` | `cloud-platform.yml`, on `main`, in parallel | `cloud-platform-<environment>-network` | Required |
| `container-platform-*` (from [`accounts.json`](accounts.json)) | `container-platform.yml`, on `main`, in parallel | `<account name>-network` | None |

Outside development, each account's network job runs after its root job. An
apply job only runs when its plan has changes. Any merge under
`terraform/environments/cloud-platform/` can therefore apply network changes to
every `container-platform-*` account immediately. The whole-module gate keeps
this tenant rollout a no-op in every disabled network workspace.

For each account:

1. Confirm the shared endpoint hub from
   [ministryofjustice/modernisation-platform#14437](https://github.com/ministryofjustice/modernisation-platform/pull/14437)
   and its DNS-name correction,
   [ministryofjustice/modernisation-platform#14446](https://github.com/ministryofjustice/modernisation-platform/pull/14446),
   are applied. From CP3 private subnets,
   `pdc-grafana-datasources-api.eu-west-2.vpce.grafana.net` and
   `pdc-grafana-datasources.eu-west-2.vpce.grafana.net` must resolve to the hub
   endpoints and accept TCP 443 and 22 respectively. CP3 already associates
   the hub's Route 53 Profile and routes `10.20.240.0/20` through the Transit Gateway.
2. Apply the OP change for the account's stack. Its apply bootstraps the
   `grafana-cloud/pdc/<account ID>` secret in that stack's OP account through
   the central token rotator. Do not apply it while any existing account's
   rotation step is in flight. Using metadata only (never retrieve the token),
   confirm that:
   - its bootstrap journal is `completed`
   - its secret has a single version, labelled only `AWSCURRENT`
   - its enrolment rule, target, Lambda permissions and delivery alarm exist

   See the [PDC token lifecycle runbook](../observability-platform/docs/grafana-cloud/pdc-token-rotation.md).
3. Deploy its agents: approve its `cloud-platform-*` network apply, or merge
   its `container-platform-*` change. Confirm three running tasks and connected
   agents in its Grafana PDC network. Wait for its enrolment to reach `enrolled`
   (first rotation done, agents reconnected) before enabling the next account.
   Check the agent logs and image retrieval if tasks do not start. Pending
   enrolment alerts after one day, so do not leave bootstrapped accounts
   without agents.

### **Restrictions on access:**

<!-- Describe any conditions which restrict access to the service, such as if it’s IP-restricted or only accessible from a private network.-->

### **How to resolve specific issues:**

<!-- Describe the steps someone might take to resolve a specific issue or incident, often for use when on call. This may be a large amount of information, so may need to be split out into multiple pages, or link to other documents.-->
