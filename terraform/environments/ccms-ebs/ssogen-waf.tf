# WAF FOR SSOGEN APP

resource "aws_wafv2_ip_set" "ssogen_waf_ip_set" {
  count              = local.is-development || local.is-test ? 1 : 0
  name               = "${local.application_name}-ssogen-waf-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
    data.aws_subnet.private_subnets_a.cidr_block,
    data.aws_subnet.private_subnets_b.cidr_block,
    data.aws_subnet.private_subnets_c.cidr_block
    # local.application_data.accounts[local.environment].sb_vpc
  ]

  tags = merge(
    local.tags,
    { Name = lower(format("%s-%s-ssogen-ip-set", local.application_name, local.environment)) }
  )
}


resource "aws_wafv2_web_acl" "ssogen_web_acl" {
  count       = local.is-development || local.is-test ? 1 : 0
  name        = "${local.application_name}-ssogen-web-acl"
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
    # for_each = !local.is-production ? [1] : [1] # Temprorarily enable for Prod as well - to be removed when Geo Match is live
    for_each = local.is-development || local.is-test ? [1] : [0] # Temprorarily enable for Prod as well - to be removed when Geo Match is live
    content {
      name     = "${local.application_name}-ssogen-waf-ip-set"
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
        metric_name                = "${local.application_name}-waf-ip-set"
        sampled_requests_enabled   = true
      }
    }

  }


  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-ssogen-web-acl", local.application_name, local.environment)) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.application_name}-ssogen-waf-metrics"
    sampled_requests_enabled   = true
  }

}

resource "aws_cloudwatch_log_group" "ssogen_waf_logs" {
  name              = "aws-waf-logs-ssogen/ssogen-waf-logs"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-ssogen-waf-logs", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "ssogen_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.ssogen_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.ssogen_web_acl.arn
}
