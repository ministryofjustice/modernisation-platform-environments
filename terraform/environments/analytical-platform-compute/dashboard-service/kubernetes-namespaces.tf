resource "kubernetes_namespace" "dashboard_service" {
  count = terraform.workspace == "analytical-platform-compute-test" ? 0 : 1

  metadata {
    name = "dashboard-service"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "restricted"
      "compute.analytical-platform.service.justice.gov.uk/workload" = "dashboard-service"
    }
  }
}
