module "waf" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-waf?ref=v0.0.1"
  enable_ddos_protection = true
  ddos_rate_limit        = 3000
  block_non_uk_traffic   = true
  associated_resource_arns = [aws_lb.waf_lb.arn]

  managed_rule_actions = {
    AWSManagedRulesKnownBadInputsRuleSet = true
    AWSManagedRulesCommonRuleSet         = true
    AWSManagedRulesSQLiRuleSet           = true
    AWSManagedRulesLinuxRuleSet          = true
    AWSManagedRulesAnonymousIpList       = true
    AWSManagedRulesBotControlRuleSet     = true
  }
  
  core_logging_account_id = local.environment_management.account_ids["core-logging-production"]

  application_name = local.application_name
  tags             = local.tags

}

module "waf_prtg" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-waf?ref=v0.0.1"
  enable_ddos_protection = true
  ddos_rate_limit        = 1000
  block_non_uk_traffic   = true
  associated_resource_arns = [aws_lb.prtg_lb.arn]

  managed_rule_actions = {
    AWSManagedRulesKnownBadInputsRuleSet = true
    AWSManagedRulesCommonRuleSet         = true
    AWSManagedRulesSQLiRuleSet           = true
    AWSManagedRulesLinuxRuleSet          = true
    AWSManagedRulesAnonymousIpList       = true
    AWSManagedRulesBotControlRuleSet     = true
  }
  
  core_logging_account_id = local.environment_management.account_ids["core-logging-production"]

  application_name = local.application_name
  tags             = local.tags

}

# WAF IP allow list for PRTG

resource "aws_wafv2_ip_set" "prtg_waf_ip_set" {
  name               = "prtg_waf_ip_set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    "100.44.12.86/32",   // MoJ Digital Wifi
    "35.176.93.186/32",  // MoJ VPN Gateway Proxies
    "172.10.10.188/32",  // V1 Digital Wifi
    "194.62.186.170",    // V1 VPN Gateway Proxies
    "66.155.16.68/32",   // Southampton BEL Wifi
  ]

  tags = merge(local.tags,
    { Name = lower(format("%s-prtg-waf-ip-set-%s", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl" "prtg_web_acl" {
  name        = "prtg_waf"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for PRTG"

  default_action {
    block {}
  }

  rule {
    name = "prtg-trusted-rule"

    priority = 1
    action {
      count {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.prtg_waf_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "prtg_waf_metrics"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-prtg-waf-web-acl-%s", local.application_name, local.environment)) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "prtg_waf_metrics"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "prtg_waf_logs" {
  name              = "aws-waf-logs-prtg-waf"
  retention_in_days = 365

  tags = merge(local.tags,
    { Name = lower(format("%s-prtg-waf-logs-%s", local.application_name, local.environment)) }
  )
}

resource "aws_wafv2_web_acl_logging_configuration" "prtg_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.prtg_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.prtg_web_acl.arn
}
