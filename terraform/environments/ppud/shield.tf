module "shield" {
  source   = "../../modules/shield_advanced"
  for_each = local.is-production ? { "build" = true } : {}
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name = local.application_name
  resources = {
    WAM-ALB = {
      action = "count"
      arn    = aws_lb.WAM-ALB.arn
    }
  }
  waf_acl_rules = {
    example = {
      "action"    = "count",
      "name"      = "DDoSprotection",
      "priority"  = 0,
      "threshold" = "150"
    }
  }
}

import {
  for_each = local.is-production ? { "build" = true } : {}
  id = "60a72081-57ea-4a38-b04a-778796012304/FMManagedWebACLV2-shield_advanced_auto_remediate-1649415357278/REGIONAL"
  to = module.shield["build"].aws_wafv2_web_acl.main
}
