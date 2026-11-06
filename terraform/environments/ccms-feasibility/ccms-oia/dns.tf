resource "aws_route53_record" "opahub" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.opahub_name}-${local.env_label}"
  type     = "A"

  alias {
    name                   = module.alb_opahub.alb_dns_name
    zone_id                = module.alb_opahub.alb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "connector" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.connector_name}-${local.env_label}"
  type     = "A"

  alias {
    name                   = module.alb_connector.alb_dns_name
    zone_id                = module.alb_connector.alb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "adaptor" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.adaptor_name}-${local.env_label}"
  type     = "A"

  alias {
    name                   = module.alb_adaptor.alb_dns_name
    zone_id                = module.alb_adaptor.alb_zone_id
    evaluate_target_health = false
  }
}
