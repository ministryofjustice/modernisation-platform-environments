locals {
  name = "${var.name}-athena"
}

data "grafana_data_source" "this" {
  count = var.athena_enabled ? 1 : 0
  name  = "${var.name}-athena"
}

resource "grafana_data_source" "this" {
  for_each = var.athena_config

  type = "athena"
  name = "${local.name}-${each.key}"
  json_data_encoded = jsonencode({
    defaultRegion = "eu-west-2"
    authType      = "ec2_iam_role"
    assumeRoleArn = "arn:aws:iam::${var.account_id}:role/observability-platform"
    externalId    = var.name
    database      = each.value.database
    workgroup     = each.value.workgroup
  })
}
