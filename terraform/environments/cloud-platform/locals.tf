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
  # OpenSearch — single shared log-search cluster (one domain per environment).
  # Scoped to development for now. Design + rationale: ADR-017-opensearch-deployment-model.
  #-----------------------------------------------------------------------------
  opensearch_host_workspaces = [
    "cloud-platform-development",
  ]
  enable_opensearch = contains(local.opensearch_host_workspaces, terraform.workspace)
  opensearch_engine = "OpenSearch_3.7" # pinned; don't rely on the default

  # "cp-" prefix keeps the name under the 28-char domain limit.
  opensearch_domain_name = "${replace(replace(terraform.workspace, "container-platform-", "cp-"), "cloud-platform-", "cp-")}-logs"
  opensearch_is_live     = local.is_live[0] == "live"
  opensearch_instance    = local.opensearch_is_live ? "or1.large.search" : "or1.medium.search"
  opensearch_data_nodes  = local.opensearch_is_live ? 2 : 1

  # Hot (gp3) disk; right-size per environment, don't provision for peak.
  opensearch_ebs_gb = lookup(local.environment_configuration, "opensearch_ebs_gb", local.opensearch_is_live ? 100 : 20)

  opensearch_audit_log_group = "/aws/vendedlogs/opensearch/${local.opensearch_domain_name}/audit"

  # CloudWatch audit-group retention (not OpenSearch's own data retention — that's per-index ISM).
  opensearch_audit_retention_days = lookup(local.environment_configuration, "opensearch_audit_retention_days", 30)
}
