module "shield" {
  source   = "../../modules/shield_advanced"
  for_each = local.is-production ? { "build" = true } : {}
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name     = local.application_name
  excluded_protections = ["aec0eb6a-62b1-4433-a854-77fb8b275db5"]
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
