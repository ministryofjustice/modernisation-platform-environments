data "aws_iam_role" "srt_access" {
  name = "AWSSRTSupport"
}

data "external" "shield_protections" {
  program = [
    "bash", "-c",
    "aws shield list-protections --output json | jq -c '.Protections | map({(.Id): (. | tostring)}) | add'"
  ]
}

data "external" "shield_waf" {
  program = [
    "bash", "-c",
    "aws wafv2 list-web-acls --scope REGIONAL --output json | jq -c '{arn: .WebACLs[] | select(.Name | contains(\"FMManagedWebACL\")) | .ARN, name: .WebACLs[] | select(.Name | contains(\"FMManagedWebACL\")) | .Name}'"
  ]
}

locals {
  shield_protections_json = {
    for k, v in data.external.shield_protections.result : k => v
  }

  shield_protections = {
    for k, v in local.shield_protections_json : k => jsondecode(v)
    if !(contains(var.excluded_protections, k)) &&
    !can(regex("eipalloc", jsondecode(v)["ResourceArn"]))
  }
}

resource "aws_shield_drt_access_role_arn_association" "main" {
  role_arn = data.aws_iam_role.srt_access.arn
}

resource "aws_shield_application_layer_automatic_response" "this" {
  for_each     = { for k, v in var.resources : k => v if lookup(v, "protection", null) != null }
  resource_arn = each.value["arn"]
  action       = upper(each.value["action"])
}

resource "aws_wafv2_web_acl_association" "this" {
  for_each     = local.shield_protections
  resource_arn = each.value["ResourceArn"]
  web_acl_arn  = data.external.shield_waf.result["arn"]
}

resource "aws_wafv2_web_acl" "main" {
  #checkov:skip=CKV_AWS_192: Log4J handled by remediation rule
  #checkov:skip=CKV2_AWS_31:  Logging not required at this time
  name  = data.external.shield_waf.result["name"]
  scope = "REGIONAL"
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = data.external.shield_waf.result["name"]
    sampled_requests_enabled   = false
  }
  dynamic "rule" {
    for_each = var.waf_acl_rules
    content {
      name     = rule.value["name"]
      priority = rule.value["priority"]
      dynamic "action" {
        for_each = rule.value["action"] == "count" ? [1] : []
        content {
          count {}
        }
      }
      dynamic "action" {
        for_each = rule.value["action"] == "block" ? [1] : []
        content {
          block {}
        }
      }
      statement {
        rate_based_statement {
          aggregate_key_type    = "IP"
          evaluation_window_sec = 300
          limit                 = rule.value["threshold"]
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value["action"]
        sampled_requests_enabled   = true
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "waf" {
  count = var.enable_logging ? 1 : 0
  name              = "aws-waf-logs-${data.external.shield_waf.result["name"]}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_wafv2_web_acl_logging_configuration" "waf" {
  count                   = var.enable_logging ? 1 : 0
  log_destination_configs = try([aws_cloudwatch_log_group.waf[0].arn], [])
  resource_arn            = aws_wafv2_web_acl.main.arn
}
