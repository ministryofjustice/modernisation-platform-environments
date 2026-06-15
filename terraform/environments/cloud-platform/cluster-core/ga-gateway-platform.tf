resource "kubectl_manifest" "gateway_platform" {
  for_each = {
    "loadbalancerconfiguration" = <<-YAML
      apiVersion: gateway.k8s.aws/v1beta1
      kind: LoadBalancerConfiguration
      metadata:
        name: internet-facing
        namespace: kube-system
      spec:
        scheme: internet-facing
        ipAddressType: ipv4
    YAML
    "gatewayclass" = <<-YAML
      apiVersion: gateway.networking.k8s.io/v1
      kind: GatewayClass
      metadata:
        name: amazon-alb
      spec:
        controllerName: gateway.k8s.aws/alb
        parametersRef:
          group: gateway.k8s.aws
          kind: LoadBalancerConfiguration
          name: internet-facing
          namespace: kube-system
    YAML
    "namespace" = <<-YAML
      apiVersion: v1
      kind: Namespace
      metadata:
        name: lbc-test
        labels:
          pod-security.kubernetes.io/enforce: restricted
    YAML
    "gateway" = <<-YAML
      apiVersion: gateway.networking.k8s.io/v1
      kind: Gateway
      metadata:
        name: shared-alb
        namespace: lbc-test
      spec:
        gatewayClassName: amazon-alb
        listeners:
        - name: http
          port: 80
          protocol: HTTP
          allowedRoutes:
            namespaces:
              from: All
        - name: https
          port: 443
          protocol: HTTPS
          hostname: "*.${local.cluster_name}.${local.cluster_base_domain}"
          tls:
            mode: Terminate
            options:
              gateway.k8s.aws/certificate-arn: "${aws_acm_certificate_validation.cluster_wildcard.certificate_arn}"
          allowedRoutes:
            namespaces:
              from: All
    YAML
  }

  yaml_body         = each.value
  server_side_apply = true
  wait              = true

  depends_on = [
    kubectl_manifest.gateway_api_crds,
    helm_release.aws_load_balancer_controller,
    aws_acm_certificate_validation.cluster_wildcard,
  ]
}
