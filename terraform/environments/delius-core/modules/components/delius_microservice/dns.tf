resource "aws_route53_record" "service" {
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_inner_zone_info.zone_id
  name     = "${{var.name}.service.${var.account_config.dns_suffix}"
  type     = "CNAME"
  ttl      = 60
  records  = [aws_instance.db_ec2.private_dns]
}
