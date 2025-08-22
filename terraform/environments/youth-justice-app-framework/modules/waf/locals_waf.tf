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
      priority = 4
      managed_rule_group_statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        rule_action_override = [
          {
            name = "SizeRestrictions_QUERYSTRING"
            action_to_use = {
              count = {}
            }
          },
          {
            name = "SizeRestrictions_BODY"
            action_to_use = {
              count = {}
            }
          },
          {
            name = "GenericRFI_QUERYARGUMENTS"
            action_to_use = {
              count = {}
            }
          },
          {
            name = "GenericRFI_BODY"
            action_to_use = {
              count = {}
            }
          },
          {
            name = "GenericRFI_URIPATH"
            action_to_use = {
              count = {}
            }
          },
          {
            name = "CrossSiteScripting_BODY"
            action_to_use = {
              count = {}
            }
          },
          {
            name = "CrossSiteScripting_COOKIE"
            action_to_use = {
              count = {}
            }
          }
        ]
      }
    },
    {
      name     = "AWSManagedRulesAdminProtectionRuleSet"
      priority = 7
      managed_rule_group_statement = {
        name        = "AWSManagedRulesAdminProtectionRuleSet"
        vendor_name = "AWS"
        rule_action_override = [
          {
            name = "AdminProtection_URIPATH"
            action_to_use = {
              count = {}
            }
          }
        ]
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
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 10
      managed_rule_group_statement = {
        name = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    },
    {
      name     = "AWSManagedRulesAmazonIpReputationList"
      priority = 6
      managed_rule_group_statement = {
        name = "AWSManagedRulesAmazonIpReputationList"
      }
    }
  ]
}
