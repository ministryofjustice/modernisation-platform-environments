resource "helm_release" "grafana" {
  count = local.environment_configuration.monitoring_stack_enabled ? 1 : 0

  name             = "grafana"
  repository       = "oci://ghcr.io/grafana-community/helm-charts"
  chart            = "grafana"
  version          = local.environment_configuration.grafana_chart_version
  namespace        = local.environment_configuration.grafana_namespace
  create_namespace = false # namespaces are provisioned in https://github.com/ministryofjustice/cloud-platform-environments/tree/main/namespaces

  values = [
    templatefile("${path.module}/src/helm/values/grafana/values.yml.tftpl", {
      hostname = local.environment_configuration.monitoring_hostname
    })
  ]
}
