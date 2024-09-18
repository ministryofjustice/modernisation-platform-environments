module "shield" {
  source   = "../../modules/shield_advanced"
  for_each = local.is-production ? { "build" = true } : {}
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name = local.application_name
  resources = {
    prtg_lb = {
      action = "block"
      arn    = aws_lb.prtg_lb.arn
    }
    waf_lb = {
      action = "block"
      arn    = aws_lb.waf_lb.arn
    }
  }
  waf_acl_rules = {
    example = {
      "action"    = "block",
      "name"      = "Shield-Block",
      "priority"  = 0,
      "threshold" = "1000"
    }
  }
}

import {
  for_each = local.is-production ? { "build" = true } : {}
  id       = "8fef055b-19dd-49f8-8056-212c928d0793/FMManagedWebACLV2-shield_advanced_auto_remediate-1654790638664/REGIONAL"
  to       = module.shield["build"].aws_wafv2_web_acl.main
}
