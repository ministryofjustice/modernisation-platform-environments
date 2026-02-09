resource "helm_release" "cilium" {
  /* https://artifacthub.io/packages/helm/cilium/cilium */

  name       = "cilium"
  repository = "oci://quay.io/cilium/charts"
  chart      = "cilium"
  version    = "1.19.0"
  namespace  = "kube-system"

  # Don't wait for pods - they need nodes to run on
  # Just install the manifests and move on
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
  version    = "1.45.2"
  namespace  = "kube-system"

  wait = false

  values = [
    templatefile(
      "${path.module}/configuration/helm/coredns/values.yml.tftpl",
      {}
    )
  ]
}
