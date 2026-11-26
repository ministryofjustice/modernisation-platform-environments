locals {
  github_sts_webhook_name   = "${local.component_name}-webhook"
  github_sts_webhook_labels = { "app.kubernetes.io/name" = local.github_sts_webhook_name }
}

resource "kubernetes_deployment_v1" "github_sts_webhook" {
  count = local.is-production ? 1 : 0

  metadata {
    name      = local.github_sts_webhook_name
    namespace = local.environment_configuration.cloud_platform_namespace
    labels    = local.github_sts_webhook_labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.github_sts_webhook_labels
    }

    template {
      metadata {
        labels = local.github_sts_webhook_labels
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
          name  = local.github_sts_webhook_name
          image = "ghcr.io/octo-sts/webhook:0.14.3@sha256:3c47f6f6455ef8f613727bc182946dc6b3099df15d48f9ce5721d7c65001b3d7"

          port {
            name           = "http"
            container_port = local.github_sts_port
          }

          env {
            name  = "PORT"
            value = tostring(local.github_sts_port)
          }

          env {
            name  = "OCTOSTS_POLICY_DIR"
            value = local.github_sts_policy_dir
          }

          env {
            name  = "ORG_POLICY_REPO"
            value = local.github_sts_policy_repo
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
            name = "GITHUB_WEBHOOK_SECRET"
            value_from {
              secret_key_ref {
                name = "${local.component_name}-webhook"
                key  = "webhook_secret"
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
              path = "/healthcheck"
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

resource "kubernetes_service_v1" "github_sts_webhook" {
  count = local.is-production ? 1 : 0

  metadata {
    name      = local.github_sts_webhook_name
    namespace = local.environment_configuration.cloud_platform_namespace
    labels    = local.github_sts_webhook_labels
  }

  spec {
    type     = "ClusterIP"
    selector = local.github_sts_webhook_labels

    port {
      name        = "http"
      port        = local.github_sts_port
      target_port = "http"
    }
  }
}
