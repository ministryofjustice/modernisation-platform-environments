locals {
  name = "${var.name}-athena"
}

data "grafana_data_source" "this" {
  count = var.athena_enabled ? 1 : 0

  name = "${var.name}-athena"
}

resource "grafana_data_source" "this" {
  type = "athena"
  name = local.name

  json_data_encoded = jsonencode({
    defaultRegion           = "eu-west-2"
    authType                = "ec2_iam_role"
    assumeRoleArn           = "arn:aws:iam::${var.account_id}:role/observability-platform"
    externalId              = var.name
    database                = var.athena_database
    workgroup               = var.athena_workgroup
  })
}
