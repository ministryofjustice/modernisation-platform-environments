locals {
  github_sts_port   = 8080
  github_sts_host   = "sts.github.engineering.justice.gov.uk"
  github_sts_labels = { "app.kubernetes.io/name" = local.component_name }
}

resource "kubernetes_deployment_v1" "github_sts" {
  count = local.is-production ? 1 : 0

  metadata {
    name      = local.component_name
    namespace = local.environment_configuration.cloud_platform_namespace
    labels    = local.github_sts_labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.github_sts_labels
    }

    template {
      metadata {
        labels = local.github_sts_labels
      }

      spec {
        automount_service_account_token = false
        node_selector = {
          "kubernetes.io/arch" = "amd64"
        }

        security_context {
          run_as_non_root = true
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = local.component_name
          image = "ghcr.io/octo-sts/app:0.14.3@sha256:cb91dd3e7adbf15f9cacb8dd0f718fbc39eef038604869f53e011062747314f1"

          port {
            name           = "http"
            container_port = local.github_sts_port
          }

          env {
            name  = "PORT"
            value = tostring(local.github_sts_port)
          }

          env {
            name  = "STS_DOMAIN"
            value = local.github_sts_host
          }

          env {
            name  = "OCTOSTS_POLICY_DIR"
            value = ".github/sts"
          }

          env {
            name  = "OCTOSTS_OIDC_BLOCK_PRIVATE_IPS"
            value = "true"
          }

          env {
            name = "GITHUB_APP_IDS"
            value_from {
              secret_key_ref {
                name = "github-app"
                key  = "app_id"
              }
            }
          }

          env {
            name  = "APP_SECRET_CERTIFICATE_FILE"
            value = "/var/run/github-sts/github-app/private-key.pem"
          }

          volume_mount {
            name       = "github-app"
            mount_path = "/var/run/github-sts/github-app"
            read_only  = true
          }

          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              memory = "256Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        volume {
          name = "github-app"
          secret {
            secret_name = "github-app"
            items {
              key  = "private_key"
              path = "private-key.pem"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "github_sts" {
  count = local.is-production ? 1 : 0

  metadata {
    name      = local.component_name
    namespace = local.environment_configuration.cloud_platform_namespace
    labels    = local.github_sts_labels
  }

  spec {
    type     = "ClusterIP"
    selector = local.github_sts_labels

    port {
      name        = "http"
      port        = local.github_sts_port
      target_port = "http"
    }
  }
}

resource "kubernetes_ingress_v1" "github_sts" {
  count = local.is-production ? 1 : 0

  metadata {
    name      = local.component_name
    namespace = local.environment_configuration.cloud_platform_namespace
    labels    = local.github_sts_labels
    annotations = {
      "external-dns.alpha.kubernetes.io/aws-weight"     = "100"
      "external-dns.alpha.kubernetes.io/set-identifier" = "${local.component_name}-${local.environment_configuration.cloud_platform_namespace}-green"
      "nginx.ingress.kubernetes.io/ssl-redirect"        = "true"
    }
  }

  spec {
    ingress_class_name = "default"

    tls {
      hosts       = [local.github_sts_host]
      secret_name = "github-sts-prod-tls"
    }

    rule {
      host = local.github_sts_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.github_sts[0].metadata[0].name
              port {
                name = "http"
              }
            }
          }
        }
      }
    }
  }
}
