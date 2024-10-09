# resource "aws_wafv2_web_acl" "this" {
#   name        = "${local.application_name}-acl"
#   description = "Web ACL for ${local.application_name}"
#   scope       = "REGIONAL"
#   default_action {
#     allow {}
#   }
#   rule {
#     name     = "AWSManagedRulesCommonRuleSet"
#     priority = 0
#     override_action {
#       # Dont do anything but count requests that match the rules in the ruleset
#       count {}
#     }
#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesCommonRuleSet"
#         vendor_name = "AWS"
#       }
#     }
#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "${local.application_name}-common-ruleset"
#       sampled_requests_enabled   = true
#     }
#   }
#   rule {
#     name     = "AWSManagedRulesSQLiRuleSet"
#     priority = 1
#     override_action {
#       # Dont do anything but count requests that match the rules in the ruleset
#       count {}
#     }
#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesSQLiRuleSet"
#         vendor_name = "AWS"
#       }
#     }
#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "${local.application_name}-SQLi-ruleset"
#       sampled_requests_enabled   = true
#     }
#   }

#   tags = local.tags
#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name                = "${local.application_name}-waf-metrics"
#     sampled_requests_enabled   = true
#   }
# }
# resource "aws_wafv2_web_acl_association" "this" {
#   resource_arn = aws_lb.external.arn
#   web_acl_arn  = aws_wafv2_web_acl.this.arn
# }

# resource "aws_cloudwatch_log_group" "waf" {
#   name              = "aws-waf-logs-${local.application_name}"
#   retention_in_days = 60
#   tags              = local.tags
# }
# resource "aws_wafv2_web_acl_logging_configuration" "waf" {
#   log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
#   resource_arn            = aws_wafv2_web_acl.this.arn
# }

module "shield" {
  source = "../../modules/shield_advanced"

  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }

  application_name = local.application_name

  resources = {
    alb = {
      arn = aws_lb.external.arn
    }
  }

  waf_acl_rules = {
    AWSManagedRulesCommonRuleSet = {
      "action" = "count"
      "name"   = "AWSManagedRulesCommonRuleSet"
      "priority" = 0
      "threshold" = 1000
      "statement" = {
        "managed_rule_group_statement" = {
          "name"        = "AWSManagedRulesCommonRuleSet"
          "vendor_name" = "AWS"
        }
      }
      "visibility_config" = {
        "cloudwatch_metrics_enabled" = true
        "metric_name"                = "${local.application_name}-common-ruleset"
        "sampled_requests_enabled"   = true
      }
    }
    AWSManagedRulesSQLiRuleSet = {
      "action" = "count"
      "name"   = "AWSManagedRulesSQLiRuleSet"
      "priority" = 1
      "threshold" = 1000
      "statement" = {
        "managed_rule_group_statement" = {
          "name"        = "AWSManagedRulesSQLiRuleSet"
          "vendor_name" = "AWS"
        }
      }
      "visibility_config" = {
        "cloudwatch_metrics_enabled" = true
        "metric_name"                = "${local.application_name}-SQLi-ruleset"
        "sampled_requests_enabled"   = true
      }
    }
  }

}

data "external" "shield_waf" {
  program = [
    "bash", "-c",
    "aws wafv2 list-web-acls --scope REGIONAL --output json | jq -c '{arn: .WebACLs[] | select(.Name | contains(\"FMManagedWebACL\")) | .ARN, name: .WebACLs[] | select(.Name | contains(\"FMManagedWebACL\")) | .Name}'"
  ]
}

locals {
  arn = split("regional/webacl/", data.external.shield_waf.result["arn"])[1]
  name = data.external.shield_waf.result["name"]
  id = split("/", local.arn)[1]
  scope = "REGIONAL"

}
import {
  id = "${local.id}/${local.name}/${local.scope}"
  to = module.shield.aws_wafv2_web_acl.main
}
