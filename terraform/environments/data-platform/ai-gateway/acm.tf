data "aws_route53_zone" "ai_gateway" {
  name         = "${local.environment_configuration.ai_gateway_hostname}."
  private_zone = false
}

module "acm_ai_gateway" {
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.0"

  domain_name               = local.environment_configuration.ai_gateway_hostname
  zone_id                   = data.aws_route53_zone.ai_gateway.zone_id
  subject_alternative_names = ["*.${local.environment_configuration.ai_gateway_hostname}"]
  validation_method         = "DNS"
  wait_for_validation       = true
}
