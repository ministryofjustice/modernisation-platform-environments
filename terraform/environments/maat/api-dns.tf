######################################
# DNS Record for Load Balancer
######################################

resource "aws_route53_record" "maat_api_lb_a_record" {
  provider = aws.core-vpc
  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${local.application_name}-cd-api.${data.aws_route53_zone.external.name}"
  type    = "A"

  alias {
    name                   = aws_lb.maat_api_ecs_lb.dns_name
    zone_id                = aws_lb.maat_api_ecs_lb.zone_id
    evaluate_target_health = true
  }

  # records = [aws_lb.maat_api_ecs_lb.dns_name]

  # Domain A record for Internal Application LoadBalancer
}