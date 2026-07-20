# Shared Cloud Platform live cluster connection details (CA certificate and
# endpoint), created by the root data-platform configuration and read here by
# name to configure the kubernetes/helm providers.
data "aws_secretsmanager_secret_version" "cloud_platform_live" {
  count = local.environment_configuration.monitoring_stack_enabled ? 1 : 0

  secret_id = "cloud-platform/live"
}

# Namespace-scoped service account credentials used to deploy into the monitoring namespace.
data "aws_secretsmanager_secret_version" "cloud_platform_live_namespace" {
  count = local.environment_configuration.monitoring_stack_enabled ? 1 : 0

  secret_id = module.cloud_platform_live_namespace_secret[0].secret_id
}

# Microsoft Entra ID (Azure AD) OAuth credentials used by Grafana for single
# sign-on. The secret is created with placeholder values in secrets.tf and
# populated out-of-band, so it is read back here to inject the values into the
# Helm release.
data "aws_secretsmanager_secret_version" "grafana_entra_id" {
  count = local.environment_configuration.monitoring_stack_enabled ? 1 : 0

  secret_id = module.grafana_entra_id_secret[0].secret_id
}

# Grafana service-account token used by the Terraform grafana provider. The secret
# is created with a placeholder value in secrets.tf and populated out-of-band, so
# it is read back here to configure the provider in providers.tf.
data "aws_secretsmanager_secret_version" "grafana_api_token" {
  count = local.environment_configuration.monitoring_stack_enabled ? 1 : 0

  secret_id = module.grafana_api_token_secret[0].secret_id
}

# PagerDuty integration key (routing key) for the Event Orchestrator. The secret
# is managed in the data-platform-pagerduty repository.
data "aws_secretsmanager_secret_version" "pagerduty_integration_key" {
  count = local.environment_configuration.monitoring_stack_enabled ? 1 : 0

  secret_id = "pagerduty/global/integration-keys/grafana"
}
