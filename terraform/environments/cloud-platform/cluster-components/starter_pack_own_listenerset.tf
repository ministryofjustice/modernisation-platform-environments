resource "kubernetes_namespace_v1" "starter-pack-with-own-listenerset" {
  metadata {
    name = "starter-pack-with-own-listenerset"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}

resource "kubernetes_manifest" "starter-pack-own-listenerset" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: ListenerSet
    metadata:
      name: starter-pack-own-listenerset
      namespace: starter-pack-with-own-listenerset
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt-production
    spec:
      parentRef:
        group: gateway.networking.k8s.io
        kind: Gateway
        name: default
        namespace: envoy-gateway-system
      listeners:
        - name: https
          protocol: HTTPS
          port: 443
          hostname: "own-listenerset.cp-1008-0927.development.container-platform.service.justice.gov.uk"
          tls:
            mode: Terminate
            certificateRefs:
              - group: ""
                kind: Secret
                name: own-listenerset-certificate
          allowedRoutes:
            namespaces:
              from: All
            kinds:
              - group: gateway.networking.k8s.io
                kind: HTTPRoute
  YAML
  )
}

module "starter_pack_own_listenerset" {
  count            = 1
  source           = "github.com/ministryofjustice/container-platform-terraform-starter-pack?ref=8f889396eff1451a6651edfc1ea72fbc800701a7" #1.3.0
  enable_httproute = true
  hostnames        = ["own-listenerset.${local.cluster_domain}"]
  namespace        = kubernetes_namespace_v1.starter-pack-with-own-listenerset.metadata[0].name
  image_repository = format("%s.dkr.ecr.%s.amazonaws.com/cloud-platform/container-platform-terraform-starter-pack", data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  image_tag        = "1.3.0"
  listenerset_name = kubernetes_manifest.starter-pack-own-listenerset.manifest["metadata"]["name"]
  listenerset_namespace = kubernetes_manifest.starter-pack-own-listenerset.manifest["metadata"]["namespace"]
}

resource "kubernetes_manifest" "starter-pack-own-listenerset-waf" {
  manifest = yamldecode(<<-YAML
    apiVersion: gateway.envoyproxy.io/v1alpha1
    kind: EnvoyExtensionPolicy
    metadata:
      name: starter-pack-own-listenerset-waf
      namespace: ${kubernetes_namespace_v1.starter-pack-with-own-listenerset.metadata[0].name}
    spec:
      targetRefs:
        - group: gateway.networking.k8s.io
          kind: HTTPRoute
          name: starter-pack-route
          namespace: ${kubernetes_namespace_v1.starter-pack-with-own-listenerset.metadata[0].name}
      dynamicModule:
        - name: composer
          filterName: coraza-waf
          config:
            directives:
              - Include @coraza.conf
              - SecRuleEngine On
              # Add custom rules specific to this application (use IDs 1000+)
              - SecRule REMOTE_ADDR "@ipMatch 86.136.25.232/32" "id:10001,phase:1,deny,status:403,log,msg:'source IP not allowed'"
  YAML
  )
}

