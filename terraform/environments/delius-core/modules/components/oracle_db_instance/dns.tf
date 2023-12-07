resource "aws_route53_record" "db_ec2_instance" {
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_inner_zone_info.zone_id
  name     = var.db_type == "primary" ? "delius-${var.env_name}-db-${var.db_count_index}.${var.account_config.route53_inner_zone_info.name}" : "delius-${var.env_name}-db-${var.db_count_index + 1}.${var.account_config.route53_inner_zone_info.name}"
  type     = "CNAME"
  ttl      = 300
  records  = [aws_instance.db_ec2.private_dns]
}