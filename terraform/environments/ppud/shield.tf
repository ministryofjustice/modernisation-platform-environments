module "shield" {
  source   = "../../modules/shield_advanced"
  for_each = local.is-production ? { "build" = true } : {}
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name = local.application_name
  resources = {
    WAM-ALB = {
      action = "block"
      arn    = aws_lb.WAM-ALB.arn
    }
  }
  waf_acl_rules = {
    example = {
      "action"    = "block",
      "name"      = "DDoSprotection",
      "priority"  = 0,
      "threshold" = "2000"
    }
  }
}
