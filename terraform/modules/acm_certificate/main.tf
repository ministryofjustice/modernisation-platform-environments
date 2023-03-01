resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = var.subject_alternate_names
  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    create_before_destroy = true
  }
}

# use core-network-services provider to validate top-level domain
resource "aws_route53_record" "validation_core_network_services" {
  provider = aws.core-network-services
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    } if var.validation[dvo.domain_name].account == "core-network-services"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.core_network_services[each.key].zone_id

  depends_on = [
    aws_acm_certificate.this
  ]
}

# use core-vpc provider to validate business-unit domain
resource "aws_route53_record" "validation_core_vpc" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    } if var.validation[dvo.domain_name].account == "core-vpc"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.core_vpc[each.key].zone_id

  depends_on = [
    aws_acm_certificate.this
  ]
}

# assume any other domains are defined in the current workspace
resource "aws_route53_record" "validation_self" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    } if var.validation[dvo.domain_name].account == "self"
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.self[each.key].zone_id

  depends_on = [
    aws_acm_certificate.this
  ]
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn
  validation_record_fqdns = [
    for record in merge(
      aws_route53_record.validation_core_network_services,
      aws_route53_record.validation_core_vpc,
      aws_route53_record.validation_self
    ) : record.fqdn
  ]
  depends_on = [
    aws_route53_record.validation_core_network_services,
    aws_route53_record.validation_core_vpc,
    aws_route53_record.validation_self
  ]
}
