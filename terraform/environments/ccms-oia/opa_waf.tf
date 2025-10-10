# WAF FOR OPAHUB APP - Temporary restricted access to trusted IPs only

resource "aws_wafv2_ip_set" "opahub_waf_ip_set" {
  name               = "${local.opa_app_name}-waf-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_a,
    local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_b,
    local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_c
  ]

  tags = merge(local.tags,
    { Name = lower(format("%s-ip-set", local.opa_app_name)) }
  )
}

# Default block on the WAF for now - only allow trusted IPs above
resource "aws_wafv2_web_acl" "opahub_web_acl" {
  name        = "${local.opa_app_name}-web-acl"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for opahub Application Load Balancer"

  default_action {
    block {}
  }

  rule {
    name = "${local.opa_app_name}-waf-ip-set"

    priority = 1
    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.opahub_waf_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.opa_app_name}-waf-metrics"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-web-acl", local.opa_app_name)) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.opa_app_name}-waf-metrics"
    sampled_requests_enabled   = true
  }
}

# WAF Logging to CloudWatch
resource "aws_cloudwatch_log_group" "opahub_waf_logs" {
  name              = "aws-waf-logs-${local.opa_app_name}"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("%s-waf-logs", local.opa_app_name)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "opahub_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.opahub_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.opahub_web_acl.arn
}

# Associate the WAF with the opahub Application Load Balancer
resource "aws_wafv2_web_acl_association" "opahub_waf_association" {
  resource_arn = aws_lb.opahub.arn
  web_acl_arn  = aws_wafv2_web_acl.opahub_web_acl.arn
}
