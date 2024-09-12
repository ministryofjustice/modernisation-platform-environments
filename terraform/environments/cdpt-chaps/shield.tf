module "shield" {
  source   = "../../modules/shield_advanced"
  for_each = local.is-production ? { "build" = true } : {}
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name = local.application_name
  resources = {
    format("%s-alb", local.application_name) = {
      action = "count"
      arn    = module.lb_access_logs_enabled.load_balancer_arn
    }
  }
  waf_acl_rules = {
    example = {
      "action"    = "count",
      "name"      = "ddos-protection",
      "priority"  = 0,
      "threshold" = "250"
    }
  }
}

import {
  for_each = local.is-production ? { "build" = true } : {}
  id = "10320dab-b3d2-426f-a02c-4a4a6a554be0/FMManagedWebACLV2-shield_advanced_auto_remediate-1700749032578/REGIONAL"
  to = module.shield["build"].aws_wafv2_web_acl.main
}
