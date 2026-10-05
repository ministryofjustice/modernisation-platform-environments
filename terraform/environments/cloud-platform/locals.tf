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

  #-----------------------------------------------------------------------------
  # OpenSearch — full-text log search (ADR-017, Option B: one domain per BU, each
  # in its own account; see ADR-017-opensearch-deployment-model).
  #
  # Deployed per workspace: each cloud-platform-<env> apply runs in that BU's
  # account (MemberInfrastructureAccess), so one domain lands per BU-environment.
  # Live environments get a larger domain than non-live (local.is_live).
  #
  # Scoped to the development workspace for now — the first build proves the
  # config in the development account before the per-BU rollout. Add workspaces
  # here to extend it.
  #-----------------------------------------------------------------------------
  opensearch_host_workspaces = [
    "cloud-platform-development",
  ]
  enable_opensearch      = contains(local.opensearch_host_workspaces, terraform.workspace)
  opensearch_engine      = "OpenSearch_3.7" # pinned (ADR-017 D5); do not rely on defaults
  opensearch_domain_name = "${terraform.workspace}-logs"
  opensearch_is_live     = local.is_live[0] == "live"
  opensearch_instance    = local.opensearch_is_live ? "or1.large.search" : "or1.medium.search"
  opensearch_data_nodes  = local.opensearch_is_live ? 2 : 1
  opensearch_ebs_gb      = local.opensearch_is_live ? 100 : 20
}
