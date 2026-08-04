#------------------------------------------------------------------------------
# Amazon CloudWatch Observability — EKS Add-on (Option D)
#
# Deploys the amazon-cloudwatch-observability add-on with OTel Container
# Insights enabled. This provides:
#   - Infrastructure metrics (node, pod, container) with original Prometheus names
#   - Container logs to CloudWatch Logs
#   - PromQL queryable metrics in CloudWatch
#
# The add-on deploys a DaemonSet in the 'amazon-cloudwatch' namespace. It uses
# EKS Pod Identity for IAM credentials.
#
# Key difference from Option A: no separate AMP workspace or ADOT collector.
# Metrics go directly to CloudWatch; AMG queries CloudWatch as a data source.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# IAM role for CloudWatch Observability agent
#------------------------------------------------------------------------------

resource "aws_iam_role" "cloudwatch_observability" {
  count = local.enable_cloudwatch_observability ? 1 : 0

  name = "${local.cluster_name}-cloudwatch-observability"

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
    option    = "D-cloudwatch-otel"
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_observability" {
  count = local.enable_cloudwatch_observability ? 1 : 0

  role       = aws_iam_role.cloudwatch_observability[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#------------------------------------------------------------------------------
# EKS Pod Identity Association — binds IAM role to cloudwatch-agent SA
#------------------------------------------------------------------------------

resource "aws_eks_pod_identity_association" "cloudwatch_observability" {
  count = local.enable_cloudwatch_observability ? 1 : 0

  cluster_name    = local.cluster_name
  namespace       = "amazon-cloudwatch"
  service_account = "cloudwatch-agent"
  role_arn        = aws_iam_role.cloudwatch_observability[0].arn

  tags = merge(local.tags, {
    component = "observability-poc"
    option    = "D-cloudwatch-otel"
  })
}

#------------------------------------------------------------------------------
# EKS Add-on — amazon-cloudwatch-observability with OTel Container Insights
#------------------------------------------------------------------------------

resource "aws_eks_addon" "cloudwatch_observability" {
  count = local.enable_cloudwatch_observability ? 1 : 0

  cluster_name                = local.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    otelContainerInsights = {
      enabled = true
    }
  })

  tags = merge(local.tags, {
    component = "observability-poc"
    option    = "D-cloudwatch-otel"
  })

  depends_on = [
    aws_eks_pod_identity_association.cloudwatch_observability
  ]
}
