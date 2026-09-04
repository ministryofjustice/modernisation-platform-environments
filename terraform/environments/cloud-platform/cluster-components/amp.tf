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
