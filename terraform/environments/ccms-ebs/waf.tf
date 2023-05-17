# WAF FOR EBS APP

resource "aws_wafv2_ip_set" "ebs_waf_ip_set" {
  name               = "ebs_waf_ip_set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    "81.134.202.29/32",  // MoJ Digital Wifi
    "35.177.125.252/32", // MoJ VPN Gateway Proxies
    "35.177.137.160/32", // MoJ VPN Gateway Proxies
    "35.176.127.232/32", // Management DMZ Subnet A - London Non-Prod NAT Gateway
    "35.177.145.193/32", // Management DMZ Subnet B - London Non-Prod NAT Gateway
    "18.130.39.94/32",   // Management DMC Subnet C - London Non-Prod NAT Gateway
    "52.56.212.11/32",   // Management DMZ Subnet A - London Prod NAT Gateway
    "35.176.254.38/32",  // Management DMZ Subnet B - London Prod NAT Gateway
    "35.177.173.197/32", // Management DMC Subnet C - London Prod NAT Gateway
    "195.59.75.0/24",    // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP
    "194.33.192.0/25",   // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP
    "194.33.193.0/25",   // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP
    "194.33.196.0/25",   // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP
    "194.33.197.0/25",   // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP
    "51.149.250.0/24",   // MoJO Production Account BYOIP CIDR range  
    "51.149.249.0/27",   // ARK Corsham Internet Egress Exponential-E
    "51.149.249.32/27",  // ARK Corsham Internet Egress Exponential-E
    "194.33.249.0/27",   // ARK Corsham Internet Egress Vodafone
    "194.33.248.0/27",   // ARK Corsham Internet Egress Vodafone
    "20.49.214.199/32",  // Azure Landing Zone Egress
    "20.49.214.228/32",  // Azure Landing Zone Egress
    "51.155.225.100/32", // Jide Personal Access Temporarily
    "82.12.34.69/32",    // Jide Personal Access Temporarily
    "10.26.59.0/25",     // DEV NLB Subnet eu-west-2a
    "10.26.59.128/25",   // DEV NLB Subnet eu-west-2b
    "10.26.60.0/25",     // DEV NLB Subnet eu-west-2c
    "10.26.99.0/25",     // TEST NLB Subnet eu-west-2a
    "10.26.99.128/25",   // TEST NLB Subnet eu-west-2b
    "10.26.100.0/25",    // TEST NLB Subnet eu-west-2c
    "10.27.75.0/25",     // PREPROD NLB Subnet eu-west-2a
    "10.27.75.128/25",   // PREPROD NLB Subnet eu-west-2b
    "10.27.76.0/25",     // PREPROD NLB Subnet eu-west-2c
  ]

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-ebsapp-ip-set", local.application_name, local.environment)) }
  )
}


resource "aws_wafv2_web_acl" "ebs_web_acl" {
  name        = "ebs_waf"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for EBS"

  default_action {
    block {}
  }

  rule {
    name = "ebs-trusted-rule"

    priority = 1
    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ebs_waf_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ebs_waf_metrics"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-ebsapp-web-acl", local.application_name, local.environment)) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ebs_waf_metrics"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "ebs_waf_logs" {
  name = "aws-waf-logs-ebs/ebs-waf-logs"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-ebs-waf-logs", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "ebs_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.ebs_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.ebs_web_acl.arn

}