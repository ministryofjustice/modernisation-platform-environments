#### This file can be used to store data specific to the member account ####
data "aws_route53_zone" "production_zone" {
  provider     = aws.core-network-services
  name         = "tribunals.gov.uk."
  private_zone = false
}