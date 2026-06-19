data "aws_route53_zone" "cluster_zone" {
  count = var.gateway_name == "default" ? 1 : 0
  name  = var.cluster_base_domain
}

resource "aws_acm_certificate" "cluster_wildcard" {
  count                     = var.gateway_name == "default" ? 1 : 0
  domain_name               = var.cluster_base_domain
  subject_alternative_names = ["*.${var.cluster_name}.${var.cluster_base_domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cluster_wildcard_validation" {
  for_each = var.gateway_name == "default" ? {
    for dvo in aws_acm_certificate.cluster_wildcard[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id         = data.aws_route53_zone.cluster_zone[0].zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cluster_wildcard" {
  count                   = var.gateway_name == "default" ? 1 : 0
  certificate_arn         = aws_acm_certificate.cluster_wildcard[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cluster_wildcard_validation : record.fqdn]
}
