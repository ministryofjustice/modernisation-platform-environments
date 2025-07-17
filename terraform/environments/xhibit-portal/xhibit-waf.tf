module "waf" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-waf?ref=v0.0.1"
  enable_ddos_protection = true
  ddos_rate_limit        = 3000
  block_non_uk_traffic   = true
  associated_resource_arns = [aws_lb.waf_lb.arn]

  managed_rule_actions = {
    AWSManagedRulesKnownBadInputsRuleSet = true
    AWSManagedRulesCommonRuleSet         = false
    AWSManagedRulesSQLiRuleSet           = true
    AWSManagedRulesLinuxRuleSet          = true
    AWSManagedRulesAnonymousIpList       = false
    AWSManagedRulesBotControlRuleSet     = false
  }
  
  core_logging_account_id = local.environment_management.account_ids["core-logging-production"]

  application_name = local.application_name        
  tags             = local.tags


}
