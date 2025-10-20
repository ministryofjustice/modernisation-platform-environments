module "waf" {
  source                   = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-aws-waf?ref=86fa9d802455114baf80628f3c5670dddc732a7f"
  enable_ddos_protection   = true
  ddos_rate_limit          = 3000
  block_non_uk_traffic     = true
  associated_resource_arns = [aws_lb.waf_lb.arn]

  providers = {
    aws                        = aws
    aws.modernisation-platform = aws.modernisation-platform
  }

  managed_rule_actions = {
    AWSManagedRulesKnownBadInputsRuleSet = false
    AWSManagedRulesCommonRuleSet         = false
    AWSManagedRulesSQLiRuleSet           = false
    AWSManagedRulesLinuxRuleSet          = false
    AWSManagedRulesAnonymousIpList       = false
    AWSManagedRulesBotControlRuleSet     = false
  }

  managed_rule_priorities = {
    AWSManagedRulesAnonymousIpList       = 10
    AWSManagedRulesKnownBadInputsRuleSet = 11
    AWSManagedRulesCommonRuleSet         = 12
    AWSManagedRulesSQLiRuleSet           = 13
    AWSManagedRulesLinuxRuleSet          = 14
    AWSManagedRulesBotControlRuleSet     = 15
  }

  core_logging_account_id = local.environment_management.account_ids["core-logging-production"]

  application_name = local.application_name
  tags             = local.tags

}

# WAF IP allow list for PRTG

resource "aws_wafv2_ip_set" "prtg_waf_ip_set" {
  name               = "prtg-waf-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"

  addresses = [
    "5.64.250.224/32",   // MP
    "35.176.93.186/32",  // MoJ Alpha VPN Gateway
    "66.155.16.61/32",   // SBEL Wifi
    "66.155.16.68/32",   // SBEL Wifi
    "86.16.40.31/32",    // ZP
    "90.247.105.163/32", // TM
    "92.236.109.133/32", // GD Wifi
    "100.44.12.86/32",   // MoJ Digital Wifi
    "128.77.75.64/26",   // MoJ Prisma VPN Gateway
    "172.10.10.188/32",  // V1 Digital Wifi
    "194.62.186.170/32"  // V1 VPN Gateway Proxies
  ]

  tags = merge(local.tags,
    { Name = lower(format("%s-prtg-waf-ip-set-%s", local.application_name, local.environment)) }
  )
}

# WebACL for PRTG
resource "aws_wafv2_web_acl" "prtg_web_acl" {
  # checkov:skip=CKV_AWS_192: "Ensure WAF prevents message lookup in Log4j2. See CVE-2021-44228 aka log4jshell"
  name        = "prtg-waf"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for PRTG"

  default_action {
    block {}
  }

  rule {
    name = "prtg-waf-ip-list"

    priority = 1
    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.prtg_waf_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "prtg-waf-ip-list"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "block-non-uk"
    priority = 2

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["GB"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "prtg-waf-block-non-uk"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rule Group (in COUNT mode)
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 10

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-prtg-waf-web-acl-%s", local.application_name, local.environment)) }
  )

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "prtg-waf"
    sampled_requests_enabled   = true
  }
}

# Create CloudWatch log group for PRTG
resource "aws_cloudwatch_log_group" "prtg_waf_logs" {
  # checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS"
  name              = "aws-waf-logs-prtg-waf"
  retention_in_days = 365

  tags = merge(local.tags,
    { Name = lower(format("%s-prtg-waf-logs-%s", local.application_name, local.environment)) }
  )
}

# Send WebACL logs to CloudWatch
resource "aws_wafv2_web_acl_logging_configuration" "prtg_waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.prtg_waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.prtg_web_acl.arn
}
