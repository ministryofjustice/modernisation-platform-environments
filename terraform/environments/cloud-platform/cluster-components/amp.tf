#------------------------------------------------------------------------------
# Amazon Managed Prometheus (AMP) — Option A metrics backend
#
# Single AMP workspace per cluster for the PoC. In production, each BU account
# would have its own AMP workspace; AMG queries cross-account via IAM roles.
# For the PoC, everything is in the same account (cloud-platform-development).
#------------------------------------------------------------------------------

resource "aws_prometheus_workspace" "this" {
  count = local.enable_amp_adot ? 1 : 0

  alias = local.amp_workspace_alias

  logging_configuration {
    log_group_arn = "${aws_cloudwatch_log_group.amp[0].arn}:*"
  }

  tags = merge(local.tags, {
    component = "observability-poc"
    option    = "A-amp-adot"
  })
}

resource "aws_cloudwatch_log_group" "amp" {
  count = local.enable_amp_adot ? 1 : 0

  name              = "/aws/prometheus/${local.amp_workspace_alias}"
  retention_in_days = 30

  tags = merge(local.tags, {
    component = "observability-poc"
  })
}

#------------------------------------------------------------------------------
# IAM role for ADOT collector to remote-write to AMP
#------------------------------------------------------------------------------

resource "aws_iam_role" "adot_amp_remote_write" {
  count = local.enable_amp_adot ? 1 : 0

  name = "${local.cluster_name}-adot-amp-remote-write"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = merge(local.tags, {
    component = "observability-poc"
    option    = "A-amp-adot"
  })
}

resource "aws_iam_role_policy" "adot_amp_remote_write" {
  count = local.enable_amp_adot ? 1 : 0

  name = "amp-remote-write"
  role = aws_iam_role.adot_amp_remote_write[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = aws_prometheus_workspace.this[0].arn
      }
    ]
  })
}

#------------------------------------------------------------------------------
# EKS Pod Identity Association — binds the IAM role to the ADOT service account
#------------------------------------------------------------------------------

resource "aws_eks_pod_identity_association" "adot_amp" {
  count = local.enable_amp_adot ? 1 : 0

  cluster_name    = local.cluster_name
  namespace       = "opentelemetry-operator-system"
  service_account = "adot-collector"
  role_arn        = aws_iam_role.adot_amp_remote_write[0].arn

  tags = merge(local.tags, {
    component = "observability-poc"
  })
}

#------------------------------------------------------------------------------
# Cross-account query role — assumed by the central AMG workspace role in the
# hub account (cloud-platform-<tier>) to query this BU's AMP workspace. Scoped to
# this cluster's workspace only; created only on enabled BU clusters. The name
# must match local.bu_amp_query_role_name in the root component.
#------------------------------------------------------------------------------

resource "aws_iam_role" "amg_amp_query" {
  count = local.bu_amp_enabled ? 1 : 0

  name = "amg-amp-query"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.environment_management.account_ids["cloud-platform-${local.workspace_environment}"]}:role/cloud-platform-${local.workspace_environment}-amg"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.tags, {
    component = "observability"
  })
}

resource "aws_iam_role_policy" "amg_amp_query" {
  count = local.bu_amp_enabled ? 1 : 0

  name = "amp-query"
  role = aws_iam_role.amg_amp_query[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:QueryMetrics",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = aws_prometheus_workspace.this[0].arn
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Publish the workspace ID for the hub Grafana (root component), which cannot
# see this account's AMP workspaces. Stored in core-shared-services-production
# under the business-unit prefix permitted by the shared-configuration-access role.
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "amp_workspace_id" {
  count    = local.bu_amp_enabled ? 1 : 0
  provider = aws.shared-configuration-access

  name  = "/${local.vpc_name}/cloud-platform/amp/${local.amp_workspace_alias}/workspace-id"
  type  = "String"
  value = aws_prometheus_workspace.this[0].id
}

#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------

output "amp_workspace_endpoint" {
  description = "AMP remote-write and query endpoint"
  value       = local.enable_amp_adot ? aws_prometheus_workspace.this[0].prometheus_endpoint : null
}

output "amp_workspace_id" {
  description = "AMP workspace ID"
  value       = local.enable_amp_adot ? aws_prometheus_workspace.this[0].id : null
}
