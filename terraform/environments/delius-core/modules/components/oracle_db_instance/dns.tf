resource "aws_route53_record" "db_ec2_instance_internal" {
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_inner_zone.zone_id
  name     = var.db_type == "primary" ? "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-${var.db_count_index}.${var.account_config.route53_inner_zone.name}" : "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-${var.db_count_index + 1}.${var.account_config.route53_inner_zone.name}"
  type     = "CNAME"
  ttl      = 60
  records  = [module.instance.aws_instance.private_dns]
}

resource "aws_route53_record" "db_ec2_instance_public" {
  #checkov:skip=CKV2_AWS_23:Not recognising that record is referencing a valid IP
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_external_zone.zone_id
  name     = var.db_type == "primary" ? "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-${var.db_count_index}.${var.account_config.dns_suffix}" : "${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-${var.db_count_index + 1}.${var.account_config.dns_suffix}"
  type     = "A"
  ttl      = 60
  records  = [module.instance.aws_instance.private_ip]
}
