# Exclude WAM ALB from shield
locals {
  # excluded_resource_arns = local.is-development || local.is-preproduction ? [aws_lb.WAM-ALB.arn] : []
  excluded_resource_arns = local.is-development ? [aws_lb.WAM-ALB.arn] : []
}

data "aws_shield_protection" "excluded" {
  for_each     = toset(local.excluded_resource_arns)
  resource_arn = each.key
}

module "shield" {
  source   = "../../modules/shield_advanced"
  for_each = local.is-production ? { "build" = true } : {}
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name     = local.application_name
  #excluded_protections = local.is-development || local.is-preproduction ? [for e in data.aws_shield_protection.excluded : e.id] : []
  #resources = local.is-development || local.is-preproduction ? {} : {
  excluded_protections = local.is-development ? [for e in data.aws_shield_protection.excluded : e.id] : []
  resources = local.is-development ? {} : {
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