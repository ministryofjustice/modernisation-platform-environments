resource "kubernetes_config_map_v1" "google_application_credentials" {
  count = local.environment_configuration.monitoring_stack_enabled ? 1 : 0

  metadata {
    namespace = local.environment_configuration.grafana_namespace
    name      = "google-application-credentials"
  }

  data = {
    "credentials.json" = local.google_application_credentials
  }
}
