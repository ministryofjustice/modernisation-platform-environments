#------------------------------------------------------------------------------
# Amazon Managed Grafana (AMG) — centralised dashboard and alerting layer
#
# A single AMG workspace serves the whole platform (ADR-005, updated
# 2026-09-07): it is deployed in the cloud-platform-live account in production
# (and in cloud-platform-development for testing), and queries per-cluster
# metrics backends (AMP workspaces and CloudWatch) as data sources. Metric data
# stays in the source accounts; AMG is a query and visualisation layer only.
#
# BU app engineers receive read-only (Viewer) access scoped to their BU's
# folder. Logical separation of metrics between BUs is provided by folder
# permissions and curated data sources, per the security team's requirement
# for default-deny visibility across BUs.
#
# Authentication: IAM Identity Center (SSO) — aligned with ADR-004.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# AMG workspace IAM role — allows AMG to reach its data sources
#------------------------------------------------------------------------------

resource "aws_iam_role" "amg" {
  count = local.enable_amg ? 1 : 0

  name = "${terraform.workspace}-amg"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = merge(local.tags, {
    component = "observability"
  })
}

#------------------------------------------------------------------------------
# AMG data source permissions — AMP read + CloudWatch read
#
# Both are granted unconditionally: the central AMG must be able to query
# whichever metrics backend a cluster runs (AMP for Option A, CloudWatch for
# Option D), and both remain in play until the ADR-005 decision gate.
#------------------------------------------------------------------------------

resource "aws_iam_role_policy" "amg_amp_read" {
  # checkov:skip=CKV_AWS_355:AMG must query multiple AMP workspaces across BU accounts, and aps:ListWorkspaces is not resource-scopable. Per-BU resource scoping via dedicated data-source assume-roles is tracked in cloud-platform#8509 (BU metric isolation).
  count = local.enable_amg ? 1 : 0

  name = "amp-query"
  role = aws_iam_role.amg[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:QueryMetrics",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata",
          "aps:ListWorkspaces",
          "aps:DescribeWorkspace"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "amg_cloudwatch_read" {
  # checkov:skip=CKV_AWS_355:AMG must query CloudWatch metrics/logs across BU accounts, and List/Describe actions here are not resource-scopable. Per-BU resource scoping via dedicated data-source assume-roles is tracked in cloud-platform#8509 (BU metric isolation).
  count = local.enable_amg ? 1 : 0

  name = "cloudwatch-query"
  role = aws_iam_role.amg[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetInsightRuleReport",
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })
}

#------------------------------------------------------------------------------
# AMG workspace
#------------------------------------------------------------------------------

resource "aws_grafana_workspace" "this" {
  count = local.enable_amg ? 1 : 0

  name                     = local.amg_workspace_name
  description              = "Centralised observability dashboards and alerting (${terraform.workspace})"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.amg[0].arn
  grafana_version          = "12.4"

  # Grafana-managed (unified) alerting must be enabled before AMG will accept an
  # upgrade to Grafana v12 (otherwise UpdateWorkspaceConfiguration returns
  # "Grafana alerting must be enabled before upgrading to v12").
  configuration = jsonencode({
    unifiedAlerting = {
      enabled = true
    }
  })

  data_sources = [
    "PROMETHEUS",
    "CLOUDWATCH",
  ]

  notification_destinations = ["SNS"]

  tags = merge(local.tags, {
    component = "observability"
  })
}

#------------------------------------------------------------------------------
# AMG workspace role association — platform engineers get ADMIN
#------------------------------------------------------------------------------

# IDC group IDs are hardcoded because the ModernisationPlatformSSOReadOnly role
# returns ResourceNotFoundException when calling GetGroupId despite having
# identitystore:Get*. This mirrors the same workaround (and the same two groups)
# used for ArgoCD RBAC in cluster/locals.tf.
# TODO: switch back to a data.aws_identitystore_group lookup once the read role
# permissions are fixed.
locals {
  cloud_platform_engineers_group_id = "664252b4-7021-701e-49b9-6c46ccc7899e"
  # AWS ProServe team building the platform; needs AMG access to inspect dashboards.
  container_platform_aws_group_id = "7682a204-00f1-7031-257e-713bb28289c6"
}

resource "aws_grafana_role_association" "platform_admin" {
  count = local.enable_amg ? 1 : 0

  role = "ADMIN"
  group_ids = [
    local.cloud_platform_engineers_group_id,
    local.container_platform_aws_group_id,
  ]
  workspace_id = aws_grafana_workspace.this[0].id
}

#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------

output "amg_workspace_endpoint" {
  description = "AMG workspace URL for browser access"
  value       = local.enable_amg ? aws_grafana_workspace.this[0].endpoint : null
}

output "amg_workspace_id" {
  description = "AMG workspace ID"
  value       = local.enable_amg ? aws_grafana_workspace.this[0].id : null
}
