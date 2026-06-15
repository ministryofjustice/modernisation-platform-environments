# WAF FOR SFTP CLIENT 1 APP

resource "aws_wafv2_ip_set" "sftp_waf_ip_set" {
  name               = "${local.sftp_suffix}-waf-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
  ]

  tags = merge(
    local.tags,
    { Name = "${local.sftp_suffix}-waf-ip-set" }
  )
}

resource "aws_wafv2_web_acl" "sftp_web_acl" {
  name        = "${local.sftp_suffix}-web-acl"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for SFTP Application Load Balancer"

  default_action {
    block {}
  }

  custom_response_body {
    key          = "TooManyRequests"
    content_type = "APPLICATION_JSON"
    content      = "{\"message\":\"Too many requests\"}"
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

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CrossSiteScripting_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "EndpointSpecific-10RPS-Limit"
    priority = 1

    statement {
      rate_based_statement {
        limit                 = 30
        aggregate_key_type    = "IP"
        evaluation_window_sec = 60

        # scope_down_statement {
        #   byte_match_statement {
        #     search_string = "/swagger-ui.html"

        #     field_to_match {
        #       uri_path {}
        #     }

        #     text_transformation {
        #       priority = 0
        #       type     = "LOWERCASE"
        #     }

        #     positional_constraint = "EXACTLY"
        #   }
        # }
      }
    }

    action {
      block {
        custom_response {
          response_code            = 429
          custom_response_body_key = "TooManyRequests"
        }
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "EndpointSpecific10RPSLimit"
    }
  }

  # Restrict access to trusted IPs only - Non-Prod environments only
  dynamic "rule" {
    for_each = !local.is-production ? [1] : [1] # Temprorarily enable for Prod as well - to be removed when Geo Match is live
    content {
      name     = "${local.sftp_suffix}-waf-ip-set"
      priority = 3

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.sftp_waf_ip_set.arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.sftp_suffix}-waf-ip-set"
        sampled_requests_enabled   = true
      }
    }
  }

  tags = merge(local.tags,
    { Name = "${local.sftp_suffix}-web-acl" }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.sftp_suffix}-waf-metrics"
    sampled_requests_enabled   = true
  }
}

# WAF Logging to CloudWatch
resource "aws_cloudwatch_log_group" "sftp_waf_logs" {
  name              = "aws-waf-logs-${local.sftp_suffix}/${local.sftp_suffix}-waf-logs"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = "${local.sftp_suffix}-waf-logs" }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "sftp_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.sftp_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.sftp_web_acl.arn
}

# Associate the WAF with the SFTP bc Application Load Balancer
resource "aws_wafv2_web_acl_association" "sftp_waf_association" {
  resource_arn = aws_lb.sftp_load_balancer.arn
  web_acl_arn  = aws_wafv2_web_acl.sftp_web_acl.arn
}
