#### This file can be used to store data specific to the member account ####

# Note - this is only used in production, but we use application variable for its name to avoid an error in non-prod envs
# This means for non-prod, the acm_cert_domain_name will be "modernisation-platform.service.justice.gov.uk"
# For production, this will be the actual route53 hosted zone name, which will be the same as the A record name, e.g. "apex.service.justice.gov.uk"
data "aws_route53_zone" "production_network_services" {
  provider     = aws.core-network-services
  name         = local.application_data.accounts[local.environment].acm_cert_domain_name # TODO: To be determined for production
  private_zone = false
}