resource "kubernetes_manifest" "ai_gateway" {
  depends_on = [
    kubernetes_namespace_v1.ai_gateway,
    aws_acm_certificate_validation.ai_gateway,
    kubernetes_manifest.ai_gateway_lb_config,
    kubernetes_manifest.ai_gateway_tg_config_litellm,
    kubernetes_manifest.ai_gateway_tg_config_litellm_admin
  ]

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "ai-gateway"
      namespace = "ai-gateway"
      annotations = {
        "external-dns.alpha.kubernetes.io/hostname" = "${local.environment_configuration.ai_gateway_hostname},admin.${local.environment_configuration.ai_gateway_hostname}"
      }
    }
    spec = {
      gatewayClassName = "aws-alb"
      listeners = [
        {
          name     = "https"
          protocol = "HTTPS"
          port     = 443
          allowedRoutes = {
            namespaces = {
              from = "Same"
            }
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "ai_gateway_lb_config" {
  depends_on = [kubernetes_namespace_v1.ai_gateway]

  manifest = {
    apiVersion = "gateway.k8s.aws/v1beta1"
    kind       = "LoadBalancerConfiguration"
    metadata = {
      name      = "ai-gateway"
      namespace = "ai-gateway"
    }
    spec = {
      scheme = "internet-facing"
      listenerConfigurations = [
        {
          protocolPort       = "HTTPS:443"
          defaultCertificate = aws_acm_certificate.ai_gateway.arn
        }
      ]
      wafV2 = {
        webACL = aws_wafv2_web_acl.ai_gateway.arn
      }
    }
  }
}

resource "kubernetes_manifest" "ai_gateway_tg_config_litellm" {
  depends_on = [kubernetes_namespace_v1.ai_gateway]

  manifest = {
    apiVersion = "gateway.k8s.aws/v1beta1"
    kind       = "TargetGroupConfiguration"
    metadata = {
      name      = "ai-gateway-litellm"
      namespace = "ai-gateway"
    }
    spec = {
      targetReference = {
        name = "litellm"
        kind = "Service"
      }
      defaultConfiguration = {
        targetType = "ip"
      }
    }
  }
}

resource "kubernetes_manifest" "ai_gateway_tg_config_litellm_admin" {
  depends_on = [kubernetes_namespace_v1.ai_gateway]

  manifest = {
    apiVersion = "gateway.k8s.aws/v1beta1"
    kind       = "TargetGroupConfiguration"
    metadata = {
      name      = "ai-gateway-litellm-admin"
      namespace = "ai-gateway"
    }
    spec = {
      targetReference = {
        name = "litellm-admin"
        kind = "Service"
      }
      defaultConfiguration = {
        targetType = "ip"
      }
    }
  }
}
