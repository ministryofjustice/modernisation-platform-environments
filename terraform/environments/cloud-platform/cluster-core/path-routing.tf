locals {
  path_routing_test_namespace = "gateway-api-test-path-routing"
  path_routing_test_hostname  = format("multi-path.%s.%s", local.cluster_name, local.cluster_base_domain)

  path_routing_test_backends = {
    api-v1 = {
      message = "You are on /api/v1"
      path    = "/api/v1"
    }
    api-v2 = {
      message = "You are on /api/v2"
      path    = "/api/v2"
    }
    web = {
      message = "You are on /web"
      path    = "/web"
    }
    catch-all = {
      message = "You are on /"
      path    = "/"
    }
  }
}

resource "kubernetes_namespace_v1" "path_routing_test" {
  metadata {
    name = local.path_routing_test_namespace
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}

resource "kubernetes_deployment_v1" "path_routing_test" {
  for_each = local.path_routing_test_backends

  metadata {
    name      = "multi-path-app-${each.key}"
    namespace = kubernetes_namespace_v1.path_routing_test.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "multi-path-app-${each.key}"
      }
    }

    template {
      metadata {
        labels = {
          app = "multi-path-app-${each.key}"
        }
      }

      spec {
        container {
          name  = "multi-path-app"
          image = "hashicorp/http-echo:1.0"
          args  = ["-text=${each.value.message}"]

          port {
            container_port = 5678
          }

          security_context {
            allow_privilege_escalation = false
            run_as_non_root            = true
            run_as_user                = 1000

            capabilities {
              drop = ["ALL"]
            }

            seccomp_profile {
              type = "RuntimeDefault"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "path_routing_test" {
  for_each = local.path_routing_test_backends

  metadata {
    name      = "multi-path-app-${each.key}"
    namespace = kubernetes_namespace_v1.path_routing_test.metadata[0].name
  }

  spec {
    selector = {
      app = "multi-path-app-${each.key}"
    }

    type = "ClusterIP"

    port {
      port        = 80
      target_port = 5678
    }
  }
}

resource "kubernetes_manifest" "path_routing_test" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: multi-path-route
      namespace: ${local.path_routing_test_namespace}
    spec:
      parentRefs:
        - name: eg
          namespace: envoy-gateway-system
      hostnames:
        - ${local.path_routing_test_hostname}
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /api/v1
          backendRefs:
            - name: ${kubernetes_service_v1.path_routing_test["api-v1"].metadata[0].name}
              port: 80
        - matches:
            - path:
                type: PathPrefix
                value: /api/v2
          backendRefs:
            - name: ${kubernetes_service_v1.path_routing_test["api-v2"].metadata[0].name}
              port: 80
        - matches:
            - path:
                type: PathPrefix
                value: /web
          backendRefs:
            - name: ${kubernetes_service_v1.path_routing_test["web"].metadata[0].name}
              port: 80
        - matches:
            - path:
                type: PathPrefix
                value: /
          backendRefs:
            - name: ${kubernetes_service_v1.path_routing_test["catch-all"].metadata[0].name}
              port: 80
  YAML
  )

  depends_on = [
    module.envoy_gateway,
    kubernetes_service_v1.path_routing_test,
  ]
}