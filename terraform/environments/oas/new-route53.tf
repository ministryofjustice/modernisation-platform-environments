######################################
### EC2 ROUTE53 RECORD
######################################
resource "aws_route53_record" "oas-app_new" {
  count    = contains(["test", "preproduction"], local.environment) ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.application_name}.${data.aws_route53_zone.external.name}"
  type     = "A"
  ttl      = 900
  records  = [aws_instance.oas_app_instance_new[0].private_ip]
}

######################################
### RDS Route53 Record
######################################
resource "aws_route53_record" "oas-rds-new" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "rds.${local.application_name}.${data.aws_route53_zone.external.name}"
  type     = "CNAME"
  ttl      = 60
  records  = [aws_db_instance.oas_rds_instance[0].address]
}
