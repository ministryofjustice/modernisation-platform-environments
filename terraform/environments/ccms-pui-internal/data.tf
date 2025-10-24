# PROD DNS Zones
data "aws_route53_zone" "legalservices" {
  provider     = aws.core-network-services
  name         = "legalservices.gov.uk"
  private_zone = false
}