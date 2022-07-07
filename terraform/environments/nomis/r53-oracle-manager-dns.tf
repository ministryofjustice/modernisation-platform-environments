resource "aws_route53_record" "oracle-manager" {
  provider = aws.core-vpc
  count = can(local.accounts[local.environment].database_oracle_manager) ? 1 : 0

  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "${local.accounts[local.environment].database_oracle_manager.oms_hostname}.${local.application_name}.${data.aws_route53_zone.internal.name}"
  type    = "A"
  ttl     = "60"
  records = [local.accounts[local.environment].database_oracle_manager.oms_ip_address]
}