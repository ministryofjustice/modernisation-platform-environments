resource "helm_release" "cilium" {
  /* https://artifacthub.io/packages/helm/cilium/cilium */

  name       = "cilium"
  repository = "oci://quay.io/cilium/charts"
  chart      = "cilium"
  version    = local.cluster_configuration.helm_chart_versions.cilium
  namespace  = "kube-system"

  wait = false

  values = [
    templatefile(
      "${path.module}/configuration/helm/cilium/values.yml.tftpl",
      {
        cluster_name   = local.eks_cluster_name
        k8sServiceHost = trimprefix(module.eks.cluster_endpoint, "https://")
      }
    )
  ]

  depends_on = [
    module.eks,
    kubernetes_manifest.gateway_api_crd
  ]
}

resource "helm_release" "coredns" {
  /* https://artifacthub.io/packages/helm/coredns/coredns */

  name       = "coredns"
  repository = "oci://ghcr.io/coredns/charts"
  chart      = "coredns"
  version    = local.cluster_configuration.helm_chart_versions.coredns
  namespace  = "kube-system"

  wait = false

  values = [
    templatefile(
      "${path.module}/configuration/helm/coredns/values.yml.tftpl",
      {}
    )
  ]
}

resource "helm_release" "kyverno" {
  /* https://artifacthub.io/packages/helm/kyverno/kyverno */
  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno"
  chart      = "kyverno"
  version    = local.cluster_configuration.helm_chart_versions.kyverno
  namespace  = module.kyverno_namespace.name

  values = [
    templatefile(
      "${path.module}/configuration/helm/kyverno/values.yml.tftpl",
      {}
    )
  ]

  depends_on = [
    helm_release.cilium,
    helm_release.coredns
  ]
}
