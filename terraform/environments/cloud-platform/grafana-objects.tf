#------------------------------------------------------------------------------
# BU metric isolation (cloud-platform#8509)
#
# For each BU: a Grafana Team (membership synced from its IAM Identity Center
# group), a Prometheus data source pointing at that BU's AMP workspace, a
# data-source permission granting ONLY that team Query access, and a per-BU
# folder the team can view.
#
# Default-deny: grafana_data_source_permission manages the ENTIRE permission set
# for a data source. Granting Query to only the BU's team — and deliberately NOT
# granting the built-in Viewer/Editor basic roles — removes default query access
# for everyone else, including other BUs' users, in dashboards and in Explore.
# Folder permissions alone would not achieve this; they gate dashboard
# visibility, not querying.
#
# All resources are gated by local.enable_amg, so workspaces that do not host
# AMG create nothing here.
#------------------------------------------------------------------------------

locals {
  # Per-workspace BU definitions, following the same per-workspace map idiom as
  # local.environment_configurations. Each entry maps a BU to its AMP workspace
  # alias and the identity groups whose members form its Grafana team.
  #
  # idc_group_ids is a LIST because a BU has many delivery teams: every group
  # granted access to any namespace in the BU should get Grafana access to that
  # BU's metrics. In future this list is expected to be derived from the
  # access[].group entries across that BU's product.yaml files in
  # container-platform-environments (deduplicated per BU). Isolation granularity
  # is the BU, which matches the requirement.
  #
  # cloud-platform-development currently holds the #8509 isolation PoC: two
  # simulated BUs backed by two ephemeral clusters' AMP workspaces. Production
  # (cloud-platform-live) is populated once per-BU-account AMP exists (#8517).
  bus_by_workspace = {
    cloud-platform-development = {
      bu1 = {
        amp_workspace_alias = "cp-1609-0059-bu1-metrics"
        # hmpps-probation-in-court (simulated BU A)
        idc_group_ids = ["f692f244-e051-7096-ea04-14f8291f76f7"]
      }
      bu2 = {
        amp_workspace_alias = "cp-1609-0059-bu2-metrics"
        # laa-access-data-stewardship (simulated BU B)
        idc_group_ids = ["66122264-80d1-70f8-e357-e5abb0fe8a21"]
      }
    }
  }

  # Only create Grafana objects where AMG exists and BUs are defined.
  grafana_bus = local.enable_amg ? lookup(local.bus_by_workspace, terraform.workspace, {}) : {}
}

#------------------------------------------------------------------------------
# Per-BU AMP workspace lookup (by alias) to obtain the query endpoint
#------------------------------------------------------------------------------

data "aws_prometheus_workspaces" "bu" {
  for_each = local.grafana_bus

  alias_prefix = each.value.amp_workspace_alias
}

data "aws_prometheus_workspace" "bu" {
  for_each = local.grafana_bus

  workspace_id = one(data.aws_prometheus_workspaces.bu[each.key].workspace_ids)
}

#------------------------------------------------------------------------------
# Teams — one Grafana team per BU, membership synced from that BU's identity
# groups (many groups per BU: every delivery team with access to the BU)
#------------------------------------------------------------------------------

resource "grafana_team" "bu" {
  for_each = local.grafana_bus

  name = "bu-${each.key}"
}

resource "grafana_team_external_group" "bu" {
  for_each = local.grafana_bus

  team_id = grafana_team.bu[each.key].id
  # Many identity groups map into one BU team — every team with access to the BU
  # gets that BU's metrics. distinct() because the same group can appear more
  # than once when derived from product.yaml (one entry per role/cluster).
  groups = distinct(each.value.idc_group_ids)
}

#------------------------------------------------------------------------------
# Per-BU AMP data source
#
# AMG v12+ uses the dedicated Amazon Managed Service for Prometheus plugin;
# SigV4 is built in and signed with the AMG workspace's own IAM role, so no
# credentials are configured here.
#------------------------------------------------------------------------------

resource "grafana_data_source" "bu_amp" {
  for_each = local.grafana_bus

  type = "grafana-amazonprometheus-datasource"
  name = "amp-${each.key}"
  url  = data.aws_prometheus_workspace.bu[each.key].prometheus_endpoint

  json_data_encoded = jsonencode({
    httpMethod    = "POST"
    sigV4Auth     = true
    sigV4AuthType = "ec2_iam_role"
    sigV4Region   = data.aws_region.current.region
  })
}

#------------------------------------------------------------------------------
# Data-source permissions — the isolation control
#------------------------------------------------------------------------------

resource "grafana_data_source_permission" "bu_amp" {
  for_each = local.grafana_bus

  datasource_uid = grafana_data_source.bu_amp[each.key].uid

  # Only this BU's team may query. No built-in role is granted, so Viewer and
  # Editor (i.e. every other BU's users) are denied by default.
  permissions {
    team_id    = grafana_team.bu[each.key].id
    permission = "Query"
  }
}

#------------------------------------------------------------------------------
# Per-BU folders — dashboard visibility scoped to the team
#------------------------------------------------------------------------------

resource "grafana_folder" "bu" {
  for_each = local.grafana_bus

  title = "BU ${each.key}"
}

resource "grafana_folder_permission" "bu" {
  for_each = local.grafana_bus

  folder_uid = grafana_folder.bu[each.key].uid

  permissions {
    team_id    = grafana_team.bu[each.key].id
    permission = "View"
  }
}
