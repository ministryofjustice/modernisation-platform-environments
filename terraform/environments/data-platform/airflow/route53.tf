resource "aws_route53_record" "airflow" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "airflow.${local.environment_configuration.route53_zone}"
  type    = "A"

  alias {
    name                   = module.mwaa_alb.dns_name
    zone_id                = module.mwaa_alb.zone_id
    evaluate_target_health = true
  }
}