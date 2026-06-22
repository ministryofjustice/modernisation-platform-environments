# Envoy Setup
resource "kubernetes_namespace_v1" "envoy_gateway_system" {
  metadata {
    name = "envoy-gateway-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}

# Envoy install
resource "helm_release" "envoy_gateway" {
  name       = "envoy-gateway"
  chart      = "gateway-helm"
  repository = "oci://docker.io/envoyproxy/"
  version    = "1.8.1"
  namespace  = "envoy-gateway-system"

  depends_on = [kubernetes_namespace_v1.envoy_gateway_system]
}

# GatewayClass
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

# Gateway
resource "kubernetes_manifest" "gateway" {
  manifest = yamldecode(<<-YAML
     apiVersion: gateway.networking.k8s.io/v1
     kind: Gateway
     metadata:
       name: eg
       namespace: envoy-gateway-system
       annotations:
         cert-manager.io/cluster-issuer: letsencrypt-prod
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
         - name: https
           protocol: HTTPS
           hostname: "${var.wildcard_domain}"
           port: 443
           tls:
             mode: Terminate
             certificateRefs:
               - kind: Secret
                 name: cluster-wildcard-tls
           allowedRoutes:
             namespaces:
               from: All
   YAML
  )

  depends_on = [
    helm_release.envoy_gateway,
    kubernetes_manifest.gatewayclass,
  ]
}

# GatewayProxy
resource "kubernetes_manifest" "gateway_proxy" {
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
            pod:
              volumes:
                - name: dynamic-modules
                  image:
                    reference: ghcr.io/tetratelabs/built-on-envoy/composer:0.6.0-dev
                    pullPolicy: IfNotPresent
            container:
              env:
                - name: GODEBUG
                  value: "cgocheck=0"
              volumeMounts:
                - name: dynamic-modules
                  mountPath: /etc/envoy/dynamic-modules
                  readOnly: true
          envoyService:
            loadBalancerClass: service.k8s.aws/nlb
            annotations:
              service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
              service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
              service.beta.kubernetes.io/aws-load-balancer-name: envoy-gw-nlb-jb
      dynamicModules:
        - name: composer
          source:
            type: Local
            local:
              path: /etc/envoy/dynamic-modules/libcomposer.so
          doNotClose: true
          loadGlobally: false
   YAML
  )

  depends_on = [
    helm_release.envoy_gateway,
    kubernetes_manifest.gatewayclass,
  ]
}

