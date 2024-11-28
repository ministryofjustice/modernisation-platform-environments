module "shield" {
  source   = "../../modules/shield_advanced"
  for_each = local.is-production ? { "build" = true } : {}
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name = local.application_name
  resources = {
    format("%s-alb", local.application_name) = {
      action = "block"
      arn    = module.lb_access_logs_enabled.load_balancer_arn
    }
  }
  waf_acl_rules = {
    example = {
      "action"    = "block",
      "name"      = "ddos-protection",
      "priority"  = 0,
      "threshold" = "250"
    }
  }
}
