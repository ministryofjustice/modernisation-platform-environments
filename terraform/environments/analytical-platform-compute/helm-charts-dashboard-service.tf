resource "helm_release" "dashboard_service" {
  /* https://github.com/ministryofjustice/analytical-platform-dashboard-service */
  name       = "dashboard-service"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "0.1.0"
  chart      = "dashboard-service"
  namespace  = kubernetes_namespace.dashboard_service[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/dashboard-service/values.yml.tftpl",
      {
        dashboard_service_hostname = local.environment_configuration.dashboard_service_hostname,
        dashboard_service_app_env = local.environment
      }
    )
  ]
}
