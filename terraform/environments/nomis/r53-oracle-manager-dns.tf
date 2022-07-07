resource "aws_route53_record" "oracle-manager" {
  provider = aws.core-vpc
  count    = can(local.accounts[local.environment].database_oracle_manager) ? 1 : 0


  zone_id = data.aws_route53_zone.internal.zone_id
  name    = "${local.accounts[local.environment].database_oracle_manager.oms_hostname}.${local.application_name}.${data.aws_route53_zone.internal.name}"
  type    = "A"
  ttl     = "60"
  # we need a record for the OEM manager in FixnGo in order to avoid direct edits of hosts files on VMs. No way to look this IP up dynamically, so it must be hard-coded.
  #checkov:skip=CKV2_AWS_23: "Route53 A Record has Attached Resource"
  records = [local.accounts[local.environment].database_oracle_manager.oms_ip_address]
}