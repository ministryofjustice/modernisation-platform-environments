locals {
  name = "${var.name}-amp"
  url  = "https://aps-workspaces.${var.amazon_prometheus_workspace_region}.amazonaws.com/workspaces/${var.amazon_prometheus_workspace_id}/"
}

resource "grafana_data_source" "this" {
  type = "prometheus"
  name = local.name
  url  = local.url

  json_data_encoded = jsonencode({
    httpMethod         = "POST"
    sigV4Auth          = true
    sigV4AuthType      = "ec2_iam_role"
    sigV4AssumeRoleArn = "arn:aws:iam::${var.account_id}:role/observability-platform"
    sigV4Region        = var.amazon_prometheus_workspace_region
    sigV4ExternalId    = var.name
  })
}
