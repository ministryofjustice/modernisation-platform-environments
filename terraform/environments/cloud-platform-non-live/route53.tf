# Route53 hostzone
resource "aws_route53_zone" "cloud_platform_justice_gov_uk" {
  name = "cloud-platform.service.justice.gov.uk."
}

resource "aws_route53_record" "cloud_platform_justice_gov_uk_TXT" {
  zone_id = aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = aws_route53_zone.cloud_platform_justice_gov_uk.name
  type    = "TXT"
  ttl     = "300"
  records = ["google-site-verification=IorKX8xdhHmAEnI4O1LtGPgQwQiFtRJpPFABmzyCN1E"]
}