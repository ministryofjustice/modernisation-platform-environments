#### This file can be used to store locals specific to the member account ####
locals {
  base_domain               = "container-platform.service.justice.gov.uk"
  environment_configuration = local.environment_configurations[terraform.workspace]
  availability_zones        = slice(data.aws_availability_zones.available.names, 0, 3)

  #-----------------------------------------------------------------------------
  # Amazon Managed Grafana (AMG) host designation (ADR-005)
  #
  # The centralised AMG workspace is deployed only in these workspaces:
  #   - cloud-platform-live: the production central AMG serving all BUs and
  #     both live and non-live environments (single workspace).
  #   - cloud-platform-development: a test AMG in the development account so
  #     ephemeral clusters' dashboards and data sources can be validated.
  # Any other workspace plans no AMG. Deployment intent is declared here.
  #-----------------------------------------------------------------------------
  amg_host_workspaces = [
    "cloud-platform-live",
    "cloud-platform-development",
  ]
  enable_amg         = contains(local.amg_host_workspaces, terraform.workspace)
  amg_workspace_name = "${terraform.workspace}-observability"
}
