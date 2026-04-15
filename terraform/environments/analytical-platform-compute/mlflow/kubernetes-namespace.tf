resource "kubernetes_namespace" "mlflow" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  metadata {
    name = "mlflow"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "restricted"
      "compute.analytical-platform.service.justice.gov.uk/workload" = "mlflow"
    }
  }
}
