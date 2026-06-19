module "alb" {
  source = "./modules/alb"

  name_prefix    = "default-alb"
  certificate_arn = module.acm.certificate_arn

  envoy_service_name = module.envoy-gateway.service_name
  envoy_namespace    = module.envoy-gateway.namespace
  envoy_service_port = module.envoy-gateway.service_port

  scheme                 = "internet-facing"
  redirect_http_to_https = false

  tags = {
    Terraform   = "true"
  }
}