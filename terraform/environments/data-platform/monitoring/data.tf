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
