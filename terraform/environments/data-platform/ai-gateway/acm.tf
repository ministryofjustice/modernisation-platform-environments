### TODO: Replace with module if possible.

resource "aws_acm_certificate" "ai_gateway" {
  domain_name               = local.environment_configuration.ai_gateway_hostname
  subject_alternative_names = ["*.${local.environment_configuration.ai_gateway_hostname}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "ai_gateway_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ai_gateway.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.ai_gateway.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 300
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "ai_gateway" {
  certificate_arn         = aws_acm_certificate.ai_gateway.arn
  validation_record_fqdns = [for record in aws_route53_record.ai_gateway_cert_validation : record.fqdn]
}

data "aws_route53_zone" "ai_gateway" {
  name         = "${local.environment_configuration.ai_gateway_hostname}."
  private_zone = false
}
