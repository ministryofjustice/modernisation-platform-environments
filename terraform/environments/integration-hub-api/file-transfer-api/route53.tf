resource "aws_route53_record" "api_custom_domain" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.file_transfer.zone_id
  name    = local.acm_domains.api
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
