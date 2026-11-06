resource "aws_route53_record" "admin" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.component_name}-admin-${local.env_label}"
  type     = "A"

  alias {
    name                   = module.nlb_admin.nlb_dns_name
    zone_id                = module.nlb_admin.nlb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "managed" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.component_name}-managed-${local.env_label}"
  type     = "A"

  alias {
    name                   = module.nlb_managed.nlb_dns_name
    zone_id                = module.nlb_managed.nlb_zone_id
    evaluate_target_health = false
  }
}
