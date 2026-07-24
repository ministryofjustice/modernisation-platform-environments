# ------------------------------------------------------------------------------
# PAGERDUTY CONTACT POINT
# Creates a Grafana contact point that sends alerts to PagerDuty Event
# Orchestrator. The routing key is read from Secrets Manager.
# ------------------------------------------------------------------------------
resource "grafana_contact_point" "pagerduty" {
  count = local.grafana_alerting_manageable && local.pagerduty_routing_key != "" ? 1 : 0

  name = "pagerduty"

  pagerduty {
    integration_key = local.pagerduty_routing_key
    severity        = "{{ .CommonLabels.severity }}"
    component       = "{{ .CommonLabels.component }}"
    group           = "{{ .CommonLabels.environment }}"

    # Include all labels as custom details in the PagerDuty payload
    details = {
      environment = "{{ .CommonLabels.environment }}"
      severity    = "{{ .CommonLabels.severity }}"
      component   = "{{ .CommonLabels.component }}"
      metric      = "{{ .CommonLabels.metric }}"
      alertname   = "{{ .CommonLabels.alertname }}"
      summary     = "{{ .CommonAnnotations.summary }}"
      description = "{{ .CommonAnnotations.description }}"
    }
  }

  depends_on = [helm_release.grafana]
}

# ------------------------------------------------------------------------------
# NOTIFICATION POLICY
# Routes alerts to the PagerDuty contact point. Each alert fires individually
# without grouping.
# ------------------------------------------------------------------------------
resource "grafana_notification_policy" "pagerduty" {
  count = local.grafana_alerting_manageable && local.pagerduty_routing_key != "" ? 1 : 0

  contact_point   = grafana_contact_point.pagerduty[0].name
  group_by        = ["..."]
  group_wait      = "0s"
  group_interval  = "1m"
  repeat_interval = "4h"

  depends_on = [helm_release.grafana]
}
