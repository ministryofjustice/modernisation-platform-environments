resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.name
    labels = {
      "compute.data-platform.service.justice.gov.uk/workload" = var.workload
      "pod-security.kubernetes.io/enforce"                    = var.pod_security_mode
    }
  }
}
