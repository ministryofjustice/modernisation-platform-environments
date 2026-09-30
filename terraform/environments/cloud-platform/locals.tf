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

  # Phase-2 gate for Grafana-internal objects, per workspace. False on a fresh
  # AMG host workspace (phase 1 creates the service account); flipped to true
  # once the service account exists so the pipeline can mint a token. Declared
  # in the per-workspace environment_configurations map (not an .auto.tfvars
  # file, which would apply to every workspace). Defaults false for any
  # workspace that omits it. See grafana-objects.tf (local.manage_grafana_objects).
  grafana_objects_enabled = lookup(local.environment_configuration, "grafana_objects_enabled", false)
}
