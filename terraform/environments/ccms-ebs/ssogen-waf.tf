# WAF FOR SSOGEN Console

resource "aws_wafv2_ip_set" "ssogen_console_waf_ip_set" {
  count              = local.is-development || local.is-test ? 1 : 0
  name               = "${local.application_name_ssogen}-console-waf-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF to SSOGEN Console"

  addresses = [
    data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod
  ]

  tags = merge(
    local.tags,
    { Name = lower(format("%s-console-%s-ip-set", local.application_name_ssogen, local.environment)) }
  )
}


resource "aws_wafv2_web_acl" "ssogen_console_web_acl" {
  count       = local.is-development || local.is-test ? 1 : 0
  name        = "${local.application_name_ssogen}-console-web-acl"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for SSOGEN Console Application Load Balancer"

  default_action {
    block {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        # rule_action_override {
        #   name = "SizeRestrictions_BODY"
        #   action_to_use {
        #     count {}
        #   }
        # }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Restrict access to trusted IPs only - Non-Prod environments only
  rule {
    name     = "${local.application_name_ssogen}-console-waf-ip-set"
    priority = 2

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ssogen_console_waf_ip_set[count.index].arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.application_name_ssogen}-console-waf-ip-set"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-console-%s-web-acl", local.application_name_ssogen, local.environment)) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.application_name_ssogen}-console-waf-metrics"
    sampled_requests_enabled   = true
  }

}

resource "aws_cloudwatch_log_group" "ssogen_console_waf_logs" {
  count             = local.is-development || local.is-test ? 1 : 0
  name              = "aws-waf-logs-ssogen/ssogen-console-waf-logs"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-console-%s-waf-logs", local.application_name_ssogen, local.environment)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "ssogen_console_waf_logging" {
  count                   = local.is-development || local.is-test ? 1 : 0
  log_destination_configs = [aws_cloudwatch_log_group.ssogen_console_waf_logs[count.index].arn]
  resource_arn            = aws_wafv2_web_acl.ssogen_console_web_acl[count.index].arn
}

# Associate WAF with Internal ALB for SSOGEN WAF
resource "aws_wafv2_web_acl_association" "ssogen_internal_waf_association" {
  count        = local.is-development || local.is-test ? 1 : 0
  resource_arn = aws_lb.ssogen_console_alb[count.index].arn
  web_acl_arn  = aws_wafv2_web_acl.ssogen_console_web_acl[count.index].arn
}

# WAF FOR SSOGEN APP

resource "aws_wafv2_ip_set" "ssogen_waf_ip_set" {
  count              = local.is-development || local.is-test ? 1 : 0
  name               = "${local.application_name_ssogen}-waf-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
    local.application_data.accounts[local.environment].mojo_devices,
    local.application_data.accounts[local.environment].dom1_devices
    # local.application_data.accounts[local.environment].sb_vpc
  ]

  tags = merge(
    local.tags,
    { Name = lower(format("%s-%s-ip-set", local.application_name_ssogen, local.environment)) }
  )
}


resource "aws_wafv2_web_acl" "ssogen_web_acl" {
  count       = local.is-development || local.is-test ? 1 : 0
  name        = "${local.application_name_ssogen}-web-acl"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for SSOGEN Application Load Balancer"

  default_action {
    block {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        # rule_action_override {
        #   name = "SizeRestrictions_BODY"
        #   action_to_use {
        #     count {}
        #   }
        # }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Restrict access to trusted IPs only - Non-Prod environments only
  rule {
    name     = "${local.application_name_ssogen}-waf-ip-set"
    priority = 2

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ssogen_waf_ip_set[count.index].arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.application_name_ssogen}-waf-ip-set"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-web-acl", local.application_name_ssogen, local.environment)) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.application_name_ssogen}-waf-metrics"
    sampled_requests_enabled   = true
  }

}

resource "aws_cloudwatch_log_group" "ssogen_waf_logs" {
  count             = local.is-development || local.is-test ? 1 : 0
  name              = "aws-waf-logs-ssogen/ssogen-waf-logs"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-waf-logs", local.application_name_ssogen, local.environment)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "ssogen_waf_logging" {
  count                   = local.is-development || local.is-test ? 1 : 0
  log_destination_configs = [aws_cloudwatch_log_group.ssogen_waf_logs[count.index].arn]
  resource_arn            = aws_wafv2_web_acl.ssogen_web_acl[count.index].arn
}

# Associate WAF with Internal ALB for SSOGEN WAF
resource "aws_wafv2_web_acl_association" "ssogen_internal_waf_association" {
  count        = local.is-development || local.is-test ? 1 : 0
  resource_arn = aws_lb.ssogen_alb[count.index].arn
  web_acl_arn  = aws_wafv2_web_acl.ssogen_web_acl[count.index].arn
}