locals {
  prototype_domain_name   = "ai-prototype.modernisation-platform.service.justice.gov.uk"
  prototype_bucket_prefix = "justice-eng-ai-prototypes"
}

resource "aws_acm_certificate" "prototypes" {
  provider                  = aws.us-east-1
  domain_name               = local.prototype_domain_name
  subject_alternative_names = ["*.${local.prototype_domain_name}"]
  validation_method         = "DNS"
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "prototype_certificate_validation" {
  provider = aws.core-network-services
  for_each = {
    for domain_validation_option in aws_acm_certificate.prototypes.domain_validation_options :
    domain_validation_option.domain_name => {
      name  = domain_validation_option.resource_record_name
      type  = domain_validation_option.resource_record_type
      value = domain_validation_option.resource_record_value
    }
  }

  zone_id         = data.aws_route53_zone.network-services.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.value]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "prototypes" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.prototypes.arn
  validation_record_fqdns = [for record in aws_route53_record.prototype_certificate_validation : record.fqdn]
}

module "shared-prototype-edge" {
  source = "./shared-prototype-edge"

  providers = {
    aws                       = aws
    aws.us_east_1             = aws.us-east-1
    aws.core_network_services = aws.core-network-services
  }

  configuration = {
    domain_name        = local.prototype_domain_name
    hosted_zone_id     = data.aws_route53_zone.network-services.zone_id
    certificate_arn    = aws_acm_certificate_validation.prototypes.certificate_arn
    bucket_prefix      = local.prototype_bucket_prefix
    allowed_ipv4_cidrs = toset(var.allowed_ingress_cidrs)
  }
  tags = local.tags
}