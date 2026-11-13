# Grafana Cloud

`grafana-cloud.tf` creates a new Grafana Cloud stack alongside the existing
Amazon Managed Grafana platform. It does not import or modify the `mojdigital`
test stack, migrate dashboards, or configure data sources. Private
connectivity is in `grafana-cloud-pdc.tf`, described below.

| Terraform workspace | AWS account | Grafana Cloud stack |
| --- | --- | --- |
| `observability-platform-development` | observability-platform-development | `mojobservabilitydevelopment` |
| `observability-platform-production` | observability-platform-production | `mojobservabilityproduction` |

Both stacks use Grafana region `prod-gb-south-1`, hosted on AWS London
(`eu-west-2`). Grafana region slugs are not AWS region names.
Stack names must be globally available.

## Credentials

Create a Grafana Cloud access policy token in the intended Grafana Cloud
organisation with `stacks:read`, `stacks:write`, and `stacks:delete` scopes.
Its realm must permit organisation-level stack creation, rather than only
access to an existing stack. The organisation associated with this token
determines where the new stacks are created; the AWS account does not.

Terraform creates the empty secret `grafana-cloud/terraform-access-policy-token`
(`secrets.tf`) in each account and reads it in `data.tf`. Populate its value
manually, as with the other Grafana secrets: the raw token as the secret
string, not a JSON object. Use separate tokens for development and production,
set an expiry, and rotate before expiry. The existing
`grafana/grafana-cloud-user` and `grafana/grafana-cloud-password` secrets are
unrelated and are not reused.

Secret values read by Terraform are stored in state and may be present in
saved plans: restrict access to both and to the state backend.

## First deployment order

The data lookup fails if the secret has no value, so deploy in stages:

1. Apply the `secrets.tf` resource only, creating the empty secret in both accounts.
2. Populate the token value in each account.
3. Apply the `data.tf` lookup, provider alias, and `grafana-cloud.tf` stack.

Alternatively, create and populate the secret manually first, then
`terraform import` the `aws_secretsmanager_secret` resource.

## Deployment and existing resources

The existing `.github/workflows/observability-platform.yml` workflow covers
these files and selects the corresponding account and Terraform workspace.
No new workflow or backend is needed. Review plans for both environments
before applying; the new resources must not replace existing Amazon Managed
Grafana resources.

The default `grafana` provider still targets Amazon Managed Grafana.
Cloud account resources explicitly use `provider = grafana.cloud`.
Future dashboards, folders, and data sources in Grafana Cloud need a separate
stack-level provider alias, authenticated with a service-account token for
that Cloud stack. Do not repoint the default provider or existing resources.

Stack destruction and replacement are blocked by `prevent_destroy`, including
the existing workflow's development destroy action. Any intentional stack
deletion requires an explicitly reviewed change to this protection.

## Private Data Source Connect (PDC) over PrivateLink

`grafana-cloud-pdc.tf` connects each environment's stack to its
`platforms-<environment>` VPC:

- a PDC network named `platforms-<environment>`
- a PDC network token, stored in the `grafana-cloud/pdc-agent-token` secret
- two PDC agent tasks on ECS Fargate in the general private subnets

PDC is switched on per environment with `enabled` in the `grafana_cloud_pdc`
local. Only development is enabled.

For the pilot, the agent image is `grafana/pdc-agent`, pulled from Docker Hub
through the Modernisation Platform network firewall. The task pins the image by
digest. The tenant module will move the image to an ECR repository in
core-shared-services.

The agents call the PDC API on TCP 443 and keep an SSH tunnel open to the
gateway on TCP 22. Both connections go through interface endpoints in the VPC.
Grafana sends queries back down the tunnel. Nothing connects inbound to the
VPC, and the PDC traffic doesn't use NAT or the network firewall.

All stacks in `prod-gb-south-1` share the same endpoint services, so one
endpoint pair per VPC serves both stacks. The
`grafana_cloud_pdc_private_connectivity` output shows the service names.

### Prerequisites

1. Add the `accesspolicies` Read, Write and Delete scopes to the Terraform
   access policy. PDC networks and their tokens are access policies.
2. In the `modernisation-platform` repository, `core-vpc/custom_endpoints.tf`
   adds the two PDC endpoints for the VPC. Each endpoint gets its own security
   group, and the gateway's group allows TCP 22 from the VPC CIDR. Check first
   that Grafana's endpoint services cover eu-west-2a, 2b and 2c.

### Rollout

1. Apply. This creates the PDC network, the token secret and the agents.
2. Check from inside the VPC that `*.vpce.grafana.net` resolves to private IP
   addresses.
3. Check that the agent logs in `/ecs/grafana-pdc-agent` show a connection,
   and that the PDC network in Grafana Cloud shows two agents.
4. Data-source owners allow the agent security group (the `agent_sg_id` value
   in the `grafana_cloud_pdc_network` output) into their data sources.
5. Optionally set `permit_remote_open` to restrict which `host:port`
   destinations the agent will forward queries to.

### Upgrading the agent

1. Get the image index digest for the new version, for example with
   `docker buildx imagetools inspect grafana/pdc-agent:<version>`.
2. Update the version and digest in `grafana_cloud_pdc_agent_image` and apply.

Grafana Cloud management API calls, browser access and alert notifications
still go over public HTTPS.
