module "shield" {
  source = "../../modules/shield_advanced_v6"

  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }

  application_name = local.application_name

  enable_logging = true

  resources = {
    alb = {
      arn = aws_lb.external.arn
    }
  }

  waf_acl_rules = {
    AWSManagedRulesCommonRuleSet = {
      "action"    = "count"
      "name"      = "AWSManagedRulesCommonRuleSet"
      "priority"  = 0
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
      "action"    = "count"
      "name"      = "AWSManagedRulesSQLiRuleSet"
      "priority"  = 1
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
  split_arn = split("regional/webacl/", data.external.shield_waf.result["arn"])[1]
  name      = data.external.shield_waf.result["name"]
  id        = split("/", local.split_arn)[1]
  scope     = "REGIONAL"

}
import {
  id = "${local.id}/${local.name}/${local.scope}"
  to = module.shield.aws_wafv2_web_acl.main
}
