resource "kubernetes_namespace" "mlflow" {
  metadata {
    name = "mlflow"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "restricted"
      "compute.analytical-platform.service.justice.gov.uk/workload" = "mlflow"
    }
  }
}
