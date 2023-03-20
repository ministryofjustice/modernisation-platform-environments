resource "aws_route53_record" "route53_record_app_lb" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "oem.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"

  alias {
    name                   = aws_lb.oem_app.dns_name
    zone_id                = aws_lb.oem_app.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "route53_record_app_lb_internal" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "oem-internal.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"

  alias {
    name                   = aws_lb.oem_app_internal.dns_name
    zone_id                = aws_lb.oem_app_internal.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "route53_record_app" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${var.networking[0].application}-app.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"
  ttl      = "300"
  records  = [aws_instance.oem_app.private_ip]
}
resource "aws_route53_record" "route53_record_db" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${var.networking[0].application}-db.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"
  ttl      = "300"
  records  = [aws_instance.oem_db.private_ip]
}
