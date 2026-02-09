resource "aws_wafv2_web_acl" "main" {
  name        = "${local.application_name}-web-acl"
  description = "WAF for ${local.application_name} API Gateway"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Rule 0: IP Allowlist
  rule {
    name     = "IPAllowlist"
    priority = 1

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.allowed_ips.arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.application_name}-ip-allowlist"
      sampled_requests_enabled   = true
    }
  }

  # Rule 1: AWS Common Rule Set (Generic exploits, OWASP Top 10)
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 10

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
      metric_name                = "${local.application_name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: SQL Injection Protection
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.application_name}-sqli-rules"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: Known Bad Inputs
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 30

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
      metric_name                = "${local.application_name}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.application_name}-waf-main"
    sampled_requests_enabled   = true
  }

  tags = local.tags
}

# Link WAF to API Gateway Stage
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_api_gateway_stage.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# WAF Logging
resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${local.application_name}"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_wafv2_web_acl_logging_configuration" "main" {
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn
}

resource "aws_wafv2_ip_set" "allowed_ips" {
  name               = "${local.application_name}-allowed-ips"
  description        = "Allowed IPs for ${local.application_name}"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["150.228.103.80/32"] #for testing, replace with actual IPs or CIDR blocks as needed
  tags               = local.tags
}
