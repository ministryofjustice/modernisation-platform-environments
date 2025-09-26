# WAF FOR PUI APP - Temporary restricted access to trusted IPs only

resource "aws_wafv2_ip_set" "pui_waf_ip_set" {
  name               = "PUI-WAF-IP-Set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    "35.176.127.232/32",  // Management DMZ Subnet A - London Non-Prod NAT Gateway
    "35.177.145.193/32",  // Management DMZ Subnet B - London Non-Prod NAT Gateway
    "18.130.39.94/32",    // Management DMC Subnet C - London Non-Prod NAT Gateway
    "52.56.212.11/32",    // Management DMZ Subnet A - London Prod NAT Gateway
    "35.176.254.38/32",   // Management DMZ Subnet B - London Prod NAT Gateway
    "35.177.173.197/32",  // Management DMC Subnet C - London Prod NAT Gateway
    "10.26.59.0/25",      // DEV NLB Subnet eu-west-2a
    "10.26.59.128/25",    // DEV NLB Subnet eu-west-2b
    "10.26.60.0/25",      // DEV NLB Subnet eu-west-2c
    "10.26.99.0/25",      // TEST NLB Subnet eu-west-2a
    "10.26.99.128/25",    // TEST NLB Subnet eu-west-2b
    "10.26.100.0/25",     // TEST NLB Subnet eu-west-2c
    "10.27.75.0/25",      // PREPROD NLB Subnet eu-west-2a
    "10.27.75.128/25",    // PREPROD NLB Subnet eu-west-2b
    "10.27.76.0/25",      // PREPROD NLB Subnet eu-west-2c
    "10.27.67.0/25",      // PROD NLB Subnet eu-west-2a
    "10.27.68.0/25",      // PROD NLB Subnet eu-west-2b
    "10.27.67.128/25",    // PROD NLB Subnet eu-west-2c
  ]

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-ip-set", local.application_name, local.environment)) }
  )
}

# Default block on the WAF for now - only allow trusted IPs above
resource "aws_wafv2_web_acl" "pui_web_acl" {
  name        = "PUI-Web-ACL"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for PUI Application Load Balancer"

  default_action {
    block {}
  }

  rule {
    name = "PUI-WAF-IP-Set"

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
      metric_name                = "PUI_WAF_Metrics"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-web-acl", local.application_name, local.environment)) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "PUI_WAF_Metrics"
    sampled_requests_enabled   = true
  }
}

# WAF Logging to CloudWatch
resource "aws_cloudwatch_log_group" "pui_waf_logs" {
  name              = "PUI-WAF-Logs"
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