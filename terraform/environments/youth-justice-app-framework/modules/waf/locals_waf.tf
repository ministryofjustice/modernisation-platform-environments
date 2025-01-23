locals {
  # Default WAF rules
  default_waf_rules = [
    {
      name     = "AWSManagedRulesBotControlRuleSet"
      priority = 5
      managed_rule_group_statement = {
        name = "AWSManagedRulesBotControlRuleSet"
      }
    },
    {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 6
      managed_rule_group_statement = {
        name = "AWSManagedRulesCommonRuleSet"
      }
    },
    {
      name     = "AWSManagedRulesAdminProtectionRuleSet"
      priority = 7
      managed_rule_group_statement = {
        name = "AWSManagedRulesAdminProtectionRuleSet"
      }
    },
    {
      name     = "AWSManagedRulesLinuxRuleSet"
      priority = 8
      managed_rule_group_statement = {
        name = "AWSManagedRulesLinuxRuleSet"
      }
    },
    {
      name     = "AWSManagedRulesWindowsRuleSet"
      priority = 9
      managed_rule_group_statement = {
        name = "AWSManagedRulesWindowsRuleSet"
      }
    },
    {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 10
      managed_rule_group_statement = {
        name = "AWSManagedRulesKnownBadInputsRuleSet"
      }

    },
    {
      name     = "AWSManagedRulesAmazonIpReputationList"
      priority = 4
      managed_rule_group_statement = {
        name = "AWSManagedRulesAmazonIpReputationList"
      }
    }
  ]
}
