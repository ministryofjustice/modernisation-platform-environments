######################################
### EC2 ROUTE53 RECORD
######################################
resource "aws_route53_record" "oas-app_new" {
  count    = contains(["test", "preproduction"], local.environment) ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.application_name}.${data.aws_route53_zone.external.name}"
  type     = "A"

  alias {
    name                   = module.lb_access_logs_enabled.load_balancer.dns_name
    zone_id                = module.lb_access_logs_enabled.load_balancer.zone_id
    evaluate_target_health = true
  }
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

######################################
### Load Balancer Route53 Record
######################################
resource "aws_route53_record" "oas-lb" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0

  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.application_name}-lb.${data.aws_route53_zone.external.name}"
  type     = "A"

  alias {
    name                   = module.lb_access_logs_enabled.load_balancer.dns_name
    zone_id                = module.lb_access_logs_enabled.load_balancer.zone_id
    evaluate_target_health = true
  }
}
