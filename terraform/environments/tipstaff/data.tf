data "aws_route53_zone" "application_zone" {
  provider     = aws.core-network-services
  name         = "tipstaff.service.justice.gov.uk."
  private_zone = false
}
