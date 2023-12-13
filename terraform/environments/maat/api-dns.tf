######################################
# DNS Record for Load Balancer
######################################

#CHECK WITH VINCENT!!!!

resource "aws_route53_record" "maat_api_lb_a_record" {
  zone_id = data.external.dns_AwsHostedZoneId.result
  name    = "${var.pAppName}.${data.external.dns_AwsHostedZoneDomainName.result}"
  type    = "CNAME"
  ttl     = "60"

  records = [aws_lb.maat_api_ecs_lb.dns_name]

  # Optional comment
  set_identifier = "Domain CNAME record for External Application LoadBalancer"
}