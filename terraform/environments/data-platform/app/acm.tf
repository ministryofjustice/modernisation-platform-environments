module "acm_app" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-acm.git?ref=5d113fa07675fc42237907a621b68ac97109043e" # v6.3.0

  domain_name         = local.environment_configuration.app_hostname
  zone_id             = data.aws_route53_zone.app.zone_id
  validation_method   = "DNS"
  wait_for_validation = true
}
