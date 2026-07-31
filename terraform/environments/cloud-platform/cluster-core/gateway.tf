# Base envoy installation, includes gateway api CRDs
module "envoy_gateway" {
  source = "github.com/ministryofjustice/container-platform-terraform-envoy-gateway?ref=d3bea0e86de00c0ca463084a0e7921fb776fa26e" #1.0.0

  depends_on = [module.gatekeeper]
}
