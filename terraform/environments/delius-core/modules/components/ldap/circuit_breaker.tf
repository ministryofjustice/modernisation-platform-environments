module "circuit_breaker" {
  source   = "./circuit_breaker"
  env_name = var.env_name
  tags     = var.tags
}
