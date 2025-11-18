provider "aws" {
  region = "eu-west-2"
}

resource "aws_wafv2_web_acl" "core_rule_set_acl" {
  name        = "core-rule-set-web-acl"
  description = "AWS WAF ACL using the AWS Managed Core Rule Set"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "coreRuleSetWebACL"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "coreRuleSet"
      sampled_requests_enabled   = true
    }
  }
}
