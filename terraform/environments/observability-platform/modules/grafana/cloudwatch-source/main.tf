locals {
  name = "${var.name}-cloudwatch"
}

data "grafana_data_source" "this" {
  count = var.xray_enabled ? 1 : 0

  name = "${var.name}-xray"
}

resource "grafana_data_source" "this" {
  type = "cloudwatch"
  name = local.name

  json_data_encoded = jsonencode({
    defaultRegion           = "eu-west-2"
    authType                = "ec2_iam_role"
    assumeRoleArn           = "arn:aws:iam::${var.account_id}:role/observability-platform"
    externalId              = var.name
    customMetricsNamespaces = try(var.cloudwatch_custom_namespaces, "")
    tracingDatasourceUid    = try(data.grafana_data_source.this[0].uid, null)
  })
}
