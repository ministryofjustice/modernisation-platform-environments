module "waf" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-waf?ref=v0.0.1"
  enable_ddos_protection = false
  ddos_rate_limit        = 5000
  block_non_uk_traffic   = false

  managed_rule_actions = {
    AWSManagedRulesKnownBadInputsRuleSet = false
    AWSManagedRulesCommonRuleSet         = false
    AWSManagedRulesSQLiRuleSet           = false
    AWSManagedRulesLinuxRuleSet          = false
    AWSManagedRulesAnonymousIpList       = false
    AWSManagedRulesBotControlRuleSet     = false
  }
  
  core_logging_account_id = local.environment_management.account_ids["core-logging-production"]

  application_name = local.application_name        
  tags             = local.tags


}
