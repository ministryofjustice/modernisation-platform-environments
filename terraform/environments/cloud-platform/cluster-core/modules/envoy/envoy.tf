# Envoy Setup
resource "kubernetes_namespace_v1" "envoy_gateway_system" {
  metadata {
    name = "envoy-gateway-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}

resource "helm_release" "envoy_gateway" {
  name       = "envoy-gateway"
  chart      = "gateway-helm"
  repository = "oci://docker.io/envoyproxy/"
  version    = "1.8.1"
  namespace  = "envoy-gateway-system"

  depends_on = [kubernetes_namespace_v1.envoy_gateway_system]
}

resource "kubernetes_manifest" "gatewayclass" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: GatewayClass
    metadata:
      name: eg
    spec:
      controllerName: gateway.envoyproxy.io/gatewayclass-controller
  YAML
  )

  depends_on = [helm_release.envoy_gateway]
}

resource "kubernetes_manifest" "envoyproxy" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: EnvoyProxy
    metadata:
      name: custom-proxy-config
      namespace: envoy-gateway-system
    spec:
      provider:
        type: Kubernetes
        kubernetes:
          envoyDeployment:
            replicas: 2
            container:
              env:
                - name: GODEBUG
                  value: "cgocheck=0"
          envoyService:
            type: ClusterIP
  YAML
  )

  depends_on = [helm_release.envoy_gateway]
}

# The gateway lives in the same namespace as the Envoy-managed service and data plane pods.
# This keeps the Gateway, ALB-facing Service, and Ingress aligned with Kubernetes namespace scoping rules.
resource "kubernetes_manifest" "gateway" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: eg
      namespace: envoy-gateway-system
    spec:
      infrastructure:
        parametersRef:
          group: gateway.envoyproxy.io
          kind: EnvoyProxy
          name: custom-proxy-config
      gatewayClassName: eg
      listeners:
        - name: http
          protocol: HTTP
          port: 80
          allowedRoutes:
            namespaces:
              from: All
  YAML
  )

  depends_on = [
    helm_release.envoy_gateway,
    kubernetes_manifest.envoyproxy,
    kubernetes_manifest.gatewayclass,
  ]
}

