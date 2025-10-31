resource "kubernetes_namespace" "actions_runners" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  metadata {
    name = "actions-runners"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "baseline"
      "compute.analytical-platform.service.justice.gov.uk/workload" = "actions-runners"
    }
  }
}
