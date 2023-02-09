/*
ccms-ebs.laa-dev.modernisation-platform.service.justice.gov.uk
ccms-ebs.laa-test.modernisation-platform.service.justice.gov.uk
ccms-ebs.laa-preproduction.modernisation-platform.service.justice.gov.uk
ccms-ebs.laa-production.modernisation-platform.service.justice.gov.uk
*/

resource "aws_acm_certificate" "external" {
  domain_name               = "modernisation-platform.service.justice.gov.uk"
  validation_method         = "DNS"
  subject_alternative_names = ["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]

  tags = merge(local.tags,
    { Environment = local.environment }
  )

  lifecycle {
    create_before_destroy = true
  }
}
/*
resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation : record.fqdn]
}
*/
resource "aws_route53_record" "external_validation" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.external.zone_id
}
