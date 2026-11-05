# Grafana Cloud

`grafana-cloud.tf` creates a new Grafana Cloud stack alongside the existing
Amazon Managed Grafana platform. It does not import or modify the `mojdigital`
test stack, migrate dashboards, configure data sources, or deploy PDC agents
and VPC endpoints.

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

## Private connectivity follow-up

The `grafana_cloud_stack` output exposes the new stack's ID, slug, URL, and
region. The `grafana_cloud_pdc_private_connectivity` output exposes the PDC
API and SSH gateway service names and private DNS names returned by Grafana.
Use these values rather than copying the pilot stack's endpoint identifiers.

The VPC owner must provision the interface endpoints in the shared VPC,
selecting supported availability zones and allowing the agent to reach the
API on TCP 443 and the SSH gateway on TCP 22. PDC networks, agent credentials,
agents, and target security-group rules are a separate deployment. Grafana
Cloud management API calls and browser access remain public HTTPS.
