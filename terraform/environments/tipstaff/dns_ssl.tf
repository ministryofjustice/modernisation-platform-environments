resource "aws_route53_record" "tipstaff_app_direct_traffic" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.inner.zone_id
  name     = "${local.application_data.accounts[local.environment].subdomain_name}.modernisation-platform.internal"
  type     = "CNAME"
  ttl      = 900
  records  = [aws_lb.tipstaff_dev_lb.dns_name]
}

resource "aws_acm_certificate" "tipstaff_app_cert" {
  domain_name       = "tipstaff-dev.modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation_subdomain_tipstaff" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.tipstaff_app_cert.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "tipstaff_lb_cert_validation" {
  provider = aws.core-network-services
  certificate_arn         = aws_acm_certificate.tipstaff_app_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.external_validation_subdomain_tipstaff : record.fqdn]
}
