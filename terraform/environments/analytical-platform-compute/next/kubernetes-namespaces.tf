resource "kubernetes_namespace" "next" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  metadata {
    name = "next"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "restricted"
      "compute.analytical-platform.service.justice.gov.uk/workload" = "next"
    }
  }
}
