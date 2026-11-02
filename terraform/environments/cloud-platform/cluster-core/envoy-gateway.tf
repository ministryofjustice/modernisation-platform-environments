# Base envoy installation, includes gateway api CRDs
module "envoy_gateway" {
  source = "github.com/ministryofjustice/container-platform-terraform-envoy-gateway?ref=6e777a2325f1424a6ac4f79bf52a509503a4234e" #1.2.0

  depends_on = [module.gatekeeper]
}
