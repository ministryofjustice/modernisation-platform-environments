data "aws_acm_certificate" "wildcard" {
  domain      = "*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  statuses    = ["ISSUED"]
  most_recent = true
}
