resource "kubernetes_secret_v1" "chainguard_pull_credentials" {
  metadata {
    name      = "chainguard-pull-secret"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "cgr.dev" = {
          username = local.chainguard_credentials["username"]
          password = local.chainguard_credentials["password"]
          auth     = base64encode("${local.chainguard_credentials["username"]}:${local.chainguard_credentials["password"]}")
        }
      }
    })
  }
}

