# resource "kubernetes_namespace" "aws_observability" {
#   metadata {
#     name = "aws-observability"
#   }
# }
# resource "kubernetes_namespace" "ui" {
#   metadata {
#     name = "ui"
#     labels = {
#       "pod-security.kubernetes.io/enforce"                          = "restricted"
#       "compute.analytical-platform.service.justice.gov.uk/workload" = "ui"
#     }
#   }
# }

