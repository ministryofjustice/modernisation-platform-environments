module "grafana_entra_id_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  count = local.environment_configuration.monitoring_stack_enabled ? 1 : 0

  name = "${local.component_name}/grafana-entra-id"

  secret_string = jsonencode({
    client_id     = "CHANGEME"
    client_secret = "CHANGEME"
    tenant_id     = "CHANGEME"
  })
  ignore_secret_changes = true
}

# Namespace-scoped service account credentials used to deploy into the monitoring
# namespace(s). The cluster CA certificate and endpoint are read from the shared
# cloud-platform/live secret (see data.tf).
module "cloud_platform_live_namespace_secret" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=d03382d3ec9c12b849fbbe35b770eaa047f7bbea" # v2.1.0

  count = local.environment_configuration.monitoring_stack_enabled ? 1 : 0

  name = "cloud-platform/live/${local.component_name}"

  secret_string = jsonencode({
    namespace = "CHANGEME"
    token     = "CHANGEME"
  })
  ignore_secret_changes = true
}