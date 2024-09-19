# Retrieve the protection ID of the ingestion-lb protection, so it can be excluded
data "aws_shield_protection" "ingestion_lb" {
  resource_arn = aws_elb.ingestion_lb.arn
}

module "shield" {
  source   = "../../modules/shield_advanced"
  for_each = local.is-production ? { "build" = true } : {}
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name = local.application_name
  excluded_protections = [data.aws_shield_protection.ingestion_lb.id]
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
