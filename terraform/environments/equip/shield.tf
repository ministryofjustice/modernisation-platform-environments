module "shield" {
  source   = "../../modules/shield_advanced"
  for_each = local.is-production ? { "build" = true } : {}
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name = local.application_name
  excluded_protections = ["aae73c82-0ce9-442a-89e4-13cab23f26e0"]
  resources = {
    citrix_alb = {
      action = "count"
      arn    = aws_lb.citrix_alb.arn
    }
  }
  waf_acl_rules = {
    example = {
      "action"    = "count",
      "name"      = "equip-count-rule",
      "priority"  = 0,
      "threshold" = "100"
    }
  }
}
