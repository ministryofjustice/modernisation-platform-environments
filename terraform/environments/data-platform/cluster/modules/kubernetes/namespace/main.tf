resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.name
    labels = merge(
      {
        "compute.data-platform.service.justice.gov.uk/workload" = var.workload
      },
      var.pod_security_mode == null ? {} : {
        "pod-security.kubernetes.io/enforce" = var.pod_security_mode
      }
    )
  }
}
