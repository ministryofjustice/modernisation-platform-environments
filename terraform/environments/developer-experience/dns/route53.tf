module "route53_zones" {
  for_each = local.environment_configuration.route53_zones

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git?ref=883f987d6bb328c09bd4dfc5a04024534b371d59" # v6.5.1

  name    = each.key
  records = each.value.records
}
