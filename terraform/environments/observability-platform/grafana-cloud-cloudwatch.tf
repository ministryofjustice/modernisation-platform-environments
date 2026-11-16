# IAM role that Grafana Cloud assumes to read CloudWatch in this account ("Grafana Assume Role").
# Grafana's AWS account assumes the role from Grafana Cloud. The external ID is this environment's
# stack ID, so only this stack can use the role.

data "aws_iam_policy_document" "grafana_cloud_cloudwatch_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.grafana_cloud_aws_account_id}:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [grafana_cloud_stack.observability_platform.id]
    }
  }
}

locals {
  # Grafana Cloud's AWS account for Grafana Assume Role, shown on the CloudWatch data source settings page
  grafana_cloud_aws_account_id = "008923505280"
}

resource "aws_iam_role" "grafana_cloud_cloudwatch" {
  name               = "grafana-cloud-cloudwatch"
  assume_role_policy = data.aws_iam_policy_document.grafana_cloud_cloudwatch_assume.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "grafana_cloud_cloudwatch" {
  role       = aws_iam_role.grafana_cloud_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

output "grafana_cloud_cloudwatch_role_arn" {
  description = "Assume Role ARN for Grafana Cloud CloudWatch data sources"
  value       = aws_iam_role.grafana_cloud_cloudwatch.arn
}
