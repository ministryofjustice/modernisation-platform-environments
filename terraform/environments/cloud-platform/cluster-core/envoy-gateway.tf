# Base envoy installation, includes gateway api CRDs
module "envoy_gateway" {
  source = "github.com/ministryofjustice/container-platform-terraform-envoy-gateway?ref=disable-crds" #1.2.0

  depends_on = [
    module.gatekeeper,
    kubectl_manifest.envoy_gateway_crds
  ]
}
