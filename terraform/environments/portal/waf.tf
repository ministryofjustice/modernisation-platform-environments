resource "aws_wafv2_ip_set" "portal_whitelist" {
  name               = "portal_whitelist"
  description        = "List of Internal MOJ Addresses that are whitelisted. Comments above the relevant IPs shows where they arehttps://github.com/ministryofjustice/moj-ip-addresses/blob/master/moj-cidr-addresses.yml"
  scope              = "CLOUDFRONT"
  provider           = aws.us-east-1
  ip_address_version = "IPV4"
  addresses          = [for ip in split("\n", chomp(file("${path.module}/aws_waf_ipset.txt"))) : ip]
}

resource "aws_wafv2_web_acl" "wafv2_acl" {
  name     = "${upper(local.application_name)}-WebAcl"
  scope    = "CLOUDFRONT"
  provider = aws.us-east-1

  dynamic "default_action" {
    for_each = local.environment == "production" ? [1] : []
    content {
      allow {}
    }
  }

  dynamic "default_action" {
    for_each = local.environment != "production" ? [1] : []
    content {
      block {}
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
      allow {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "PortalManualAllowRuleMetric"
      sampled_requests_enabled   = true
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.portal_whitelist.arn
      }
    }
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
      }
    }
  }

  rule {
    name     = "AWSManagedRulesBotControl"
    priority = 3

    #the Cloudformation code has the OverrideAction: None: {} in https://github.com/ministryofjustice/laa-portal/blob/master/aws/wafv2/wafv2.template
    #however the LZ Development (and Production) console has the Action set to Override rule group action to count - so Action has been set to count
    override_action {
      count {}
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
      }
    }
  }
}