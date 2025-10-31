resource "helm_release" "dashboard_service" {
  count = terraform.workspace == "analytical-platform-compute-test" ? 0 : 1

  /* https://github.com/ministryofjustice/analytical-platform-dashboard-service */
  name       = "dashboard-service"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "0.2.13"
  chart      = "dashboard-service"
  namespace  = kubernetes_namespace.dashboard_service[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/dashboard-service/values.yml.tftpl",
      {
        dashboard_service_app_env                = local.environment,
        dashboard_service_auth0_domain           = local.environment_configuration.dashboard_service_auth0_domain,
        dashboard_service_django_settings_module = "dashboard_service.settings.${local.environment}"
        dashboard_service_hostname               = local.environment_configuration.dashboard_service_hostname,
      }
    )
  ]
}
