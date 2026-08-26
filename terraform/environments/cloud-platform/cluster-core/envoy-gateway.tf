# Base envoy installation, includes gateway api CRDs
module "envoy_gateway" {
  source = "github.com/ministryofjustice/container-platform-terraform-envoy-gateway?ref=54df47381507b0998f397d4d5a64d1245320c6a1" #1.1.0

  depends_on = [module.gatekeeper]
}