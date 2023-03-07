resource "aws_route53_record" "tipstaff-app-record" {
  provider  = aws.core-vpc
  zone_id   = data.aws_route53_zone.inner.zone_id
  name      = "${local.application_data.accounts[local.environment].subdomain_name}.modernisation-platform.internal"
  type      = "CNAME"
  ttl       = 900
  records   = [aws_lb.tipstaff_dev_lb.dns_name]
}

resource "aws_acm_certificate" "tipstaff-app-cert" {
  domain_name       = local.application_data.accounts[local.environment].subdomain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
