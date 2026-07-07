resource "aws_acm_certificate" "external" {
  validation_method = "DNS"
  domain_name       = "${local.component_name}-${local.env_label}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.core-vpc

  for_each = {
    for dvo in local.cert_opts : dvo.domain_name => {
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
  zone_id         = local.cert_zone_id
}

resource "aws_acm_certificate_validation" "external" {
  depends_on              = [aws_route53_record.cert_validation]
  certificate_arn         = local.cert_arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}
