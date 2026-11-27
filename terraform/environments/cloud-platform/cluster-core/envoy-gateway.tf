# Deploy the Envoy Gateway controller after its CRDs have been applied.
# CRDs and Gateway API safe-upgrade admission resources are managed separately
# in envoy-gateway-crds.tf.
# https://gateway.envoyproxy.io/docs/install/install-helm/#upgrading-from-the-previous-version
module "envoy_gateway" {
  source = "github.com/ministryofjustice/container-platform-terraform-envoy-gateway?ref=00e02e4382949c9ad35142eca2a9d57ef567c2f3" #1.2.1

  depends_on = [
    module.gatekeeper,
    kubectl_manifest.envoy_gateway_crds
  ]
}
