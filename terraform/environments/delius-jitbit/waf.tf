resource "aws_wafv2_web_acl" "this" {
  name        = "${local.application_name}-acl"
  description = "Web ACL for ${local.application_name}"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      # Dont do anything but count requests that match the rules in the ruleset
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${local.application_name}-common-ruleset"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      # Dont do anything but count requests that match the rules in the ruleset
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${local.application_name}-SQLi-ruleset"
      sampled_requests_enabled   = false
    }
  }

  tags = local.tags

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${local.application_name}-waf-metrics"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "example" {
  resource_arn = aws_lb.external.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
