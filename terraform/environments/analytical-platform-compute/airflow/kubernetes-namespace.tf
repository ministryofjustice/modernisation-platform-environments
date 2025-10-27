resource "kubernetes_namespace" "airflow" {
  metadata {
    name = "airflow"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "baseline" # This was restricted, but the current pod specification doesn't set the right metadata
      "compute.analytical-platform.service.justice.gov.uk/workload" = "airflow"
    }
  }
}

resource "kubernetes_namespace" "mwaa" {
  metadata {
    name = "mwaa"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "restricted"
      "compute.analytical-platform.service.justice.gov.uk/workload" = "airflow"
    }
  }
}
