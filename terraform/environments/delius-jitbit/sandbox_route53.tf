resource "aws_route53_record" "external_sandbox" {
  count = local.is-development ? 1 : 0

  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = local.sandbox_app_url
  type    = "A"

  alias {
    name                   = aws_lb.external_sandbox[0].dns_name
    zone_id                = aws_lb.external_sandbox[0].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_sandbox_blue" {
  count = local.is-development ? 1 : 0

  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "blue-${local.sandbox_app_url}"
  type    = "A"

  alias {
    name                   = aws_lb.external_sandbox[0].dns_name
    zone_id                = aws_lb.external_sandbox[0].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "external_sandbox_green" {
  count = local.is-development ? 1 : 0

  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "green-${local.sandbox_app_url}"
  type    = "A"

  alias {
    name                   = aws_lb.external_sandbox[0].dns_name
    zone_id                = aws_lb.external_sandbox[0].zone_id
    evaluate_target_health = true
  }
}