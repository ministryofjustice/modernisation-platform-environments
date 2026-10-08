locals {
  prototype_domain_name   = "ai-prototype.modernisation-platform.service.justice.gov.uk"
  prototype_bucket_prefix = "justice-eng-ai-prototypes"
}

data "aws_route53_zone" "prototypes" {
  name         = "${local.prototype_domain_name}."
  private_zone = false
}

data "aws_acm_certificate" "prototypes" {
  provider    = aws.us-east-1
  domain      = local.prototype_domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

module "shared-prototype-edge" {
  source = "./shared-prototype-edge"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us-east-1
  }

  configuration = {
    domain_name        = local.prototype_domain_name
    hosted_zone_id     = data.aws_route53_zone.prototypes.zone_id
    certificate_arn    = data.aws_acm_certificate.prototypes.arn
    bucket_prefix      = local.prototype_bucket_prefix
    allowed_ipv4_cidrs = toset(var.allowed_ingress_cidrs)
  }
  tags = local.tags
}