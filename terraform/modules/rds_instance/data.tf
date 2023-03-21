data "aws_caller_identity" "current" {}

data "aws_route53_zone" "internal" {
  provider = aws.core-vpc

  name         = "${var.business_unit}-${var.environment}.modernisation-platform.internal."
  private_zone = true
}

data "aws_route53_zone" "external" {
  provider = aws.core-vpc

  name         = "${var.business_unit}-${var.environment}.modernisation-platform.service.justice.gov.uk."
  private_zone = false
}