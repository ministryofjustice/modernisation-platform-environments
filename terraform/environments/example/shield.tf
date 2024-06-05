module "shield" {
  source = "../../modules/shield_advanced"
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name     = local.application_name
  excluded_protections = local.application_data.accounts[local.environment].excluded_protections
  monitored_resources = {
    public_lb      = aws_lb.external.arn,
    certificate_lb = aws_lb.certificate_example_lb.arn
  }
  waf_acl_rules = {
    example = {
      "action" = "count",
      "name" = "example-count-rule",
      "priority" = 0,
      "threshold" = "1000"
    }
  }
}
