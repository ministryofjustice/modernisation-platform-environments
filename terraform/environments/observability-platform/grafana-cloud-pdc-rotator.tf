locals {
  # Null in both environments until the image, credential and notification destination exist.
  gc_pdc_rotator_deployments = local.environment_configuration_gc.pdc_token_rotator == null ? {} : {
    this = local.environment_configuration_gc.pdc_token_rotator
  }

  gc_pdc_usage_datasource_uid = "grafanacloud-usage"
  gc_pdc_rotator_environment = {
    for key, config in local.gc_pdc_rotator_deployments : key => {
      GRAFANA_API_CREDENTIAL_SECRET_ARN         = config.credential_secret_arn
      GRAFANA_STACK_URL                         = grafana_cloud_stack.observability_platform.url
      GRAFANA_USAGE_DATASOURCE_UID              = local.gc_pdc_usage_datasource_uid
      GRAFANA_STACK_QUERY_CREDENTIAL_SECRET_ARN = config.stack_query_credential_secret_arn
      ROTATION_STATE_TABLE_NAME                 = aws_dynamodb_table.gc_pdc_rotation_state[key].name
    }
  }
}

resource "aws_dynamodb_table" "gc_pdc_rotation_state" {
  for_each = local.gc_pdc_rotator_deployments

  name                        = "${local.gc_pdc_rotator_role_name}-state"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "rotation_id"
  deletion_protection_enabled = true

  attribute {
    name = "rotation_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_iam_policy" "gc_pdc_rotator" {
  for_each = local.gc_pdc_rotator_deployments

  name        = local.gc_pdc_rotator_role_name
  description = "Rotate central PDC secrets and assume only opted-in tenant restart roles"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RotatePdcSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
        ]
        Resource = [for secret in aws_secretsmanager_secret.gc_pdc_token : secret.arn]
      },
      {
        Sid      = "ReadGrafanaCredential"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [each.value.credential_secret_arn]
      },
      {
        Sid      = "ReadStackQueryCredential"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [each.value.stack_query_credential_secret_arn]
      },
      {
        Sid      = "UsePdcSecretKeys"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = [for key in aws_kms_key.gc_pdc_token : key.arn]
        Condition = {
          StringEquals = {
            "kms:ViaService"                  = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
            "kms:EncryptionContext:SecretARN" = [for secret in aws_secretsmanager_secret.gc_pdc_token : secret.arn]
          }
        }
      },
      {
        Sid      = "DecryptGrafanaCredential"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = [each.value.credential_kms_key_arn]
        Condition = {
          StringEquals = {
            "kms:ViaService"                  = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
            "kms:EncryptionContext:SecretARN" = each.value.credential_secret_arn
          }
        }
      },
      {
        Sid      = "DecryptStackQueryCredential"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = [each.value.stack_query_credential_kms_key_arn]
        Condition = {
          StringEquals = {
            "kms:ViaService"                  = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
            "kms:EncryptionContext:SecretARN" = each.value.stack_query_credential_secret_arn
          }
        }
      },
      {
        Sid      = "AssumeTenantRestarters"
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = values(local.gc_pdc_restarter_role_arns)
      },
      {
        Sid      = "ManageRotationJournal"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem"]
        Resource = [aws_dynamodb_table.gc_pdc_rotation_state[each.key].arn]
      },
    ]
  })

  lifecycle {
    precondition {
      condition     = length(local.gc_pdc_accounts) > 0
      error_message = "Configure the PDC rotator only in an environment with opted-in PDC accounts."
    }
    precondition {
      condition = (
        can(regex("^arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:", each.value.credential_secret_arn)) &&
        can(regex("^arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/", each.value.credential_kms_key_arn))
      )
      error_message = "The dedicated Grafana credential and its KMS key must be in this Observability Platform account and region."
    }
    precondition {
      condition = (
        each.value.stack_query_credential_secret_arn != each.value.credential_secret_arn &&
        can(regex("^arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:", each.value.stack_query_credential_secret_arn)) &&
        can(regex("^arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/", each.value.stack_query_credential_kms_key_arn))
      )
      error_message = "The stack query credential must be separate from the management credential, with its secret and KMS key in this Observability Platform account and region."
    }
  }
}

#tfsec:ignore:avd-aws-0057 Public Grafana Cloud APIs require internet access; no tenant VPC access is needed.
module "grafana_pdc_token_rotator" {
  for_each = local.gc_pdc_rotator_deployments

  source  = "terraform-aws-modules/lambda/aws"
  version = "7.20.1"

  function_name = local.gc_pdc_rotator_role_name
  role_name     = local.gc_pdc_rotator_role_name
  role_path     = "/"
  description   = "Rotates Grafana Cloud PDC tokens in the central Observability Platform account"
  package_type  = "Image"
  image_uri     = each.value.image_uri
  memory_size   = 512
  timeout       = 900
  tags          = local.tags

  create_package                    = false
  publish                           = true
  cloudwatch_logs_retention_in_days = 90
  reserved_concurrent_executions    = 1
  attach_policy                     = true
  policy                            = aws_iam_policy.gc_pdc_rotator[each.key].arn

  environment_variables = local.gc_pdc_rotator_environment[each.key]

  # Secrets Manager invokes the unqualified function, not an immutable published version.
  create_current_version_allowed_triggers = false
  allowed_triggers = {
    for account_name, secret in aws_secretsmanager_secret.gc_pdc_token : account_name => {
      principal      = "secretsmanager.amazonaws.com"
      source_account = data.aws_caller_identity.current.account_id
      source_arn     = secret.arn
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "gc_pdc_rotator_errors" {
  for_each = local.gc_pdc_rotator_deployments

  alarm_name          = "${local.gc_pdc_rotator_role_name}-errors"
  alarm_description   = "PDC token rotation failed; recover before the current token expires"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [each.value.failure_topic_arn]
  dimensions = {
    FunctionName = module.grafana_pdc_token_rotator[each.key].lambda_function_name
  }

  lifecycle {
    precondition {
      condition     = can(regex("^arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:", each.value.failure_topic_arn))
      error_message = "PDC rotation requires an operational SNS failure destination in this account and region."
    }
  }
}

resource "aws_cloudwatch_event_rule" "gc_pdc_rotation_failed" {
  for_each = local.gc_pdc_rotator_deployments

  name        = "${local.gc_pdc_rotator_role_name}-rotation-failed"
  description = "Alert on Secrets Manager rotation failures in this account, including failures before Lambda runs"
  event_pattern = jsonencode({
    source        = ["aws.secretsmanager"]
    "detail-type" = ["AWS Service Event via CloudTrail"]
    detail = {
      eventSource = ["secretsmanager.amazonaws.com"]
      eventName   = ["RotationFailed"]
    }
  })
}

resource "aws_cloudwatch_event_target" "gc_pdc_rotation_failed" {
  for_each = local.gc_pdc_rotator_deployments

  rule      = aws_cloudwatch_event_rule.gc_pdc_rotation_failed[each.key].name
  target_id = "notify-rotation-failure"
  arn       = each.value.failure_topic_arn
}
