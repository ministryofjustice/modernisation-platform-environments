resource "aws_waf_ipset" "allow" {
  # name = "${upper(var.application_name)} Manual Allow Set"
  name = "${upper(local.application_name)} Manual Allow Set"

  # Ranges from https://github.com/ministryofjustice/laa-aws-infrastructure/blob/master/waf/wafv2_whitelist.template
  # disc_internet_pipeline, disc_dom1, moj_digital_wifi, petty_france_office365, petty_france_wifi, ark_internet, gateway_proxies

  dynamic "ip_set_descriptors" {
    for_each = local.ip_set_list
    content {
      type  = "IPV4"
      value = ip_set_descriptors.value
    }
  }
}

resource "aws_waf_ipset" "block" {
  # name = "${upper(var.application_name)} Manual Block Set"
  name = "${upper(local.application_name)} Manual Block Set"
}

resource "aws_waf_rule" "allow" {
  # name        = "${upper(var.application_name)} Manual Allow Rule"
  # metric_name = "${upper(var.application_name)}ManualAllowRule"
  name        = "${upper(local.application_name)} Manual Allow Rule"
  metric_name = "${upper(local.application_name)} ManualAllowRule"

  predicates {
    data_id = aws_waf_ipset.allow.id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_waf_rule" "block" {
  # name        = "${upper(var.application_name)} Manual Block Rule"
  # metric_name = "${upper(var.application_name)}ManualBlockRule"
  name        = "${upper(local.application_name)} Manual Block Rule"
  metric_name = "${upper(local.application_name)} ManualBlockRule"

  predicates {
    data_id = aws_waf_ipset.block.id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_wafv2_web_acl" "wafv2_acl" {
# name            = "${upper(var.application_name)} Whitelisting Requesters"
# metric_name     = "${upper(var.application_name)}WhitelistingRequesters"
name            = "${upper(local.application_name)} Whitelisting Requesters"
metric_name     = "${upper(local.application_name)} WhitelistingRequesters"
scope           = "CLOUDFRONT"

dynamic "default_action" {
  for_each = local.environment == "production" ? [1] : []
  content {
    allow {}
  }
}

visibility_config {
  cloudwatch_metrics_enabled = true
  metric_name                = "PortalWebRequests"
  sampled_requests_enabled   = true
}

rule {
    name     = "WhitelistInternalMoJAndPingdom"
    priority = 4
    action {
      type = "ALLOW"
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "PortalManualAllowRuleMetric"
      sampled_requests_enabled   = true
    }
    ip_set_reference_statement   =  aws_waf_ipset.arn
}

rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0

    override_action {
      none {}
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
      none {}
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
      none {}
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
      none {}
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

}

# tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}"
#     }
#   )




