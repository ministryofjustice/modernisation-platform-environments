module "cwa-poc2-environment" {
  source = "./cwa-poc2"

  environment = local.environment
  # application_data = local.application_data
  tags = local.tags
  route53_zone_external = data.aws_route53_zone.external.name
  
}