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

  wait    = true
  timeout = 300

  depends_on = [kubernetes_namespace_v1.envoy_gateway_system]
}

# GatewayClass
resource "kubectl_manifest" "gatewayclass" {
  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: GatewayClass
    metadata:
      name: eg
    spec:
      controllerName: gateway.envoyproxy.io/gatewayclass-controller
  YAML

  server_side_apply = true
  wait              = true

  depends_on = [helm_release.envoy_gateway]
}

# Gateway
resource "kubectl_manifest" "gateway" {
  yaml_body = <<-YAML
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

  server_side_apply = true
  wait              = true

  depends_on = [
    helm_release.envoy_gateway,
    kubectl_manifest.gatewayclass,
  ]
}

# GatewayProxy (ensure Envoy Gateway CRDs are available)
resource "kubectl_manifest" "gateway_proxy" {
  yaml_body = <<-YAML
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
            # Auto Mode NLB class; the classic service.k8s.aws/nlb controller
            # isn't present on Auto Mode clusters.
            loadBalancerClass: eks.amazonaws.com/nlb
            annotations:
              service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
              service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
              service.beta.kubernetes.io/aws-load-balancer-name: envoy-${var.cluster_name}
              # Preserve the client IP; off by default on NLB ip-target groups.
              # Without it Envoy sees the NLB node IP and SecurityPolicy CIDRs never match.
              service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: preserve_client_ip.enabled=true
      dynamicModules:
        - name: composer
          source:
            type: Local
            local:
              path: /etc/envoy/dynamic-modules/libcomposer.so
          doNotClose: true
          loadGlobally: false
  YAML

  server_side_apply = true
  wait              = true

  depends_on = [
    helm_release.envoy_gateway,
    kubectl_manifest.gatewayclass,
  ]
}

# Gateway-wide WAF policy (ensure EnvoyExtensionPolicy CRD is available)
resource "kubectl_manifest" "coraza_waf" {
  yaml_body = <<-YAML
    apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: EnvoyExtensionPolicy
    metadata:
      name: coraza-waf
      namespace: envoy-gateway-system
    spec:
      targetRefs:
        - group: gateway.networking.k8s.io
          kind: Gateway
          name: eg
      dynamicModule:
        - name: composer
          filterName: coraza-waf
          config:
            directives:
              # TODO: look into admin rules that cna't be overridden by route-level policies, and whether we need to disable them. (e.g. IMDS endpoint)



              # Loads Coraza base defaults and recommended core settings.
              - Include @coraza.conf

              # Enables WAF enforcement at cluster level – teams can override per-route.
              - SecRuleEngine On

              # Enables audit logging for matched/security-relevant transactions.
              - SecAuditEngine On

              # Writes audit logs as JSON to make stern/k9s output machine-parseable.
              - SecAuditLogFormat JSON

              # Sends audit logs to container stdout so they appear in Kubernetes logs.
              - SecAuditLog /dev/stdout

              # Skips response body inspection to reduce overhead/noise.
              - SecResponseBodyAccess Off

              # Loads CRS tuning/bootstrap variables before CRS rules.
              - Include @crs-setup.conf

              # Loads the full OWASP Core Rule Set.
              - Include @owasp_crs/*.conf
  YAML

  server_side_apply = true
  wait              = true

  depends_on = [
    helm_release.envoy_gateway,
    kubectl_manifest.gatewayclass,
  ]
}
