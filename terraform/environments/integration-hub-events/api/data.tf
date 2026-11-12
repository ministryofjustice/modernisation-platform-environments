#### This file can be used to store data specific to the member account ####

data "aws_route53_zone" "events_parent" {
  provider = aws.core-network-services

  name         = "events-platform.service.justice.gov.uk."
  private_zone = false
}

data "aws_route53_zone" "events" {
  provider = aws.core-network-services

  name         = local.is-production ? "events-platform.service.justice.gov.uk." : "${local.environment}.events-platform.service.justice.gov.uk."
  private_zone = false
}
