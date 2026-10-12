resource "kubernetes_network_policy_v1" "openai" {
  count = local.openai_enabled ? 1 : 0

  metadata {
    name      = "litellm-openai"
    namespace = module.ai_gateway_namespace.name
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/instance" = "litellm-openai"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_expressions {
            key      = "app.kubernetes.io/instance"
            operator = "In"
            values   = ["litellm", "litellm-admin"]
          }
        }
      }

      ports {
        port     = "4000"
        protocol = "TCP"
      }
    }
  }
}
