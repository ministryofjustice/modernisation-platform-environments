
module "waf" {
  source                   = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-aws-waf"
  enable_pagerduty_integration = true
  enable_ddos_protection = true
  ddos_rate_limit        = 5000
  block_non_uk_traffic   = true
  associated_resource_arns = [aws_lb.cst.arn]
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
  },
  {
    name        = "AWSManagedRulesUnixRuleSet"
    vendor_name = "AWS"
    override_action = "count"
  }
]
}
