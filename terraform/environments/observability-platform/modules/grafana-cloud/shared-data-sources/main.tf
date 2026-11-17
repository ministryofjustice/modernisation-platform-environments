locals {
  # Static UIDs, equal to the names, so the data sources can link to each other without a dependency
  # cycle
  uids = {
    metrics = "shared-metrics"
    logs    = "shared-logs"
    traces  = "shared-traces"
  }

  basic_auth_password = jsonencode({
    basicAuthPassword = var.read_token
  })

  # Selector matching one account's data in each store. Mimir and Loki match the `cloud_account_id`
  # label, which Grafana Cloud must be configured to promote from the OTLP `cloud.account.id` resource
  # attribute: until it is, these rules match no metrics or logs. Tempo rules can only match resource
  # attributes, so they match `cloud.account.id` itself.
  account_selectors = {
    metrics = "{ cloud_account_id=\"%s\" }"
    logs    = "{ cloud_account_id=\"%s\" }"
    traces  = "{ resource.cloud.account.id=\"%s\" }"
  }

  # Signal => team UID => rules. A team with no accounts pushing the signal gets a rule that matches
  # no data, rather than no rules: users whose teams have no rules on a data source can see all of
  # its data if they're granted Query.
  rules = {
    for signal, selector in local.account_selectors : signal => {
      for team in values(var.teams) : team.uid => (
        length(team.accounts[signal]) > 0
        ? [for account in team.accounts[signal] : format(selector, var.account_ids[account])]
        : [format(selector, "none")]
      )
    }
  }

  data_source_uids = {
    metrics = grafana_data_source.metrics.uid
    logs    = grafana_data_source.logs.uid
    traces  = grafana_data_source.traces.uid
  }
}

resource "grafana_data_source" "metrics" {
  type = "prometheus"
  name = local.uids.metrics
  uid  = local.uids.metrics
  url  = var.metrics.url

  basic_auth_enabled  = true
  basic_auth_username = var.metrics.username

  json_data_encoded = jsonencode({
    httpMethod     = "POST"
    prometheusType = "Mimir"
    # OpenTelemetry SDKs export metrics every 60 seconds by default
    timeInterval = "60s"
    # Links exemplars to their traces
    exemplarTraceIdDestinations = [{
      name          = "trace_id"
      datasourceUid = local.uids.traces
    }]
  })
  secure_json_data_encoded = local.basic_auth_password
}

resource "grafana_data_source" "logs" {
  type = "loki"
  name = local.uids.logs
  uid  = local.uids.logs
  url  = var.logs.url

  basic_auth_enabled  = true
  basic_auth_username = var.logs.username

  json_data_encoded = jsonencode({
    # Links log records to their traces. OTLP log records keep the trace ID in the `trace_id`
    # structured metadata.
    derivedFields = [{
      name            = "TraceID"
      matcherType     = "label"
      matcherRegex    = "trace_id"
      url             = "$${__value.raw}"
      urlDisplayLabel = "View trace"
      datasourceUid   = local.uids.traces
    }]
  })
  secure_json_data_encoded = local.basic_auth_password
}

resource "grafana_data_source" "traces" {
  type = "tempo"
  name = local.uids.traces
  uid  = local.uids.traces
  url  = var.traces.url

  basic_auth_enabled  = true
  basic_auth_username = var.traces.username

  json_data_encoded = jsonencode({
    # Links spans to the service's logs for the trace. OTLP resource attribute `service.name` is the
    # `service_name` label in Loki.
    tracesToLogsV2 = {
      datasourceUid      = local.uids.logs
      spanStartTimeShift = "-5m"
      spanEndTimeShift   = "5m"
      tags               = [{ key = "service.name", value = "service_name" }]
      customQuery        = true
      query              = "{$${__tags}} | trace_id=\"$${__trace.traceId}\""
    }
    tracesToMetrics = {
      datasourceUid = local.uids.metrics
      tags          = [{ key = "service.name", value = "service_name" }]
    }
    serviceMap = {
      datasourceUid = local.uids.metrics
    }
    nodeGraph = {
      enabled = true
    }
  })
  secure_json_data_encoded = local.basic_auth_password
}

# Label-based access control: each team only sees data from the accounts it can query. Authoritative
# over each data source's rules.
resource "grafana_data_source_config_lbac_rules" "this" {
  for_each = local.data_source_uids

  datasource_uid = each.value
  rules          = jsonencode(local.rules[each.key])
}

# Authoritative: replaces the default Viewer and Editor access, so only the teams with accounts
# pushing the signal can query the data source. Admins, including the Terraform service account,
# keep access.
resource "grafana_data_source_permission" "this" {
  for_each = local.data_source_uids

  datasource_uid = each.value

  dynamic "permissions" {
    for_each = {
      for tenant_name, team in var.teams : tenant_name => team.id if length(team.accounts[each.key]) > 0
    }

    content {
      team_id    = permissions.value
      permission = "Query"
    }
  }

  # Grant Query once the team's rules are in place. Removing a team's access first changes its rules
  # to match no data, then removes its Query permission.
  depends_on = [grafana_data_source_config_lbac_rules.this]
}

# The stack's built-in data sources query the same stores without these rules, so only admins can
# query them: authoritative, with no grants. Removing this resource doesn't restore other users' access.
data "grafana_data_source" "built_in" {
  for_each = {
    metrics = "prom"
    logs    = "logs"
    traces  = "traces"
  }

  name = "grafanacloud-${var.stack_slug}-${each.value}"
}

resource "grafana_data_source_permission" "built_in" {
  for_each = data.grafana_data_source.built_in

  datasource_uid = each.value.uid
}
