# ──────────────────────────────────────────────────────────────────
# Grant rds_iam role to the litellm DB user (one-time setup).
# ──────────────────────────────────────────────────────────────────

resource "kubernetes_job_v1" "grant_rds_iam" {
  metadata {
    name      = "psql-grant"
    namespace = local.component_name
  }

  spec {
    backoff_limit              = 2
    ttl_seconds_after_finished = 60

    template {
      metadata {
        name = "psql-grant"
      }

      spec {
        restart_policy       = "Never"
        service_account_name = local.component_name

        toleration {
          key      = "compute.data-platform.service.justice.gov.uk/node-pool"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        security_context {
          run_as_non_root = true
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name    = "psql"
          image   = "postgres:15-alpine"
          command = ["sh", "-c"]
          args = [
            <<-EOT
            wget -qO /tmp/global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
            PGPASSWORD="$PGPASSWORD" psql \
              "host=${module.ai_gateway_aurora.cluster_endpoint} \
               port=${tostring(module.ai_gateway_aurora.cluster_port)} \
               dbname=${module.ai_gateway_aurora.cluster_database_name} \
               user=${module.ai_gateway_aurora.cluster_master_username} \
               sslmode=verify-full \
               sslrootcert=/tmp/global-bundle.pem" \
              -c "GRANT rds_iam TO ${module.ai_gateway_aurora.cluster_master_username};"
            EOT
          ]

          env {
            name      = "PGPASSWORD"
            value     = random_password.aurora.result
            sensitive = true
          }

          security_context {
            allow_privilege_escalation = false
            run_as_non_root            = true
            run_as_user                = 65534
            capabilities {
              drop = ["ALL"]
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }

  # Block the CI apply until the Job completes (or fails).
  wait_for_completion = true
  timeouts {
    create = "3m"
  }

  depends_on = [
    module.ai_gateway_namespace,
    kubernetes_service_account_v1.ai_gateway,
    module.ai_gateway_aurora
  ]
}