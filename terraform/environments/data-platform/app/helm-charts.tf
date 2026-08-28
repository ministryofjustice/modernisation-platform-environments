resource "helm_release" "app" {

  /* https://github.com/ministryofjustice/data-platform-app */
  name       = "app"
  repository = "oci://ghcr.io/ministryofjustice/data-platform-charts"
  version    = "0.5.0"
  chart      = "app"
  namespace  = module.app_namespace.name
  values = [
    templatefile(
      "${path.module}/src/helm/values/app/values.yml.tftpl",
      {
        app_env                    = local.environment,
        app_django_settings_module = "data_platform_app.settings.${local.environment == "production" ? "production" : "development"}",
        app_hostname               = local.environment_configuration.app_hostname,
        app_google_analytics_id    = local.environment_configuration.app_google_analytics_id,
        app_feature_ai_gateway_costs = tostring(local.environment_configuration.app_feature_ai_gateway_costs),
      }
    )
  ]
}

resource "helm_release" "app_configuration" {
  name      = "${local.component_name}-configuration"
  chart     = "${path.module}/src/helm/charts/${local.component_name}-configuration"
  version   = "1.3.0"
  namespace = module.app_namespace.name

  values = [
    templatefile(
      "${path.module}/src/helm/values/${local.component_name}-configuration/values.yml.tftpl",
      {
        hostname        = local.environment_configuration.app_hostname,
        certificate_arn = module.acm_app.acm_certificate_arn,
        alb_logs_bucket = module.alb_access_logs.s3_bucket_id,
      }
    )
  ]

  depends_on = [helm_release.app]
}
