locals {
  prototype_edge_enabled = local.is-production || local.is-development
  prototype_domain_name  = local.is-production ? "ai-builder.modernisation-platform.service.justice.gov.uk" : "ai-builder-dev.modernisation-platform.service.justice.gov.uk"
  prototype_name_prefix  = "justice-eng-ai-prototypes"

  # Reuse the stable validation CNAME already managed by web-ui.
  prototype_validation_records = local.prototype_edge_enabled ? {
    (local.prototype_domain_name) = one([
      for option in aws_acm_certificate.prototypes[0].domain_validation_options : option
      if option.domain_name == local.prototype_domain_name
    ])
  } : {}
}

resource "aws_acm_certificate" "prototypes" {
  count = local.prototype_edge_enabled ? 1 : 0

  provider                  = aws.us-east-1
  domain_name               = local.prototype_domain_name
  subject_alternative_names = ["*.${local.prototype_domain_name}"]
  validation_method         = "DNS"
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "prototype_origin" {
  count = local.prototype_edge_enabled ? 1 : 0

  domain_name               = local.prototype_domain_name
  subject_alternative_names = ["*.${local.prototype_domain_name}"]
  validation_method         = "DNS"
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "prototypes" {
  count = local.prototype_edge_enabled ? 1 : 0

  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.prototypes[0].arn
  validation_record_fqdns = [for option in values(local.prototype_validation_records) : option.resource_record_name]
}

resource "aws_acm_certificate_validation" "prototype_origin" {
  count = local.prototype_edge_enabled ? 1 : 0

  certificate_arn         = aws_acm_certificate.prototype_origin[0].arn
  validation_record_fqdns = [for option in values(local.prototype_validation_records) : option.resource_record_name]
}

module "shared-prototype-edge" {
  count  = local.prototype_edge_enabled ? 1 : 0
  source = "./shared-prototype-edge"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us-east-1
  }

  configuration = {
    domain_name            = local.prototype_domain_name
    hosted_zone_id         = data.aws_route53_zone.ai_builder[0].zone_id
    certificate_arn        = aws_acm_certificate_validation.prototypes[0].certificate_arn
    origin_certificate_arn = aws_acm_certificate_validation.prototype_origin[0].certificate_arn
    name_prefix            = local.prototype_name_prefix
    vpc_id                 = data.aws_vpc.prototype[0].id
    public_subnet_ids      = data.aws_subnets.public_prototypes[0].ids
    allowed_ipv4_cidrs     = toset(var.allowed_ingress_cidrs)
  }
  tags = local.tags
}

output "shared_prototype_edge" {
  description = "Shared CloudFront, WAF and public ALB details for prototype routing; populated in development and production."
  value       = local.prototype_edge_enabled ? module.shared-prototype-edge[0].hosting : null
}
