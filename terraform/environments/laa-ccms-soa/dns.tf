#--Admin
resource "aws_route53_record" "admin" {
  zone_id = data.aws_route53_zone.network-services.zone_id
  name    = local.application_data.accounts[local.environment].admin_hostname
  type    = "A"
  alias {
    name                   = aws_lb.admin.dns_name
    zone_id                = aws_lb.admin.zone_id
    evaluate_target_health = false
  }
}

#--Managed
resource "aws_route53_record" "managed" {
  zone_id = data.aws_route53_zone.network-services.zone_id
  name    = local.application_data.accounts[local.environment].managed_hostname
  type    = "A"
  alias {
    name                   = aws_lb.managed.dns_name
    zone_id                = aws_lb.managed.zone_id
    evaluate_target_health = false
  }
}
