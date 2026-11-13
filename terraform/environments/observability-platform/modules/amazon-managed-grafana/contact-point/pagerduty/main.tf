data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  secret_id = "grafana/notifications/pagerduty-integration-keys"
}

resource "grafana_contact_point" "this" {
  name = "${var.service}-pagerduty"

  pagerduty {
    integration_key = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)[var.service]
  }
}
