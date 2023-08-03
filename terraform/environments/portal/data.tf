data "aws_route53_zone" "portal-dev-private" {
  provider = aws.core-network-services

  name         = "aws.dev.legalservices.gov.uk."
  private_zone = true
}



