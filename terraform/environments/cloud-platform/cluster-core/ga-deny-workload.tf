# Deny-by-default test workload.
#
# A single echo backend in the `test-workload` namespace, served under one or
# more hostnames via the shared-alb Gateway from Tim's foundation
# (ga-gateway-platform.tf). Each hostname is a separate HTTPRoute and receives
# per-host WAF treatment in ga-deny-waf.tf.
#
# Kept in its own file (separate from Tim's foundation) so his gateway-api
# branch reconciles cleanly when it merges to main. The namespace uses the
# `restricted` Pod Security Admission level required by the cluster's
# Gatekeeper policy (user-ns-require-psa-label).

locals {
  # Incremental: start with echo1 only; additional hostnames (echo3, echo4,
  # echo5) are added in later steps as each deny-by-default scenario is built.
  deny_echo_hostnames = {
    echo1 = "echo1.${local.cluster_name}.${local.cluster_base_domain}"
    echo3 = "echo3.${local.cluster_name}.${local.cluster_base_domain}"
  }
}

resource "kubectl_manifest" "deny_test_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: test-workload
      labels:
        pod-security.kubernetes.io/enforce: restricted
  YAML

  server_side_apply = true
  wait              = true
}

resource "kubectl_manifest" "deny_test_deployment" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: echo
      namespace: test-workload
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: echo
      template:
        metadata:
          labels:
            app: echo
        spec:
          securityContext:
            runAsNonRoot: true
            seccompProfile:
              type: RuntimeDefault
          containers:
            - name: echo
              image: hashicorp/http-echo:latest
              securityContext:
                allowPrivilegeEscalation: false
                capabilities:
                  drop:
                    - ALL
              args:
                - "-text=hello from deny-by-default echo"
              ports:
                - containerPort: 5678
  YAML

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.deny_test_namespace,
  ]
}

resource "kubectl_manifest" "deny_test_service" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: echo
      namespace: test-workload
    spec:
      type: NodePort
      selector:
        app: echo
      ports:
        - port: 80
          targetPort: 5678
  YAML

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.deny_test_namespace,
    kubectl_manifest.deny_test_deployment,
  ]
}

resource "kubectl_manifest" "deny_test_http_routes" {
  for_each = local.deny_echo_hostnames

  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: ${each.key}-route
      namespace: test-workload
    spec:
      parentRefs:
        - name: shared-alb
          namespace: lbc-test
      hostnames:
        - "${each.value}"
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          backendRefs:
            - name: echo
              port: 80
  YAML

  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.deny_test_service,
    kubectl_manifest.gateway_platform,
  ]
}
