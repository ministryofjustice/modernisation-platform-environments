#### This file can be used to store data specific to the member account ####

# Note - this is only used in production, but we use the condition to avoid an error in non-prod envs.
data "aws_route53_zone" "production-network-services" {
  # provider = var.environment != "production" ? aws.core-vpc : aws.core-network-services
  provider     = aws.core-network-services
  name         = local.application_data.accounts[local.environment].acm_cert_domain_name
  private_zone = false
}