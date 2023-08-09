#### This file can be used to store data specific to the member account ####
data "aws_route53_zone" "application_zone" {
  provider     = aws.core-network-services
  name         = "neutral-citation-allocation-system.service.justice.gov.uk."
  private_zone = false
}
