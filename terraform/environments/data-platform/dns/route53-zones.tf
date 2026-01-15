module "zone" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git?ref=6c5c0587f16701e8050d14d20b39d823534eec9a" # v6.1.1

  name    = local.environment_configuration.route53_zone_name
  records = local.environment_configuration.route53_records
}
