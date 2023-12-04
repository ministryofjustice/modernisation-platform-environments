locals {
  name = "${var.name}-cloudwatch"
}

resource "grafana_data_source" "this" {
  type = "cloudwatch"
  name = local.name

  json_data_encoded = jsonencode({
    defaultRegion = "eu-west-2"
    authType      = "ec2_iam_role"
    assumeRoleArn = "arn:aws:iam::${var.account_id}:role/observability-platform"
    externalId    = var.name
  })
}
