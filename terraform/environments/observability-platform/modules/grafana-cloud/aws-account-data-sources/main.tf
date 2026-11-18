locals {
  # Grafana Assume Role: Grafana Cloud's AWS account assumes the role, with the stack ID as the
  # external ID. Grafana sets the external ID; it can't be configured.
  assume_role = {
    authType      = "grafana_assume_role"
    assumeRoleArn = var.role_arn
    defaultRegion = "eu-west-2"
    # Keep the stack-wide external ID that the role trusts. When Grafana's per-data-source external
    # ID feature is enabled, a new data source that doesn't set this gets its own external ID.
    usePerDatasourceExternalId = false
  }
}

resource "grafana_data_source" "xray" {
  count = var.xray.enabled ? 1 : 0

  type              = "grafana-x-ray-datasource"
  name              = "${var.name}-xray"
  json_data_encoded = jsonencode(local.assume_role)
}

resource "grafana_data_source" "cloudwatch" {
  count = var.cloudwatch.enabled ? 1 : 0

  type = "cloudwatch"
  name = "${var.name}-cloudwatch"
  json_data_encoded = jsonencode(merge(
    local.assume_role,
    { customMetricsNamespaces = join(",", var.cloudwatch.custom_namespaces) },
    # Links X-Ray trace IDs in CloudWatch Logs results to the account's X-Ray data source
    var.xray.enabled ? { tracingDatasourceUid = grafana_data_source.xray[0].uid } : {}
  ))
}

# Uses the Amazon Managed Service for Prometheus plugin: SigV4 in the core Prometheus data source
# is deprecated.
resource "grafana_data_source" "amazon_prometheus" {
  count = var.amazon_prometheus != null ? 1 : 0

  type = "grafana-amazonprometheus-datasource"
  name = "${var.name}-amp"
  url  = "https://aps-workspaces.${var.amazon_prometheus.region}.amazonaws.com/workspaces/${var.amazon_prometheus.workspace_id}"
  json_data_encoded = jsonencode({
    httpMethod         = "POST"
    sigV4Auth          = true
    sigV4AuthType      = "grafana_assume_role"
    sigV4AssumeRoleArn = var.role_arn
    sigV4Region        = var.amazon_prometheus.region
    sigv4Service       = "aps"
    # SigV4 equivalent of usePerDatasourceExternalId above
    sigV4UsePerDatasourceExternalId = false
  })
}

# Authoritative: replaces the default Viewer and Editor access, so only these teams can query the
# account's data sources. Admins, including the Terraform service account, keep access.
resource "grafana_data_source_permission" "this" {
  for_each = {
    for store, data_sources in {
      cloudwatch        = grafana_data_source.cloudwatch
      xray              = grafana_data_source.xray
      amazon_prometheus = grafana_data_source.amazon_prometheus
    } : store => data_sources[0].uid if length(data_sources) > 0
  }

  datasource_uid = each.value

  dynamic "permissions" {
    for_each = var.query_team_ids

    content {
      team_id    = permissions.value
      permission = "Query"
    }
  }
}
