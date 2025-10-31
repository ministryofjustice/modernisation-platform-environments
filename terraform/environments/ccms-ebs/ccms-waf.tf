# WAF FOR EBS APP

resource "aws_wafv2_ip_set" "ebs_waf_ip_set" {
  name               = "ebs_waf_ip_set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_a,
    local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_b,
    local.application_data.accounts[local.environment].lz_aws_workspace_public_nat_gateway_c,
    // "195.59.75.0/24",    // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP - NOT on Donovans list
    // "194.33.192.0/25",   // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP - NOT on Donovans list
    // "194.33.193.0/25",   // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP - NOT on Donovans list
    // "194.33.196.0/25",   // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP - NOT on Donovans list
    // "194.33.197.0/25",   // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP - NOT on Donovans list
    // "51.149.250.0/24",   // MoJO Production Account BYOIP CIDR range  - NOT on Donovans list
    "51.149.249.0/29",  // ARK Corsham Internet Egress Exponential-E - (changed from /27 to /29)
    "51.149.249.32/29", // ARK Corsham Internet Egress Exponential-E - (changed from /27 to /29)
    "194.33.249.0/29",  // ARK Corsham Internet Egress Vodafone - (changed from /27 to /29)
    "194.33.248.0/29",  // ARK Corsham Internet Egress Vodafone - (changed from /27 to /29)
    "20.49.214.199/32", // Azure Landing Zone Egress - Keep
    "20.49.214.228/32", // Azure Landing Zone Egress - Keep
    "20.26.11.71/32",   // Azure Landing Zone Egress - Added from Donovans list
    "20.26.11.108/32",  // Azure Landing Zone Egress - Added from Donovans list
    // "51.149.251.0/24",   // MoJO Pre-Production Account BYOIP CIDR range - NOT on Donovans list
    // "51.149.249.64/29",  // 10SC Model Office - NOT on Donovans list
    // "194.33.200.0/21",   // PRP DIA Sites - NOT on Donovans list
    // "194.33.216.0/23",   // PRP DIA Sites - NOT on Donovans list
    // "194.33.218.0/24",   // PRP DIA Sites - NOT on Donovans list
    "128.77.75.64/26",   // Palo Alto Prisma Access Egress IP Addresses - Keep
    "35.176.93.186/32",  // Gateway IP address for Global Protect alpha vpn firewall - Added from Donovans list
    "18.169.147.172/32", // Gateway IP address for Global Protect alpha vpn firewall - Added from Donovans list
    "18.130.148.126/32", // Gateway IP address for Global Protect alpha vpn firewall - Added from Donovans list
    "35.176.148.126/32", // Gateway IP address for Global Protect alpha vpn firewall - Added from Donovans list
    data.aws_subnet.public_subnets_a.cidr_block,
    data.aws_subnet.public_subnets_b.cidr_block,
    data.aws_subnet.public_subnets_c.cidr_block
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
  name              = "aws-waf-logs-ebs/ebs-waf-logs"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-%s-ebs-waf-logs", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "ebs_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.ebs_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.ebs_web_acl.arn
}
