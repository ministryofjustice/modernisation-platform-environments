resource "helm_release" "ui" {
  /* https://github.com/ministryofjustice/analytical-platform-ui */
  name       = "ui"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "0.0.0-rc1"
  chart      = "analytical-platform-ui"
  namespace  = kubernetes_namespace.ui.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/ui/values.yml.tftpl",
      {
        ui_hostname = local.environment_configuration.ui_hostname
      }
    )
  ]
}

resource "helm_release" "ollamate" {
  /* https://github.com/ministryofjustice/analytical-platform-ollamate */
  name       = "ui"
  repository = "oci://ghcr.io/ministryofjustice/analytical-platform-charts"
  version    = "0.0.0-rc1"
  chart      = "analytical-platform-ollamate"
  namespace  = kubernetes_namespace.ollamate.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/values/ollamate/values.yml.tftpl",
      {
        ollamate_hostname = "ollamate.${local.environment_configuration.route53_zone}"
      }
    )
  ]
}
