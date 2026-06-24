locals {
  # Microsoft Entra ID (Azure AD) OAuth credentials for Grafana. The secret is
  # provisioned with placeholder values in secrets.tf and populated out-of-band,
  # then read back via the data source in data.tf. try() keeps this resolvable in
  # environments where the monitoring stack is disabled and the data source
  # therefore has no instances.
  grafana_entra_id = try(jsondecode(data.aws_secretsmanager_secret_version.grafana_entra_id[0].secret_string), {})
}
