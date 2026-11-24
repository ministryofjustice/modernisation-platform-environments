locals {
  envoy_gateway_crds_version = "v1.8.6"
  gateway_api_channel        = "standard"
}

data "helm_template" "envoy_gateway_crds" {
  name       = "envoy-gateway-crds"
  repository = "oci://docker.io/envoyproxy"
  chart      = "gateway-crds-helm"
  version    = local.envoy_gateway_crds_version

  values = [
    yamlencode({
      crds = {
        gatewayAPI = {
          enabled = true
          channel = local.gateway_api_channel
        }

        envoyGateway = {
          enabled = true
        }
      }
    })
  ]
}

data "kubectl_file_documents" "envoy_gateway_crds" {
  content = data.helm_template.envoy_gateway_crds.manifest
}

resource "kubectl_manifest" "envoy_gateway_crds" {
  for_each = data.kubectl_file_documents.envoy_gateway_crds.manifests

  yaml_body = each.value

  server_side_apply = true
  force_conflicts   = true
  apply_only        = true
}