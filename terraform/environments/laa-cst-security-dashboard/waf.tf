
module "waf" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-aws-waf?ref=a96a97c0cc64c14f1ee66b272e31101cce5aee61" # v2.0.0
  providers = {
    aws                        = aws
    aws.modernisation-platform = aws.modernisation-platform
  }
  enable_pagerduty_integration = true
  enable_ddos_protection       = true
  ddos_rate_limit              = 5000
  block_non_uk_traffic         = false
  associated_resource_arns     = []
  managed_rule_actions = {
    AWSManagedRulesKnownBadInputsRuleSet = true
    AWSManagedRulesCommonRuleSet         = true
    AWSManagedRulesSQLiRuleSet           = true
    AWSManagedRulesLinuxRuleSet          = false
    AWSManagedRulesAnonymousIpList       = false
    AWSManagedRulesBotControlRuleSet     = false
  }

  core_logging_account_id = local.environment_management.account_ids["core-logging-production"]

  application_name = local.application_name
  tags             = local.tags

  additional_managed_rules = [
    {
      name            = "AWSManagedRulesPHPRuleSet"
      vendor_name     = "AWS"
      override_action = "count"
      priority        = 1001
    },
    {
      name            = "AWSManagedRulesUnixRuleSet"
      vendor_name     = "AWS"
      override_action = "count"
      priority        = 1002
    }
  ]
}
