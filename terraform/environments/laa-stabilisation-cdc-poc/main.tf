module "cwa-poc2-environment" {
  source = "./cwa-poc2"

  providers = {
    aws.core-vpc = aws.core-vpc
  }

  environment = local.environment
  # application_data = local.application_data
  tags = local.tags
  route53_zone_external = data.aws_route53_zone.external.name
  route53_zone_external_id = data.aws_route53_zone.external.zone_id
  
}