######################################
### EC2 ROUTE53 RECORD
######################################
resource "aws_route53_record" "oas-app" {
  count    = local.environment == "preproduction" ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "${local.application_name}.${data.aws_route53_zone.external.name}"
  type     = "A"
  ttl      = 900
  records  = [aws_instance.oas_app_instance_new[0].private_ip]
}
