#### This file can be used to store data specific to the member account ####
data "aws_route53_zone" "laa-finance" {
  provider = aws.core-network-services

  name         = "laa-finance-data.service.justice.gov.uk"
  private_zone = false
}