resource "kubernetes_ingress_v1" "litellm" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  metadata {
    name      = "litellm"
    namespace = jsondecode(data.aws_secretsmanager_secret_version.cloud_platform_live_namespace[0].secret_string)["namespace"]
    annotations = {
      "external-dns.alpha.kubernetes.io/aws-weight"        = "100"
      "external-dns.alpha.kubernetes.io/hostname"          = local.environment_configuration.llm_gateway_hostname
      "external-dns.alpha.kubernetes.io/set-identifier"    = "litellm-${local.application_name}-${local.component_name}-${local.environment}-green"
      "nginx.ingress.kubernetes.io/whitelist-source-range" = join(",", local.environment_configuration.llm_gateway_ingress_allowlist)
    }
    labels = {}
  }

  spec {
    ingress_class_name = "default"
    rule {
      host = local.environment_configuration.llm_gateway_hostname
      http {
        path {
          path      = "/"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "litellm"
              port {
                number = 4000
              }
            }
          }
        }
        // This path is to stop metrics being accessed externally
        path {
          path      = "/metrics"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "blackhole"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [local.environment_configuration.llm_gateway_hostname]
      secret_name = "llms-gateway-tls"
    }
  }
}
