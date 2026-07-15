# ------------------------------------------------------------------------------
# ALERT FOLDERS
# Creates the logical directory structure within Grafana to organize alerting rules.
# ------------------------------------------------------------------------------
resource "grafana_folder" "alert_rules" {
  for_each = (local.grafana_alerting_manageable && length(local.grafana_monitored_accounts_by_uid) > 0) ? local.alert_rule_folder_paths : toset([])

  uid   = "alert-rules-${replace(each.key, "/", "-")}"
  title = each.key

  depends_on = [helm_release.grafana]
}

# ------------------------------------------------------------------------------
#ALERT RULE GROUPS & RULES
# Manages the evaluation groups, query structures, and thresholds for alerts.
# ------------------------------------------------------------------------------
resource "grafana_rule_group" "this" {
  for_each = {
    for name, group in local.rule_groups_flat :
    name => group
    if local.grafana_alerting_manageable
  }

  name = each.value.name

  folder_uid = grafana_folder.alert_rules[each.value.folder].uid

  interval_seconds = local.interval_seconds_by_env[each.value.env]

  dynamic "rule" {
    for_each = each.value.rules
    content {
      name          = rule.value.title
      uid           = rule.value.uid
      condition     = rule.value.condition
      for           = rule.value.for
      no_data_state = rule.value.noDataState
      labels        = rule.value.labels

      dynamic "data" {
        for_each = rule.value.data
        content {
          ref_id         = data.value.refId
          datasource_uid = data.value.datasourceUid

          model = sensitive(jsonencode(data.value.model))

          relative_time_range {
            from = data.value.relativeTimeRange.from
            to   = data.value.relativeTimeRange.to
          }
        }
      }
    }
  }

  depends_on = [helm_release.grafana]
}

# ------------------------------------------------------------------------------
# PAGERDUTY CONTACT POINT
# Sends alert notifications to PagerDuty via the Events API v2. The routing key
# is the Global Event Orchestration routing key, stored in Secrets Manager
# (secrets.tf / data.tf) and injected at apply time. The severity label on each
# alert rule is forwarded as a payload field for orchestration rules to act on.
# ------------------------------------------------------------------------------
resource "grafana_contact_point" "pagerduty" {
  count = local.grafana_alerting_manageable ? 1 : 0

  name = "pagerduty"

  pagerduty {
    integration_key = local.pagerduty_routing_key
    severity        = "{{ index .CommonLabels \"severity\" }}"
    component       = "{{ index .CommonLabels \"namespace\" }}"
    details = {
      environment = "{{ index .CommonLabels \"environment\" }}"
    }
  }

  depends_on = [helm_release.grafana]
}

# ------------------------------------------------------------------------------
# NOTIFICATION POLICY
# Routes all firing alerts to the PagerDuty contact point. Group by folder,
# alert name, and severity so each distinct signal creates a separate PagerDuty
# incident rather than being bundled into one.
# ------------------------------------------------------------------------------
resource "grafana_notification_policy" "this" {
  count = local.grafana_alerting_manageable ? 1 : 0

  contact_point = grafana_contact_point.pagerduty[0].name
  group_by      = ["grafana_folder", "alertname", "severity"]

  group_wait      = "30s"
  group_interval  = "5m"
  repeat_interval = "4h"

  depends_on = [grafana_contact_point.pagerduty]
}