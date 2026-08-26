#--Admin
resource "aws_route53_record" "admin" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = local.application_data.accounts[local.environment].admin_hostname
  type     = "A"
  alias {
    name                   = aws_lb.admin.dns_name
    zone_id                = aws_lb.admin.zone_id
    evaluate_target_health = false
  }
}

#--Managed
resource "aws_route53_record" "managed" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = local.application_data.accounts[local.environment].managed_hostname
  type     = "A"
  alias {
    name                   = aws_lb.managed.dns_name
    zone_id                = aws_lb.managed.zone_id
    evaluate_target_health = false
  }
}

#--Validation
resource "aws_route53_record" "validation" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.soa.domain_validation_options : dvo.domain_name => {
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
