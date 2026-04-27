# WAF FOR SFTP CLIENT 1 APP
resource "aws_wafv2_ip_set" "sftp_bc_waf_ip_set" {
  name               = "${local.application_name}-sftp-bc-waf-ip-set"
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
    { Name = lower(format("%s-sftp-bc-%s-ip-set", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl" "sftp_bc_web_acl" {
  name        = "${local.application_name}-sftp-bc-web-acl"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for SFTP Client 1 Application Load Balancer"

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

  # Restrict access to trusted IPs only - Non-Prod environments only
  dynamic "rule" {
    for_each = !local.is-production ? [1] : [1] # Temprorarily enable for Prod as well - to be removed when Geo Match is live
    content {
      name     = "${local.application_name}-sftp-bc-waf-ip-set"
      priority = 2

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.sftp_bc_waf_ip_set.arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.application_name}-sftp-bc-waf-ip-set"
        sampled_requests_enabled   = true
      }
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-bc-%s-web-acl", local.application_name, local.environment)) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.application_name}-sftp-bc-waf-metrics"
    sampled_requests_enabled   = true
  }
}

# WAF Logging to CloudWatch
resource "aws_cloudwatch_log_group" "sftp_bc_waf_logs" {
  name              = "aws-waf-logs-${local.application_name}-sftp-bc/sftp-bc-waf-logs"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("%s-sftp-bc-%s-waf-logs", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "sftp_bc_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.sftp_bc_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.sftp_bc_web_acl.arn
}

# Associate the WAF with the SFTP bc Application Load Balancer
resource "aws_wafv2_web_acl_association" "sftp_bc_waf_association" {
  resource_arn = aws_lb.sftp_bc_load_balancer.arn
  web_acl_arn  = aws_wafv2_web_acl.sftp_bc_web_acl.arn
}
