#### This file can be used to store data specific to the member account ####

# Note - this is only used in production, but we use application variable for its name to avoid an error in non-prod envs
# This means for non-prod, the cloudfront_domain_name will be "modernisation-platform.service.justice.gov.uk"
# For production, this will be the actual route53 hosted zone name, which will be the same as the A record name, e.g. "meansassessment.service.justice.gov.uk"

data "aws_route53_zone" "production-network-services" {
  provider     = aws.core-network-services
  name         = local.application_data.accounts[local.environment].cloudfront_domain_name
  private_zone = false
}
