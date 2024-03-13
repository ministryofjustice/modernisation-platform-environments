#### This file can be used to store data specific to the member account ####
data "aws_route53_zone" "application_zone" {
  provider     = aws.core-network-services
  name         = "integrated-fraud-system.service.justice.gov.uk"
  private_zone = false
}
