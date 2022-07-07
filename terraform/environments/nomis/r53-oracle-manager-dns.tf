data "aws_route53_zone" "internal" {
  provider = aws.core-vpc

  name         = "${local.business_unit}-${local.environment}.modernisation-platform.internal."
  private_zone = true
}

resource "aws_route53_record" "oracle-manager" {
  provider = aws.core-vpc
  for_each = local.accounts[local.environment].database_oracle_manager

  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "${each.oms_hostname.value}.${local.application_name}.${data.aws_route53_zone.internal.name}"
  type    = "A"
  ttl     = "60"
  records = [each.oms_ip_address.value]
}