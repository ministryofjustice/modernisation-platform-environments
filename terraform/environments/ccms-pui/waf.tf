# WAF FOR PUI APP

resource "aws_wafv2_ip_set" "pui_waf_ip_set" {
  name               = "${local.application_name}-waf-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = (
    local.is-production
    ? [
      local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_a,
      local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_b,
      local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_c,
      "89.45.177.118/32" # Sahid
    ]
    :
    [
      local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_a,
      local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_b,
      local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_c,
      "35.176.254.38/32",  # Temp AWS PROD Workspace
      "35.177.173.197/32", # Temp AWS PROD Workspace
      "52.56.212.11/32"    # Temp AWS PROD Workspace
    ]
  )

  tags = merge(
    local.tags,
    { Name = lower(format("%s-%s-ip-set", local.application_name, local.environment)) }
  )
}



# Default block on the WAF for now - only allow trusted IPs above
resource "aws_wafv2_web_acl" "pui_web_acl" {
  name        = "${local.application_name}-web-acl"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for PUI Application Load Balancer"

  default_action {
    block {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        # rule_action_override {
        #   name = "NoUserAgent_HEADER"
        #   action_to_use {
        #     allow {}
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
  rule {
    name = "${local.application_name}-waf-ip-set"

    priority = 1
    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.pui_waf_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.application_name}-waf-metrics"
      sampled_requests_enabled   = true
    }
  }

  # rule {
  #   name     = "allow-uk-traffic-only"
  #   priority = 3

  #   statement {
  #     geo_match_statement {
  #       country_codes = ["GB"]
  #     }
  #   }

  #   action {
  #     allow {}
  #   }

  #   visibility_config {
  #     cloudwatch_metrics_enabled = true
  #     metric_name                = "allow-uk-traffic-only"
  #     sampled_requests_enabled   = true
  #   }
  # }


  tags = merge(local.tags,
    { Name = lower(format("%s-%s-web-acl", local.application_name, local.environment)) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.application_name}-waf-metrics"
    sampled_requests_enabled   = true
  }
}

# WAF Logging to CloudWatch
resource "aws_cloudwatch_log_group" "pui_waf_logs" {
  name              = "aws-waf-logs-${local.application_name}"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-waf-logs", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "pui_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.pui_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.pui_web_acl.arn
}

# Associate the WAF with the PUI Application Load Balancer
resource "aws_wafv2_web_acl_association" "pui_waf_association" {
  resource_arn = aws_lb.pui.arn
  web_acl_arn  = aws_wafv2_web_acl.pui_web_acl.arn
}
