resource "aws_wafv2_web_acl" "wafv2_acl" {
name            = "${upper(var.application_name)} Whitelisting Requesters"
metric_name     = "${upper(var.application_name)}WhitelistingRequesters"
scope           = "CLOUDFRONT"
default_action {
    allow {}
}

rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0

    override_action {
      None {}
    }

     visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleMetric"
      sampled_requests_enabled   = true
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "GenericRFI_QUERYARGUMENTS"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "CrossSiteScripting_BODY"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "CrossSiteScripting_COOKIE"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "SizeRestrictions_BODY"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "GenericRFI_BODY"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "CrossSiteScripting_QUERYARGUMENTS"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "NoUserAgent_HEADER"
        }

      }
    }
 }

rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1

    override_action {
      None {}
    }

     visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleMetric"
      sampled_requests_enabled   = true
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"

        # rule_action_override {
        #   action_to_use {
        #     count {}
        #   }

        #   name = ""
        # }
      }
    }
 }

rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 2

    override_action {
      None {}
    }

     visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationListMetric"
      sampled_requests_enabled   = true
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"

        # rule_action_override {
        #   action_to_use {
        #     count {}
        #   }

        #   name = ""
        # }
      }
    }
 }

rule {
    name     = "AWSManagedRulesBotControl"
    priority = 3

    override_action {
      None {}
    }

     visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesBotControlMetric"
      sampled_requests_enabled   = true
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"

        # rule_action_override {
        #   action_to_use {
        #     count {}
        #   }

        #   name = ""
        # }
      }
    }
 }

rule {
    name     = "WhitelistInternalMoJAndPingdom"
    priority = 4

    action {
      Allow {}
    }

     visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "PortalManualAllowRuleMetric"
      sampled_requests_enabled   = true
    }

    statement {
      IPSetReferenceStatement {
        # ???Arn: !ImportValue common-wafv2-ipset-whitelist Cloudformation code line 37
        # https://github.com/ministryofjustice/laa-portal/blob/master/aws/wafv2/wafv2.template
      }
    }
 }

tags = merge(
    local.tags,
    {
      Name = "${local.application_name}"
    }
  )

}



