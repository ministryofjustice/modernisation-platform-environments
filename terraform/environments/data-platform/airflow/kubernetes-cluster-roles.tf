# Cluster-wide permissions for the mwaa-external-secrets group, which the
# analytical-platform-airflow GitHub Actions role is mapped to in cluster.tf.
resource "kubernetes_cluster_role_v1" "mwaa_external_secrets" {
  metadata {
    name = "mwaa-external-secrets"
  }
  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["list"]
  }
}

