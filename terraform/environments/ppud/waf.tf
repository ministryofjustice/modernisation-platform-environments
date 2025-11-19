#########################################################
# Web Application Firewall ACL, IP Sets & WAF Rule Groups
#########################################################

#########################
# Development Environment
#########################

locals {
  associated_load_balancers_arns = local.environment == "development" ? [aws_lb.WAM-ALB.arn] : []
}

module "waf" {
  # checkov:skip=CKV_TF_1: "Commit Hash requirement temporarily disabled"
  # checkov:skip=CKV_TF_2: "Version number tag requirement temporarily disabled"
  source                   = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-aws-waf?ref=c0875272407dd5094287c021201b36f250be3806"
  web_acl_name             = "wam-acl"
  enable_ddos_protection   = true # Defaults to rule priority 2
  ddos_rate_limit          = 150
  block_non_uk_traffic     = true # Defaults to rule priority 3
  blocked_ip_rule_priority = 4
  associated_resource_arns = local.associated_load_balancers_arns

  providers = {
    aws                        = aws
    aws.modernisation-platform = aws.modernisation-platform
  }

  additional_managed_rules = [
    {
      arn             = aws_wafv2_rule_group.wam_waf_acl.arn
      override_action = "none" # respect the group's action (BLOCK). Use "count" to dry-run.
      priority        = 1      # unique; runs before managed rules at 10..15
    }
  ]

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

# Custom WAF Rule Group

resource "aws_wafv2_rule_group" "wam_waf_acl" {
  name        = "custom-wam-waf-rule-group"
  description = "A custom rule group to include additional rules to the WAF ACL"
  scope       = "REGIONAL"
  capacity    = 2

  rule {
    name     = "allow-ncsc-ip-list"
    priority = 10
    action {
      allow {}
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ncsc_waf_ip_set.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-ncsc-ip-list"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "allow-circle-ci-ip-list"
    priority = 20
    action {
      allow {}
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.circle_ci_waf_ip_set.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-circle-ci-ip-list"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "custom-wam-waf-rule-group"
    sampled_requests_enabled   = true
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-custom-wam-waf-rule-group-%s", local.application_name, local.environment)) }
  )
}

# WAF IP Set for NCSC WebCheck & Detectify Public IP Addresses

data "aws_ssm_parameter" "ncsc_waf_ip_set" {
  name = "ncsc_waf_ip_set"
}

locals {
  ncsc_ip_addresses = [for ip in split(",", data.aws_ssm_parameter.ncsc_waf_ip_set.value) : trim(ip, " ")]
}

resource "aws_wafv2_ip_set" "ncsc_waf_ip_set" {
  # count              = (local.is-development || local.is-preproduction || local.is-production) ? 1 : 0
  name               = "ncsc-waf-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted NCSC and Detectify IP Addresses allowing access via WAF"
  addresses          = local.ncsc_ip_addresses

  tags = merge(local.tags,
    { Name = lower(format("%s-ncsc-waf-ip-set-%s", local.application_name, local.environment)) }
  )
}

# WAF IP Set for Circle CI Public IP Addresses

data "aws_ssm_parameter" "circle_ci_waf_ip_set" {
  name = "circle_ci_waf_ip_set"
}

locals {
  circle_ci_ip_addresses = [for ip in split(",", data.aws_ssm_parameter.circle_ci_waf_ip_set.value) : trim(ip, " ")]
}

resource "aws_wafv2_ip_set" "circle_ci_waf_ip_set" {
  # count              = (local.is-development || local.is-preproduction || local.is-production) ? 1 : 0
  name               = "circle-ci-waf-ip-set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  description        = "List of trusted Circle CI IP Addresses allowing access via WAF"
  addresses          = local.circle_ci_ip_addresses

  tags = merge(local.tags,
    { Name = lower(format("%s-circle-ci-waf-ip-set-%s", local.application_name, local.environment)) }
  )
}
