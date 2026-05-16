resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.name
    labels = merge(
      var.additional_labels,
      {
        "compute.data-platform.service.justice.gov.uk/workload" = var.workload
      }
    )
  }
}
