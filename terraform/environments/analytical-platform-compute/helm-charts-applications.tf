resource "helm_release" "ui" {
  /* https://github.com/ministryofjustice/analytical-platform-ui */
  name       = "ui"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "0.2.4"
  chart      = "analytical-platform-ui"
  namespace  = kubernetes_namespace.ui.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/ui/values.yml.tftpl",
      {
        ui_hostname  = local.environment_configuration.ui_hostname
        eks_role_arn = module.analytical_platform_ui_service_role.iam_role_arn
      }
    )
  ]
}
