# WAF FOR EBS APP Internal ALB

resource "aws_wafv2_ip_set" "ebsapps_waf_ip_set" {
  name               = "ebsapps_internal_waf_ip_set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF for EBS Apps Internal ALB"

  addresses = [
    data.aws_vpc.shared.cidr_block,
    local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod,
    local.application_data.accounts[local.environment].mojo_devices,
    local.application_data.accounts[local.environment].dom1_devices
  ]

  tags = merge(local.tags,
    { Name = lower(format("ebsapp-internal-ip-set")) }
  )
}

resource "aws_wafv2_web_acl" "ebsapps_internal_web_acl" {
  name        = "ebs_internal_waf"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for EBS Internal Application Load Balancer"

  default_action {
    block {}
  }

  rule {
    name = "ebs-trusted-rule-ip-set"

    priority = 1
    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ebsapps_waf_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ebs_internal_waf_metrics"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("ebsapp-internal-web-acl")) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ebs_internal_waf_metrics"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "ebs_internal_waf_logs" {
  name              = "aws-waf-logs-ebs/ebs-waf-internal-logs"
  retention_in_days = 180

  tags = merge(local.tags,
    { Name = lower(format("ebs-waf-logs")) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "ebs_internal_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.ebs_internal_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.ebsapps_internal_web_acl.arn
}

# Associate WAF with Internal ALB for EBS Apps
resource "aws_wafv2_web_acl_association" "ebs_internal_waf_association" {
  resource_arn = aws_lb.ebsapps_internal_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.ebsapps_internal_web_acl.arn
}