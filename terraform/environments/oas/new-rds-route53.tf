######################################
### RDS Route53 Record
######################################
resource "aws_route53_record" "oas-rds-new" {
  count = local.environment == "preproduction" ? 1 : 0

  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "rds.${local.application_name}.${data.aws_route53_zone.external.name}"
  type     = "CNAME"
  ttl      = 60
  records  = [aws_db_instance.oas_rds_instance[0].address]
}