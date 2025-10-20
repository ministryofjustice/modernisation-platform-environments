locals {
  associated_load_balancers_arns = local.environment == "development" ? [aws_lb.WAM-ALB.arn] : []
}

module "waf" {
  source                   = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-aws-waf?ref=b9cf6f92b142e80845ae30252aee2f84f57a71a9"
  enable_ddos_protection   = true
  ddos_rate_limit          = 150
  block_non_uk_traffic     = true
  associated_resource_arns = local.associated_load_balancers_arns

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
    AWSManagedRulesAnonymousIpList       = 30
    AWSManagedRulesKnownBadInputsRuleSet = 40
    AWSManagedRulesCommonRuleSet         = 50
    AWSManagedRulesSQLiRuleSet           = 60
    AWSManagedRulesLinuxRuleSet          = 70
    AWSManagedRulesBotControlRuleSet     = 80
  }

  core_logging_account_id = local.environment_management.account_ids["core-logging-production"]

  application_name = local.application_name
  tags             = local.tags

}

# WAF IP allow list for NCSC WebCheck & Detectify Services

data "aws_ssm_parameter" "ncsc_waf_ip_set" {
  name = "ncsc_waf_ip_set"
}

locals {
  ncsc_ip_addresses = split(",", data.aws_ssm_parameter.ncsc_waf_ip_set.value)
}

resource "aws_wafv2_ip_set" "ncsc_waf_ip_set" {
  count              = (local.is-development || local.is-preproduction || local.is-production) ? 1 : 0
  name               = "ncsc-waf-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted IP Addresses allowing access via WAF"
  addresses          = local.ncsc_ip_addresses

  tags = merge(local.tags,
    { Name = lower(format("%s-ncsc-waf-ip-set-%s", local.application_name, local.environment)) }
  )
}

# WebACL for WAM
resource "aws_wafv2_web_acl" "wam_web_acl" {
  # checkov:skip=CKV_AWS_192: "Ensure WAF prevents message lookup in Log4j2. See CVE-2021-44228 aka log4jshell"
  count       = local.is-development == true ? 1 : 0
  name        = "wam-waf-acl"
  scope       = "REGIONAL"
  description = "AWS WAF Web ACL for WAM"

  default_action {
    allow {}       // This allows UK traffic by default
  }

  rule {
    name = "ncsc-waf-ip-list"
    priority = 10
    action {
      allow {}
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ncsc_waf_ip_set.arn[0]
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "wam-ncsc-waf-ip-list"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "block-non-uk"
    priority = 20
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
      metric_name                = "wam-waf-block-non-uk"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rule Group (in COUNT mode)
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 100

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
    { Name = lower(format("%s-wam-waf-web-acl-%s", local.application_name, local.environment)) }
  )
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "wam-waf"
    sampled_requests_enabled   = true
  }
}

# Create CloudWatch log group for PRTG
resource "aws_cloudwatch_log_group" "wam_waf_logs" {
  # checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS"
  count             = local.is-development == true ? 1 : 0
  name              = "aws-waf-logs-wam-waf"
  retention_in_days = 365
  tags = merge(local.tags,
    { Name = lower(format("%s-wam-waf-logs-%s", local.application_name, local.environment)) }
  )
}

# Send WebACL logs to CloudWatch
resource "aws_wafv2_web_acl_logging_configuration" "wam_waf_logging" {
  count                   = local.is-development == true ? 1 : 0
  log_destination_configs = [aws_cloudwatch_log_group.wam_waf_logs.arn[0]]
  resource_arn            = aws_wafv2_web_acl.wam_web_acl.arn[0]
}
