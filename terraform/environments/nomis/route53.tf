#------------------------------------------------------------------------------
# Internal Zone
#------------------------------------------------------------------------------
data "aws_route53_zone" "internal" {
  provider = aws.core-vpc

  name         = "${local.vpc_name}-${local.environment}.modernisation-platform.internal."
  private_zone = true
}

resource "aws_route53_record" "database" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "database.${local.application_name}.${local.vpc_name}-${local.environment}.modernisation-platform.internal"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.db_server.private_ip]
}

#------------------------------------------------------------------------------
# External Zone
#------------------------------------------------------------------------------
data "aws_route53_zone" "external" {
  provider = aws.core-vpc

  name         = "${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk."
  private_zone = true
}

resource "aws_route53_record" "loadbalancer" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${local.application_name}.${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.external.dns_name
    zone_id                = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}