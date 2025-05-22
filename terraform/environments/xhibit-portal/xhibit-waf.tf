
# WAF FOR EBS APP

# The secret containing IP addresses
data "aws_secretsmanager_secret_version" "ip_block_list" {
  secret_id = aws_secretsmanager_secret.ip_block_list.id
}


resource "aws_wafv2_ip_set" "xbhibit_waf_ip_set" {
  name               = "xbhibit_waf_ip_set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List IP Addresses to be blockefd via WAF"

  addresses = jsondecode(data.aws_secretsmanager_secret_version.ip_block_list.secret_string)

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-ip-set", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl" "xhibit_web_acl" {
  name        = "xbhibit_waf"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL"

  default_action {
    block {}
  }

  rule {
    name = "xbhibit-waf-blocked-rule"

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

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-xhibit-web-acl", local.application_name, local.environment)) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "xhibit_waf_metrics"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "xbhibit_waf_logs" {
  name              = "aws-waf-logs/xhibit-waf-logs"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-xhibit-waf-logs", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "xhibit_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.xbhibit_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.xhibit_web_acl.arn
}
