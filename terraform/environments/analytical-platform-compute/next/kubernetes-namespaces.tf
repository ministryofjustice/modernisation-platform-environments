resource "kubernetes_namespace" "main" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  metadata {
    name = local.component_name
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "restricted"
      "compute.analytical-platform.service.justice.gov.uk/workload" = local.component_name
    }
  }
}

moved {
  from = kubernetes_namespace.next
  to   = kubernetes_namespace.main
}
