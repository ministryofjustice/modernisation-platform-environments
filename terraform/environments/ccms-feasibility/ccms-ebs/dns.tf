resource "aws_route53_record" "ebsapps" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.component_name}-${local.env_label}"
  type     = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ebsdb" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.inner.zone_id
  name     = "${local.component_name}-db-${local.env_label}"
  type     = "A"
  ttl      = 300
  records  = [module.oracle_ebs_db.private_ip]
}

resource "aws_route53_record" "ebsapps_instance" {
  count    = 2
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.inner.zone_id
  name     = "${local.component_name}-apps${count.index + 1}-${local.env_label}"
  type     = "A"
  ttl      = 300
  records  = [module.oracle_ebs_apps[count.index].private_ip]
}
