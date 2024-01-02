resource "aws_route53_record" "db_ec2_instance_internal" {
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_inner_zone_info.zone_id
  name     = var.db_type == "primary" ? "${var.env_name}-delius-db-${var.db_count_index}.delius.${var.account_config.route53_inner_zone_info.name}" : "${var.env_name}-delius-db-${var.db_count_index + 1}.delius.${var.account_config.route53_inner_zone_info.name}"
  type     = "CNAME"
  ttl      = 60
  records  = [aws_instance.db_ec2.private_dns]
}
