module "acm_api" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.1"

  domain_name             = local.api_domain
  validation_method       = "DNS"
  key_algorithm           = "RSA_2048"
  create_route53_records  = false
  validation_record_fqdns = module.acm_api_validation.validation_route53_record_fqdns
}

# The validation records live in the core-network-services account, which owns the zone.
module "acm_api_validation" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.1"

  providers = { aws = aws.core-network-services }

  create_certificate                        = false
  create_route53_records_only               = true
  validation_method                         = "DNS"
  distinct_domain_names                     = [local.api_domain]
  zone_id                                   = data.aws_route53_zone.events.zone_id
  dns_ttl                                   = 60
  validation_allow_overwrite_records        = true
  acm_certificate_domain_validation_options = module.acm_api.acm_certificate_domain_validation_options
}

resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = local.api_domain

  domain_name_configuration {
    certificate_arn = module.acm_api.acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = local.tags
}

resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = module.api_gateway.api_id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = aws_apigatewayv2_stage.default.name
}

resource "aws_route53_record" "api" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.events.zone_id
  name    = local.api_domain
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
