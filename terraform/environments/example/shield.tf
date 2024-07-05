module "shield" {
  source = "../../modules/shield_advanced"
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name     = local.application_name
  excluded_protections = local.application_data.accounts[local.environment].excluded_protections
  resources = {
    certificate_lb = {
      arn = aws_lb.certificate_example_lb.arn
    }
    public_lb = {
      action = "count",
      arn    = aws_lb.external.arn
    }
  }
  waf_acl_rules = {
    example = {
      "action"    = "count",
      "name"      = "example-count-rule",
      "priority"  = 0,
      "threshold" = "1000"
    }
  }
}
