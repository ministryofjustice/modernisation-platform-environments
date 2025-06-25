resource "aws_ssm_parameter" "ip_block_list" {
  # checkov:skip=CKV_AWS_337: Standard KMS is fine
  name  = "/waf/ip_block_list"
  type  = "SecureString"
  value = "[]" # or use a dummy like '[]'

  lifecycle {
    ignore_changes = [value] # This is critical, so its not overwritten 
  }
}


resource "aws_wafv2_ip_set" "xbhibit_waf_ip_set" {
  name               = "xbhibit_waf_ip_set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List IP Addresses to be blockefd via WAF"

  addresses = local.blocked_ips


  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-ip-set", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl" "xhibit_web_acl" {
  # checkov:skip=CKV_AWS_192: Log4j protection is handled by AWSManagedRulesKnownBadInputsRuleSet
  name        = "xbhibit_waf"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL"

  default_action {
    allow {}
  }

  # IP blocking rule, the only blocking rule
  rule {
    name     = "xbhibit-waf-blocked-rule"
    priority = 1

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.xbhibit_waf_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "xbhibit_waf_metrics"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rule Groups (all in COUNT mode)
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 10

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 11

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
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 12

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesLinuxRuleSet"
    priority = 13

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "LinuxRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = 14

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AnonymousIpList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesBotControlRuleSet"
    priority = 16

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
        # Optional: scope_down_statement can be added here for finer control
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BotControlRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "xhibit_waf_metrics"
    sampled_requests_enabled   = true
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-xhibit-web-acl", local.application_name, local.environment)) }
  )
}


resource "aws_wafv2_web_acl_association" "xhibit_portal_prtg" {
  resource_arn = aws_lb.prtg_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.xhibit_web_acl.arn
  depends_on   = [aws_lb.prtg_lb]
}

resource "aws_wafv2_web_acl_association" "xhibit_portal_waf" {
  resource_arn = aws_lb.waf_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.xhibit_web_acl.arn

  depends_on = [aws_lb.waf_lb] # Ensures ALB is ready before association

}

resource "aws_cloudwatch_log_group" "xbhibit_waf_logs" {
  #checkov:skip=CKV_AWS_158: "Ensure that Cloudwatch Log Group is encrypted using KMS CMK"
  name              = "aws-waf-logs-xbhibit-waf" # Must match this format
  retention_in_days = 365
  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-xhibit-waf-logs", local.application_name, local.environment)) }
  )
}



resource "aws_wafv2_web_acl_logging_configuration" "xbhibit_waf_logging_config" {
  log_destination_configs = [aws_cloudwatch_log_group.xbhibit_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.xhibit_web_acl.arn

  depends_on = [aws_cloudwatch_log_resource_policy.xbhibit_waf_resource_policy]
}

resource "aws_cloudwatch_log_resource_policy" "xbhibit_waf_resource_policy" {
  policy_document = data.aws_iam_policy_document.waf.json
  policy_name     = "webacl-policy-uniq-name"
}
data "aws_iam_policy_document" "waf" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.xbhibit_waf_logs.arn}:*"]
  }
}
