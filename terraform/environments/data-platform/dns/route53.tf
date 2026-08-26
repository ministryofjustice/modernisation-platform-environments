module "route53_zones" {
  for_each = local.environment_configuration.route53_zones

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git?ref=b4c9c820abdff9357747865f65131d1fa4128edc" # v6.4.0

  name    = each.key
  records = each.value.records
}
