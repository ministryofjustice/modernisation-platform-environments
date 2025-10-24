# PROD DNS Zones

data "aws_route53_zone" "laa" {
  provider     = aws.core-network-services
  name         = "laa.service.justice.gov.uk"
  private_zone = false
}