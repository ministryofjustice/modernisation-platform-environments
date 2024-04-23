resource "aws_route53_record" "db_ec2_instance_internal" {
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_inner_zone_info.zone_id
  name     = var.db_type == "primary" ? "delius-${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-${var.db_count_index}.${var.account_info.application_name}.${var.account_config.route53_inner_zone_info.name}" : "delius-${var.account_info.application_name}-${var.env_name}-${var.db_suffix}-${var.db_count_index + 1}.${var.account_info.application_name}.${var.account_config.route53_inner_zone_info.name}"
  type     = "CNAME"
  ttl      = 60
  records  = [module.instance.aws_instance.private_dns]
}
