resource "kubernetes_namespace_v1" "ai_gateway" {
  metadata {
    name = local.component_name
    labels = {
      "compute.data-platform.service.justice.gov.uk/workload"               = "application"
      "compute.data-platform.service.justice.gov.uk/shared-gateway-enabled" = "true"
      "pod-security.kubernetes.io/enforce"                                  = "restricted"
    }
  }
}
