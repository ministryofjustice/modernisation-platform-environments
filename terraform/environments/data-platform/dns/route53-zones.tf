module "zone" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git?ref=b4c9c820abdff9357747865f65131d1fa4128edc" # v6.4.0

  name    = local.environment_configuration.route53_zone_name
  records = local.environment_configuration.route53_records
}
