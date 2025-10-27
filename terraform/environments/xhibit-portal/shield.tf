# Retrieve the protection ID of the ingestion-lb protection, so it can be excluded
locals {
  excluded_resource_arns = [aws_elb.ingestion_lb.arn, aws_lb.waf_lb.arn, aws_lb.prtg_lb.arn]
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
  excluded_protections = [for e in data.aws_shield_protection.excluded : e.id]
  resources = {
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
