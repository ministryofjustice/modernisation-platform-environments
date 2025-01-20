module "mwaa_certificate" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  zone_id     = module.route53_zones.zone_ids[local.environment_configuration.route53_zone]
  domain_name = "airflow.${local.environment_configuration.route53_zone}"

  validation_method = "DNS"

  tags = local.tags
}
