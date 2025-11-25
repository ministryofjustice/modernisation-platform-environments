# modules/waf.tf

resource "aws_wafv2_web_acl" "basic" {
  name        = "basic-waf"
  scope       = "REGIONAL"
  default_action { block {} }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action { count {} }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "commonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "basicWaf"
    sampled_requests_enabled   = true
  }
}
