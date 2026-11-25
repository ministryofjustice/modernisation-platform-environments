# Deploy the Envoy Gateway controller after its CRDs have been applied.
# CRDs and Gateway API safe-upgrade admission resources are managed separately
# in envoy-gateway-crds.tf.
# https://gateway.envoyproxy.io/docs/install/install-helm/#upgrading-from-the-previous-version
module "envoy_gateway" {
  source = "github.com/ministryofjustice/container-platform-terraform-envoy-gateway?ref=disable-crds" #1.2.0

  depends_on = [
    module.gatekeeper,
    kubectl_manifest.envoy_gateway_crds
  ]
}
