data "aws_caller_identity" "current" {}

data "aws_route53_zone" "rds_dns_entry" {
  provider = aws.core-vpc

  name         = "${var.business_unit}-${var.environment}.modernisation-platform.internal."
  private_zone = true
}