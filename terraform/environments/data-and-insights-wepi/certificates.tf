resource "aws_acm_certificate" "redshift_cert" {
  domain_name       = data.aws_route53_zone.inner.name
  validation_method = "DNS"

  subject_alternative_names = [
    format("redshift.%s.%s", local.application_name, data.aws_route53_zone.inner.name),
    aws_redshift_cluster.wepi_redshift_cluster.dns_name
  ]

  tags = merge(local.tags,
    { Name = lower(format("redshift.%s.%s", local.application_name, data.aws_route53_zone.inner.name)) }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "redshift_cert" {
  certificate_arn         = aws_acm_certificate.redshift_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.redshift_cert_validation : record.fqdn]
  timeouts {
    create = "15m"
  }
}

resource "aws_route53_record" "redshift_cert_validation" {
  provider = aws.core-network-services
  for_each = {
    for dvo in aws_acm_certificate.redshift_cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.network-services.zone_id
}
