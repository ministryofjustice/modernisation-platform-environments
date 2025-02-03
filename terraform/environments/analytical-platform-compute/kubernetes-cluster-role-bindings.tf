resource "kubernetes_cluster_role_binding" "mwaa_external_secrets" {
  metadata {
    name = "mwaa-external-secrets"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.mwaa_external_secrets.metadata[0].name
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "mwaa-external-secrets"
  }
}
