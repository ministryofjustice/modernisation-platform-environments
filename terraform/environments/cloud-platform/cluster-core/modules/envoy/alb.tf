# Using AWS auto mode to provision the ALB, must be done through an ingress
resource "kubernetes_namespace_v1" "alb_auto_mode_test" {
  metadata {
    name = "envoy-edge"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}

resource "kubernetes_ingress_class_v1" "alb" {
  metadata {
    name = "alb"
    labels = {
      "app.kubernetes.io/name" = "LoadBalancerController"
    }
  }

  spec {
    controller = "eks.amazonaws.com/alb"
  }
}

resource "kubernetes_service_v1" "envoy_alb" {
  metadata {
    name      = "envoy-alb"
    namespace = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
  }

  spec {
    type = "ClusterIP"

    selector = {
      "gateway.envoyproxy.io/owning-gateway-name"      = "eg"
      "gateway.envoyproxy.io/owning-gateway-namespace" = "envoy-gateway-system"
    }

    port {
      name        = "http"
      port        = 80
      target_port = "10080"
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "alb_auto_mode_test" {
  metadata {
    name      = "envoy-edge-ingress"

    namespace = kubernetes_namespace_v1.envoy_gateway_system.metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/scheme"              = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"         = "ip"
      "alb.ingress.kubernetes.io/certificate-arn"     = var.alb_certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"        = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"        = "443"
    }
  }

  spec {
    ingress_class_name = "alb"

    tls {
      hosts = ["*.cp-1606-0845.development.container-platform.service.justice.gov.uk"]
    }

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.envoy_alb.metadata[0].name

              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
