resource "kubernetes_manifest" "namespace" {
  manifest = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = var.name
      labels = {
        "pod-security.kubernetes.io/enforce" = "restricted"
      }
    }
  }
}

resource "kubernetes_manifest" "deployment" {
  manifest = {
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name      = "nginx"
      namespace = var.name
    }
    spec = {
      replicas = 1
      selector = {
        matchLabels = { app = "nginx" }
      }
      template = {
        metadata = {
          labels = { app = "nginx" }
        }
        spec = {
          securityContext = {
            seccompProfile = { type = "RuntimeDefault" }
          }
          containers = [
            {
              name  = "nginx"
              image = "nginxinc/nginx-unprivileged:stable"
              ports = [{ containerPort = 8080 }]
              securityContext = {
                allowPrivilegeEscalation = false
                readOnlyRootFilesystem   = false
                runAsNonRoot             = true
                capabilities             = { drop = ["ALL"] }
              }
            }
          ]
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.namespace]
}

resource "kubernetes_manifest" "service" {
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "nginx"
      namespace = var.name
    }
    spec = {
      selector = { app = "nginx" }
      ports = [
        {
          port       = 80
          targetPort = 8080
          protocol   = "TCP"
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.deployment]
}

resource "kubernetes_manifest" "httproute" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "nginx"
      namespace = var.name
    }
    spec = {
      hostnames = [var.hostname]
      parentRefs = [
        {
          name      = var.gateway_name
          namespace = var.gateway_namespace
        }
      ]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = "nginx"
              port = 80
            }
          ]
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.service]
}

locals {
  # Base directives applied to every route-level WAF policy.
  # SecAuditEngine RelevantOnly + SecAuditLogRelevantStatus suppresses audit
  # log entries for normal (clean) requests, keeping stern output readable.
  # Use an RE2-compatible pattern (no lookaheads) to include all 5xx and
  # all 4xx except 404.
  base_directives = [
    "Include @coraza.conf",
    "SecRuleEngine ${var.waf_rule_engine}",
    "SecAuditEngine RelevantOnly",
    "SecAuditLogRelevantStatus \"^(?:5[0-9]{2}|40[0-35-9]|4[1-9][0-9])$\"",
    "SecAuditLogFormat JSON",
    "SecAuditLog /dev/stdout",
    "SecResponseBodyAccess Off",
    "Include @crs-setup.conf",
    "Include @owasp_crs/*.conf",
  ]

  # Caller-supplied directives are appended last so they can override CRS defaults.
  all_directives = concat(local.base_directives, var.extra_waf_directives)
}

resource "kubernetes_manifest" "waf_policy" {
  count = var.create_waf_policy ? 1 : 0

  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyExtensionPolicy"
    metadata = {
      name      = "coraza-waf"
      namespace = var.name
    }
    spec = {
      targetRefs = [
        {
          group = "gateway.networking.k8s.io"
          kind  = "HTTPRoute"
          name  = "nginx"
        }
      ]
      dynamicModule = [
        {
          name       = "composer"
          filterName = "coraza-waf"
          config = {
            directives = local.all_directives
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.httproute]
}
