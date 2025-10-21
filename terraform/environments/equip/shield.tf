module "shield" {
  source   = "../../modules/shield_advanced_v6"
  for_each = local.is-production ? { "build" = true } : {}
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name = local.application_name
  resources = {
    citrix_alb = {
      action = "block"
      arn    = aws_lb.citrix_alb.arn
    }
  }
  waf_acl_rules = {
    example = {
      "action"    = "block",
      "name"      = "equip-count-rule",
      "priority"  = 0,
      "threshold" = "1000"
    }
  }
}
