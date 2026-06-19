resource "kubernetes_manifest" "alb_ingress_class_param" {
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "IngressClassParams"
    metadata = {
      name = var.ingress_class_name
    }
    spec = merge(
      {
        scheme = var.scheme
        namespaceSelector = {
          matchLabels = {
            "kubernetes.io/metadata.name" = var.envoy_namespace
          }
        }
      },
      length(var.tags) > 0 ? {
        tags = [
          for key, value in var.tags : {
            key   = key
            value = value
          }
        ]
      } : {}
    )
  }
}

resource "kubernetes_ingress_class_v1" "alb" {
  metadata {
    name = var.ingress_class_name
  }

  spec {
    controller = "eks.amazonaws.com/alb"

    parameters {
      api_group = "eks.amazonaws.com"
      kind      = "IngressClassParams"
      name      = kubernetes_manifest.alb_ingress_class_param.manifest.metadata.name
    }
  }
}

resource "kubernetes_ingress_v1" "envoy" {
  metadata {
    name      = "${var.name_prefix}-envoy-alb"
    namespace = var.envoy_namespace

    annotations = merge(
      {
        # ALB configuration
        "alb.ingress.kubernetes.io/target-type"     = "ip"
        "alb.ingress.kubernetes.io/healthcheck-path" = var.health_check_path
        # HTTPS configuration
        "alb.ingress.kubernetes.io/listen-ports"    = jsonencode([{ "HTTP" : 80 }, { "HTTPS" : 443 }])
        "alb.ingress.kubernetes.io/certificate-arn" = var.certificate_arn
      },
      var.redirect_http_to_https ? {
        "alb.ingress.kubernetes.io/ssl-redirect" = "443"
      } : {}
    )

    labels = var.labels
  }

  spec {
    ingress_class_name = kubernetes_ingress_class_v1.alb.metadata[0].name

    rule {
      http {
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"

          backend {
            service {
              name = var.envoy_service_name
              port {
                number = var.envoy_service_port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_ingress_class_v1.alb]
}
