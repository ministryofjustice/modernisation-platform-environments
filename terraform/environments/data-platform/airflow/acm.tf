module "acm_airflow" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-acm.git?ref=5d113fa07675fc42237907a621b68ac97109043e" # v6.3.0

  domain_name         = "airflow.${local.environment_configuration.route53_zone}"
  zone_id             = data.aws_route53_zone.main.zone_id
  validation_method   = "DNS"
  wait_for_validation = true

  tags = local.tags
}
