# modules/waf.tf

resource "aws_wafv2_web_acl" "basic" {
  name        = "basic-waf"
  scope       = "REGIONAL"
  default_action { 
    block {} 
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action { 
        count {} 
    }
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
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BadInputRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "basicWaf"
    sampled_requests_enabled   = true
  }
}

# WAF Logging to CloudWatch
resource "aws_cloudwatch_log_group" "basic_waf_logs" {
  name              = "aws-waf-logs-${local.cst_app_name}"
  retention_in_days = 180

  tags = merge(local.tags,
    { Name = lower(format("%s-waf-logs", local.cst_app_name)) }
  )
}


resource "aws_wafv2_web_acl_logging_configuration" "basic_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.basic_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.basic.arn
}