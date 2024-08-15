# WAF FOR EBS APP

resource "aws_wafv2_ip_set" "ebs_waf_ip_set" {
  name               = "ebs_waf_ip_set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    "81.134.202.29/32",   // MoJ Digital Wifi
    "35.177.125.252/32",  // MoJ VPN Gateway Proxies
    "35.177.137.160/32",  // MoJ VPN Gateway Proxies
    "35.176.127.232/32",  // Management DMZ Subnet A - London Non-Prod NAT Gateway
    "35.177.145.193/32",  // Management DMZ Subnet B - London Non-Prod NAT Gateway
    "18.130.39.94/32",    // Management DMC Subnet C - London Non-Prod NAT Gateway
    "52.56.212.11/32",    // Management DMZ Subnet A - London Prod NAT Gateway
    "35.176.254.38/32",   // Management DMZ Subnet B - London Prod NAT Gateway
    "35.177.173.197/32",  // Management DMC Subnet C - London Prod NAT Gateway
    "195.59.75.0/24",     // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP
    "194.33.192.0/25",    // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP
    "194.33.193.0/25",    // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP
    "194.33.196.0/25",    // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP
    "194.33.197.0/25",    // ARK Data Center External Internet access addresses - NPS and HMCTS users transitioned under TTP
    "51.149.250.0/24",    // MoJO Production Account BYOIP CIDR range  
    "51.149.249.0/27",    // ARK Corsham Internet Egress Exponential-E
    "51.149.249.32/27",   // ARK Corsham Internet Egress Exponential-E
    "194.33.249.0/27",    // ARK Corsham Internet Egress Vodafone
    "194.33.248.0/27",    // ARK Corsham Internet Egress Vodafone
    "20.49.214.199/32",   // Azure Landing Zone Egress
    "20.49.214.228/32",   // Azure Landing Zone Egress
    "51.149.251.0/24",    // MoJO Pre-Production Account BYOIP CIDR range
    "51.149.249.64/29",   // 10SC Model Office
    "194.33.200.0/21",    // PRP DIA Sites
    "194.33.216.0/23",    // PRP DIA Sites
    "194.33.218.0/24",    // PRP DIA Sites
    "128.77.75.64/26",    // Palo Alto Prisma Access Egress IP Addresses
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
    "5.172.196.188/32",   // PINGDOM
    "13.232.220.164/32",  // PINGDOM
    "23.22.2.46/32",      // PINGDOM
    "23.83.129.219/32",   // PINGDOM
    "23.92.127.2/32",     // PINGDOM
    "23.106.37.99/32",    // PINGDOM
    "23.111.152.74/32",   // PINGDOM
    "23.111.159.174/32",  // PINGDOM
    "37.252.231.50/32",   // PINGDOM
    "43.225.198.122/32",  // PINGDOM
    "43.229.84.12/32",    // PINGDOM
    "46.20.45.18/32",     // PINGDOM
    "46.246.122.10/32",   // PINGDOM
    "50.2.185.66/32",     // PINGDOM
    "50.16.153.186/32",   // PINGDOM
    "52.0.204.16/32",     // PINGDOM
    "52.24.42.103/32",    // PINGDOM
    "52.48.244.35/32",    // PINGDOM
    "52.52.34.158/32",    // PINGDOM
    "52.52.95.213/32",    // PINGDOM
    "52.52.118.192/32",   // PINGDOM
    "52.57.132.90/32",    // PINGDOM
    "52.59.46.112/32",    // PINGDOM
    "52.59.147.246/32",   // PINGDOM
    "52.62.12.49/32",     // PINGDOM
    "52.63.142.2/32",     // PINGDOM
    "52.63.164.147/32",   // PINGDOM
    "52.63.167.55/32",    // PINGDOM
    "52.67.148.55/32",    // PINGDOM
    "52.73.209.122/32",   // PINGDOM
    "52.89.43.70/32",     // PINGDOM
    "52.194.115.181/32",  // PINGDOM
    "52.197.31.124/32",   // PINGDOM
    "52.197.224.235/32",  // PINGDOM
    "52.198.25.184/32",   // PINGDOM
    "52.201.3.199/32",    // PINGDOM
    "52.209.34.226/32",   // PINGDOM
    "52.209.186.226/32",  // PINGDOM
    "52.210.232.124/32",  // PINGDOM
    "54.68.48.199/32",    // PINGDOM
    "54.70.202.58/32",    // PINGDOM
    "54.94.206.111/32",   // PINGDOM
    "64.237.49.203/32",   // PINGDOM
    "64.237.55.3/32",     // PINGDOM
    "66.165.229.130/32",  // PINGDOM
    "66.165.233.234/32",  // PINGDOM
    "72.46.130.18/32",    // PINGDOM
    "72.46.131.10/32",    // PINGDOM
    "76.72.167.154/32",   // PINGDOM
    "76.72.172.208/32",   // PINGDOM
    "76.164.234.106/32",  // PINGDOM
    "76.164.234.130/32",  // PINGDOM
    "82.103.136.16/32",   // PINGDOM
    "82.103.139.165/32",  // PINGDOM
    "82.103.145.126/32",  // PINGDOM
    "85.195.116.134/32",  // PINGDOM
    "89.163.146.247/32",  // PINGDOM
    "89.163.242.206/32",  // PINGDOM
    "94.75.211.73/32",    // PINGDOM
    "94.75.211.74/32",    // PINGDOM
    "94.247.174.83/32",   // PINGDOM
    "96.47.225.18/32",    // PINGDOM
    "103.10.197.10/32",   // PINGDOM
    "103.47.211.210/32",  // PINGDOM
    "104.129.24.154/32",  // PINGDOM
    "104.129.30.18/32",   // PINGDOM
    "107.182.234.77/32",  // PINGDOM
    "108.181.70.3/32",    // PINGDOM
    "148.72.170.233/32",  // PINGDOM
    "148.72.171.17/32",   // PINGDOM
    "151.106.52.134/32",  // PINGDOM
    "159.122.168.9/32",   // PINGDOM
    "162.208.48.94/32",   // PINGDOM
    "162.218.67.34/32",   // PINGDOM
    "162.253.128.178/32", // PINGDOM
    "168.1.203.46/32",    // PINGDOM
    "169.51.2.18/32",     // PINGDOM
    "169.54.70.214/32",   // PINGDOM
    "169.56.174.151/32",  // PINGDOM
    "172.241.112.86/32",  // PINGDOM
    "173.248.147.18/32",  // PINGDOM
    "173.254.206.242/32", // PINGDOM
    "174.34.156.130/32",  // PINGDOM
    "175.45.132.20/32",   // PINGDOM
    "178.162.206.244/32", // PINGDOM
    "178.255.152.2/32",   // PINGDOM
    "178.255.153.2/32",   // PINGDOM
    "179.50.12.212/32",   // PINGDOM
    "184.75.208.210/32",  // PINGDOM
    "184.75.209.18/32",   // PINGDOM
    "184.75.210.90/32",   // PINGDOM
    "184.75.210.226/32",  // PINGDOM
    "184.75.214.66/32",   // PINGDOM
    "184.75.214.98/32",   // PINGDOM
    "185.39.146.214/32",  // PINGDOM
    "185.39.146.215/32",  // PINGDOM
    "185.70.76.23/32",    // PINGDOM
    "185.93.3.65/32",     // PINGDOM
    "185.136.156.82/32",  // PINGDOM
    "185.152.65.167/32",  // PINGDOM
    "185.180.12.65/32",   // PINGDOM
    "185.246.208.82/32",  // PINGDOM
    "188.172.252.34/32",  // PINGDOM
    "190.120.230.7/32",   // PINGDOM
    "196.240.207.18/32",  // PINGDOM
    "196.244.191.18/32",  // PINGDOM
    "196.245.151.42/32",  // PINGDOM
    "199.87.228.66/32",   // PINGDOM
    "200.58.101.248/32",  // PINGDOM
    "201.33.21.5/32",     // PINGDOM
    "207.244.80.239/32",  // PINGDOM
    "209.58.139.193/32",  // PINGDOM
    "209.58.139.194/32",  // PINGDOM
    "209.95.50.14/32",    // PINGDOM
    "212.78.83.12/32",    // PINGDOM
    "212.78.83.16/32"     // PINGDOM
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
