locals {
  name = "${var.name}-xray"
}

resource "grafana_data_source" "this" {
  type = "grafana-x-ray-datasource"
  name = local.name

  json_data_encoded = jsonencode({
    defaultRegion = "eu-west-2"
    authType      = "ec2_iam_role"
    assumeRoleArn = "arn:aws:iam::${var.account_id}:role/observability-platform"
    externalId    = var.name
  })
}
