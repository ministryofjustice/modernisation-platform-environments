resource "aws_route53_record" "database" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.database_hostname}.${data.aws_route53_zone.external.name}"
  type     = "A"
  ttl      = 900
  records  = [aws_instance.database.private_ip]
}

# Note that the hostname for CM is cwa-app2
resource "aws_route53_record" "concurrent_manager" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.cm_hostname}.${data.aws_route53_zone.external.name}"
  type     = "A"
  ttl      = 900
  records  = [aws_instance.concurrent_manager.private_ip]
}

resource "aws_route53_record" "app1" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.appserver1_hostname}.${data.aws_route53_zone.external.name}"
  type     = "A"
  ttl      = 900
  records  = [aws_instance.app1.private_ip]
}

# Note that this app2 referes to Application Server 2, not CM
resource "aws_route53_record" "app2" {
  count    = contains(["development", "test"], local.environment) ? 0 : 1
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.appserver2_hostname}.${data.aws_route53_zone.external.name}"
  type     = "A"
  ttl      = 900
  records  = [aws_instance.app2[0].private_ip]
}

# Domain A record for ALB
resource "aws_route53_record" "external" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.application_name_short}.${data.aws_route53_zone.external.name}" # cwa.dev.legalservices.gov.uk
  type     = "A"

  alias {
    name                   = aws_lb.external.dns_name
    zone_id                = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}