resource "kubernetes_cluster_role" "mwaa_external_secrets" {
  metadata {
    name = "mwaa-external-secrets"
  }
  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["list"]
  }
}
