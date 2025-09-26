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
    "aws wafv2 list-web-acls --scope REGIONAL --output json | jq -c '[.WebACLs[] | select(.Name | startswith(\"FMManagedWebACL\"))] | sort_by(.Name) | .[0] | {arn: .ARN, name: .Name}'"
  ]
}


data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


data "aws_secretsmanager_secret" "environment_management" {
  provider = aws.modernisation-platform
  name     = "environment_management"
}

data "aws_secretsmanager_secret_version" "environment_management" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.environment_management.id
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

locals {
  environment_management               = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)
  core_logging_account_id              = local.environment_management.account_ids["core-logging-production"]
  core_logging_cw_destination_arn      = "arn:aws:logs:eu-west-2:${local.core_logging_account_id}:destination:waf-logs-destination"
  core_logging_cw_destination_resource = "arn:aws:logs:eu-west-2:${local.core_logging_account_id}:destination/waf-logs-destination"
}

resource "aws_kms_key" "waf_logs" {
  #checkov:skip=CKV2_AWS_64: "KMS key policy is defined via separate aws_kms_key_policy resource"
  count                   = var.enable_logging ? 1 : 0
  description             = "KMS key for encrypting WAF CloudWatch logs"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = {
    Name = "waf-logs-kms-key"
  }
}

resource "aws_kms_alias" "waf_logs" {
  count         = var.enable_logging ? 1 : 0
  name          = "alias/waf-logs-kms-key"
  target_key_id = aws_kms_key.waf_logs[0].key_id
}

resource "aws_kms_key_policy" "waf_logs" {
  count  = var.enable_logging ? 1 : 0
  key_id = aws_kms_key.waf_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsAccess"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:aws-waf-logs-${data.external.shield_waf.result["name"]}"
          }
        }
      },
      {
        Sid    = "AllowCoreLoggingCrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.core_logging_account_id}:root"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "logs.${data.aws_region.current.region}.amazonaws.com"
          }
        }
      }
    ]
  })
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
  count             = var.enable_logging ? 1 : 0
  name              = "aws-waf-logs-${data.external.shield_waf.result["name"]}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.enable_logging ? aws_kms_key.waf_logs[0].arn : null
}

resource "aws_wafv2_web_acl_logging_configuration" "waf" {
  count                   = var.enable_logging ? 1 : 0
  log_destination_configs = try([aws_cloudwatch_log_group.waf[0].arn], [])
  resource_arn            = aws_wafv2_web_acl.main.arn
}

resource "aws_iam_role" "cwl_to_core_logging" {
  count = var.enable_logging ? 1 : 0
  name  = "CWLtoCoreLogging"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "logs.eu-west-2.amazonaws.com"
      },
      Action = "sts:AssumeRole",
      Condition = {
        StringLike = {
          "aws:SourceArn" = [
            "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"
          ]
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "cwl_to_core_logging_policy" {
  count = var.enable_logging ? 1 : 0

  name = "Permissions-Policy-For-CWL"
  role = aws_iam_role.cwl_to_core_logging[0].name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["logs:PutSubscriptionFilter"],
      Resource = local.core_logging_cw_destination_resource
    }]
  })
}

resource "aws_cloudwatch_log_subscription_filter" "waf_to_core_logging" {
  count           = var.enable_logging ? 1 : 0
  name            = "waf-to-core-logging"
  log_group_name  = aws_cloudwatch_log_group.waf[0].name
  filter_pattern  = "{$.action = * }"
  destination_arn = local.core_logging_cw_destination_arn
  role_arn        = aws_iam_role.cwl_to_core_logging[0].arn

  depends_on = [aws_cloudwatch_log_group.waf]
}

output "core_logging_cw_destination_arn" {
  value     = local.core_logging_cw_destination_arn
  sensitive = true
}