#------------------------------------------------------------------------------
# Amazon Managed Grafana (AMG) — Shared dashboard and alerting layer
#
# A single AMG workspace serves both PoC options. It has two data sources:
#   1. AMP (Prometheus) — for Option A queries via PromQL
#   2. CloudWatch — for Option D queries via CloudWatch Metrics Insights
#
# For the PoC, everything is in the same account (cloud-platform-development).
# In production, AMG would live in a dedicated Observability account and query
# AMP/CloudWatch cross-account via IAM role assumption.
#
# Authentication: IAM Identity Center (SSO) — aligned with ADR-004.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# AMG workspace IAM role — allows AMG to assume data source roles
#------------------------------------------------------------------------------

resource "aws_iam_role" "amg" {
  count = local.enable_amg ? 1 : 0

  name = "${local.cluster_name}-amg"

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
    component = "observability-poc"
  })
}

#------------------------------------------------------------------------------
# AMG data source permissions — AMP read + CloudWatch read
#------------------------------------------------------------------------------

resource "aws_iam_role_policy" "amg_amp_read" {
  count = local.enable_amg && local.enable_amp_adot ? 1 : 0

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
  count = local.enable_amg && local.enable_cloudwatch_observability ? 1 : 0

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

  name                     = "${local.cluster_name}-observability"
  description              = "Observability PoC — metrics dashboards and alerting for ${local.cluster_name}"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.amg[0].arn
  grafana_version          = "10.4"

  data_sources = compact([
    local.enable_amp_adot ? "PROMETHEUS" : "",
    local.enable_cloudwatch_observability ? "CLOUDWATCH" : "",
  ])

  notification_destinations = ["SNS"]

  tags = merge(local.tags, {
    component = "observability-poc"
  })
}

#------------------------------------------------------------------------------
# AMG workspace role association — platform engineers get ADMIN
#------------------------------------------------------------------------------

# Look up the platform-engineer-admin SSO group in Identity Store
data "aws_identitystore_group" "platform_engineers" {
  count = local.enable_amg ? 1 : 0

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "platform-engineer-admin"
    }
  }
}

resource "aws_grafana_role_association" "platform_admin" {
  count = local.enable_amg ? 1 : 0

  role         = "ADMIN"
  group_ids    = [data.aws_identitystore_group.platform_engineers[0].group_id]
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

output "amp_workspace_endpoint" {
  description = "AMP remote-write and query endpoint"
  value       = local.enable_amp_adot ? aws_prometheus_workspace.this[0].prometheus_endpoint : null
}

output "amp_workspace_id" {
  description = "AMP workspace ID"
  value       = local.enable_amp_adot ? aws_prometheus_workspace.this[0].id : null
}
