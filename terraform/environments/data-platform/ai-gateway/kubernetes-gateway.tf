resource "kubernetes_manifest" "ai_gateway" {
  depends_on = [
    kubernetes_namespace_v1.ai_gateway,
    module.ai_gateway_acm
  ]

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "ai-gateway"
      namespace = "ai-gateway"
      annotations = {
        "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"     = "ip"
        "alb.ingress.kubernetes.io/certificate-arn" = tostring(module.ai_gateway_acm.acm_certificate_arn)
        "alb.ingress.kubernetes.io/wafv2-acl-arn"   = tostring(module.ai_gateway_waf.web_acl_arn)
        "alb.ingress.kubernetes.io/listen-ports"    = jsonencode([{ HTTPS = 443 }])
        "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
        "external-dns.alpha.kubernetes.io/hostname" = tostring("${local.environment_configuration.ai_gateway_hostname},admin.${local.environment_configuration.ai_gateway_hostname}")
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
