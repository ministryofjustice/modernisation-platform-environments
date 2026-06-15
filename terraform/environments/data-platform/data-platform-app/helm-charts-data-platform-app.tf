resource "helm_release" "data_platform_app" {
  count = terraform.workspace == "data-platform-test" ? 0 : 1

  /* https://github.com/ministryofjustice/data-platform-app */
  name       = "data-platform-app"
  repository = "oci://ghcr.io/ministryofjustice/data-platform-charts"
  version    = "0.0.3"
  chart      = "data-platform-app"
  namespace  = kubernetes_namespace_v1.data_platform_app[0].metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/data-platform-app/values.yml.tftpl",
      {
        data_platform_app_env                = local.environment,
        data_platform_app_django_settings_module = "data_platform_app.settings.${local.environment}"
        data_platform_app_hostname           = local.environment_configuration.data_platform_app_hostname,
      }
    )
  ]
}
