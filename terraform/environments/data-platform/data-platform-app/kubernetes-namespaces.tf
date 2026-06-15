resource "kubernetes_namespace_v1" "data_platform_app" {
  count = terraform.workspace == "data-platform-test" ? 0 : 1

  metadata {
    name = "data-platform-app"
    labels = {
      "pod-security.kubernetes.io/enforce"                          = "restricted"
      # JSNote: Is this needed or is it the correct workload?
      "compute.data-platform.service.justice.gov.uk/workload" = "data-platform-app"
    }
  }
}
