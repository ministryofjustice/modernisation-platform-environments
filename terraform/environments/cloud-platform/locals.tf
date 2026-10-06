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
  enable_opensearch = contains(local.opensearch_host_workspaces, terraform.workspace)
  opensearch_engine = "OpenSearch_3.7" # pinned (ADR-017 D5); do not rely on defaults

  # Domain name has a hard AWS limit of 28 chars. "${terraform.workspace}-logs"
  # overflows: cloud-platform-development-logs is 30, and container-platform BU
  # workspaces are longer still. Shorten the long platform prefixes to "cp-" so
  # every workspace stays unique and well under 28 (e.g. cp-development-logs,
  # cp-hmpps-nonlive-logs).
  opensearch_domain_name = "${replace(replace(terraform.workspace, "container-platform-", "cp-"), "cloud-platform-", "cp-")}-logs"
  opensearch_is_live     = local.is_live[0] == "live"
  opensearch_instance    = local.opensearch_is_live ? "or1.large.search" : "or1.medium.search"
  opensearch_data_nodes  = local.opensearch_is_live ? 2 : 1

  # Hot (gp3) disk per domain. Set PER BU, not one shared number — the cost
  # breakdown (ADR-017) found the central cluster had 216 TB provisioned but only
  # ~22% used, so a single global size over-provisions. Each BU can set
  # opensearch_ebs_gb in its environment_configurations entry; the default is a
  # small live/non-live starter. Size to measured use plus headroom, NOT to peak.
  opensearch_ebs_gb = lookup(local.environment_configuration, "opensearch_ebs_gb", local.opensearch_is_live ? 100 : 20)

  # Private access (architecture review): the domain is reached over the private
  # network like the EKS clusters (VPN -> transit gateway -> VPC endpoints), not
  # over a public endpoint. The VPC and its subnets live in the `network`
  # component, a separate state, so we look them up by tag rather than reference
  # the module (same approach as the SSM relay). One subnet while zone awareness
  # is off; add subnets here when multi-AZ is turned on.
  opensearch_vpc_name = terraform.workspace

  # Audit logging (architecture review): on by default, published to a CloudWatch
  # log group under /aws/vendedlogs/ so one broad resource policy covers every
  # per-BU domain without hitting the 10-policies-per-Region cap. Verbosity
  # tuning to control ingest cost is a separate follow-on ticket.
  opensearch_audit_log_group = "/aws/vendedlogs/opensearch/${local.opensearch_domain_name}/audit"

  # Log retention is set PER BU, not one global value (architecture review).
  # Taken from the per-workspace environment_configurations map so each BU can
  # pick its own duration; falls back to 30 days where unset. Values will firm up
  # once regulatory retention guidance lands.
  opensearch_audit_retention_days = lookup(local.environment_configuration, "opensearch_audit_retention_days", 30)
}
