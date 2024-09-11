module "shield" {
  source   = "../../modules/shield_advanced"
  for_each = local.is-production ? { "build" = true } : {}
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name = local.application_name
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

import {
  for_each = local.is-production ? { "build" = true } : {}
  id = "06cebb43-c961-44f0-81e5-27f94e2159d4/FMManagedWebACLV2-shield_advanced_auto_remediate-1649415294385/REGIONAL"
  to = module.shield["build"].aws_wafv2_web_acl.main
}