locals {
  name       = "${var.name}-cloudwatch"
  account_id = var.environment_management.account_ids[var.name]
}

resource "grafana_data_source" "this" {
  type = "cloudwatch"
  name = local.name

  json_data_encoded = jsonencode({
    defaultRegion   = "eu-west-2"
    authType        = "ec2_iam_role"
    assume_role_arn = "arn:aws:iam::${local.account_id}:role/observability-platform"
  })
}
