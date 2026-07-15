locals {
  observability_configuration = merge(
    {
      api_gateway_latency_threshold_ms       = 5000
      api_gateway_latency_evaluation_periods = 2
      lambda_duration_threshold_ms           = 2000
      lambda_duration_evaluation_periods     = 2
    },
    try(local.application_data.accounts[local.environment].observability_configuration, {})
  )

  enable_alerting = local.notification_configuration != null && alltrue([
    try(local.notification_configuration.high_priority_alerts.slack_channel_id, "") != "",
    try(local.notification_configuration.high_priority_alerts.slack_team_id, "") != "",
    try(local.notification_configuration.low_priority_alerts.slack_channel_id, "") != "",
    try(local.notification_configuration.low_priority_alerts.slack_team_id, "") != "",
  ])

  cloudwatch_alarm_actions_high_priority = local.enable_alerting ? [module.sns_cloudwatch_alarms_high_priority[0].topic_arn] : []
  cloudwatch_alarm_actions_low_priority  = local.enable_alerting ? [module.sns_cloudwatch_alarms_low_priority[0].topic_arn] : []

  cloudwatch_lambda_alarms = {
    "upload-ticket" = {
      alarm_name_prefix = "${local.resource_name_prefix}-upload-ticket"
      description       = "Upload ticket Lambda"
      function_name     = module.lambda_upload_ticket.lambda_function_name
    }
    "authorizer" = {
      alarm_name_prefix = "${local.resource_name_prefix}-authorizer"
      description       = "Request authorizer Lambda"
      function_name     = module.lambda_api_authorizer.lambda_function_name
    }
    "docs" = {
      alarm_name_prefix = "${local.resource_name_prefix}-docs"
      description       = "Swagger UI docs Lambda"
      function_name     = module.lambda_api_docs.lambda_function_name
    }
  }
}

module "kms_cloudwatch_logs" {
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["integration-hub-api/logs/${local.component_name}"]
  description             = "KMS CMK for Integration Hub API CloudWatch Logs encryption"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true

  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  key_statements = [
    {
      sid = "AllowCloudWatchLogsService"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
        }
      ]
      condition = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"]
        }
      ]
    },
    {
      sid = "AllowCloudWatchLogsAssociationCallers"
      actions = [
        "kms:DescribeKey",
      ]
      resources = ["*"]
      principals = [
        {
          type = "AWS"
          identifiers = [
            "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/github-actions-apply",
            "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/github-actions-plan",
            "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/MemberInfrastructureAccess",
            "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/${var.collaborator_access}",
          ]
        }
      ]
      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["logs.${data.aws_region.current.region}.amazonaws.com"]
        }
      ]
    },
    {
      sid = "AllowPlatformUsersToReadEncryptedLogs"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      condition = [
        {
          test     = "ArnLike"
          variable = "aws:PrincipalArn"
          values = [
            "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess",
            "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/${var.collaborator_access}",
            "arn:aws:iam::${local.environment_management.account_ids[terraform.workspace]}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.region}/AWSReservedSSO_*",
          ]
        },
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["logs.${data.aws_region.current.region}.amazonaws.com"]
        }
      ]
    }
  ]

  tags = local.tags
}

module "kms_sns" {
  count   = local.enable_alerting ? 1 : 0
  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases                 = ["integration-hub-api/sns/${local.component_name}"]
  description             = "KMS CMK for Integration Hub API SNS alarm encryption"
  enable_default_policy   = true
  enable_key_rotation     = true
  deletion_window_in_days = 30
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true

  key_administrators = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  key_statements = [
    {
      sid = "AllowCloudWatchAlarmPublishers"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*",
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["cloudwatch.amazonaws.com"]
        }
      ]
    },
    {
      sid = "AllowSNSService"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["sns.amazonaws.com"]
        }
      ]
      condition = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:sns:topicArn"
          values   = ["arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
        }
      ]
    }
  ]

  tags = local.tags
}

module "sns_cloudwatch_alarms_high_priority" {
  count   = local.enable_alerting ? 1 : 0
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.0"

  name              = "${local.resource_name_prefix}-cloudwatch-alarms-high-priority"
  kms_master_key_id = module.kms_sns[0].key_arn

  topic_policy_statements = {
    cloudwatch_publish = {
      sid     = "AllowCloudWatchAlarmsPublish"
      actions = ["sns:Publish"]
      principals = [{
        type        = "Service"
        identifiers = ["cloudwatch.amazonaws.com"]
      }]
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
    chatbot_consume = {
      sid = "AllowChatbotToConsume"
      actions = [
        "sns:Subscribe",
        "sns:Receive",
        "sns:Publish",
      ]
      principals = [{
        type = "Service"
        identifiers = [
          "sns.amazonaws.com",
          "events.amazonaws.com",
          "chatbot.amazonaws.com",
        ]
      }]
    }
  }

  tags = local.tags
}

module "sns_cloudwatch_alarms_low_priority" {
  count   = local.enable_alerting ? 1 : 0
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.0"

  name              = "${local.resource_name_prefix}-cloudwatch-alarms-low-priority"
  kms_master_key_id = module.kms_sns[0].key_arn

  topic_policy_statements = {
    cloudwatch_publish = {
      sid     = "AllowCloudWatchAlarmsPublish"
      actions = ["sns:Publish"]
      principals = [{
        type        = "Service"
        identifiers = ["cloudwatch.amazonaws.com"]
      }]
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
    chatbot_consume = {
      sid = "AllowChatbotToConsume"
      actions = [
        "sns:Subscribe",
        "sns:Receive",
        "sns:Publish",
      ]
      principals = [{
        type = "Service"
        identifiers = [
          "sns.amazonaws.com",
          "events.amazonaws.com",
          "chatbot.amazonaws.com",
        ]
      }]
    }
  }

  tags = local.tags
}

module "chatbot_cloudwatch_alarms_high_priority" {
  count  = local.enable_alerting ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  application_name = "${local.resource_name_prefix}-cloudwatch-alarms-high-priority"
  slack_channel_id = local.notification_configuration.high_priority_alerts.slack_channel_id
  slack_team_id    = local.notification_configuration.high_priority_alerts.slack_team_id
  sns_topic_arns   = [module.sns_cloudwatch_alarms_high_priority[0].topic_arn]
  tags             = local.tags
}

module "chatbot_cloudwatch_alarms_low_priority" {
  count  = local.enable_alerting ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  application_name = "${local.resource_name_prefix}-cloudwatch-alarms-low-priority"
  slack_channel_id = local.notification_configuration.low_priority_alerts.slack_channel_id
  slack_team_id    = local.notification_configuration.low_priority_alerts.slack_team_id
  sns_topic_arns   = [module.sns_cloudwatch_alarms_low_priority[0].topic_arn]
  tags             = local.tags
}

module "cloudwatch_api_gateway_5xx" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${local.resource_name_prefix}-api-gateway-5xx"
  alarm_description   = "Integration Hub API Gateway is returning server errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xx"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_high_priority
  ok_actions          = local.cloudwatch_alarm_actions_high_priority

  dimensions = {
    ApiId = aws_apigatewayv2_api.upload_ticket.id
    Stage = aws_apigatewayv2_stage.default.name
  }

  tags = local.tags
}

module "cloudwatch_api_gateway_latency" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${local.resource_name_prefix}-api-gateway-latency"
  alarm_description   = "Integration Hub API Gateway latency is above the expected threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.observability_configuration.api_gateway_latency_evaluation_periods
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = local.observability_configuration.api_gateway_latency_threshold_ms
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_low_priority
  ok_actions          = local.cloudwatch_alarm_actions_low_priority

  dimensions = {
    ApiId = aws_apigatewayv2_api.upload_ticket.id
    Stage = aws_apigatewayv2_stage.default.name
  }

  tags = local.tags
}

module "cloudwatch_lambda_errors" {
  for_each = local.cloudwatch_lambda_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${each.value.alarm_name_prefix}-errors"
  alarm_description   = "${each.value.description} returned one or more errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_high_priority
  ok_actions          = local.cloudwatch_alarm_actions_high_priority

  dimensions = {
    FunctionName = each.value.function_name
  }

  tags = local.tags
}

module "cloudwatch_lambda_throttles" {
  for_each = local.cloudwatch_lambda_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${each.value.alarm_name_prefix}-throttles"
  alarm_description   = "${each.value.description} is throttling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_high_priority
  ok_actions          = local.cloudwatch_alarm_actions_high_priority

  dimensions = {
    FunctionName = each.value.function_name
  }

  tags = local.tags
}

module "cloudwatch_lambda_duration" {
  for_each = local.cloudwatch_lambda_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${each.value.alarm_name_prefix}-duration"
  alarm_description   = "${each.value.description} duration is above the expected threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.observability_configuration.lambda_duration_evaluation_periods
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = local.observability_configuration.lambda_duration_threshold_ms
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_low_priority
  ok_actions          = local.cloudwatch_alarm_actions_low_priority

  dimensions = {
    FunctionName = each.value.function_name
  }

  tags = local.tags
}

resource "aws_cloudwatch_dashboard" "api_platform" {
  dashboard_name = "${local.resource_name_prefix}-${local.environment}-overview"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "API Gateway Requests and Errors"
          region  = data.aws_region.current.region
          view    = "timeSeries"
          stacked = false
          period  = 300
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiId", aws_apigatewayv2_api.upload_ticket.id, "Stage", aws_apigatewayv2_stage.default.name],
            [".", "4xx", ".", ".", ".", ".", { "yAxis" : "right" }],
            [".", "5xx", ".", ".", ".", ".", { "yAxis" : "right" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "API Gateway Latency"
          region  = data.aws_region.current.region
          view    = "timeSeries"
          stacked = false
          period  = 300
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiId", aws_apigatewayv2_api.upload_ticket.id, "Stage", aws_apigatewayv2_stage.default.name],
            [".", "IntegrationLatency", ".", ".", ".", "."]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Lambda Errors and Throttles"
          region  = data.aws_region.current.region
          view    = "timeSeries"
          stacked = false
          period  = 300
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", module.lambda_upload_ticket.lambda_function_name],
            [".", "Errors", ".", module.lambda_api_authorizer.lambda_function_name],
            [".", "Errors", ".", module.lambda_api_docs.lambda_function_name],
            [".", "Throttles", ".", module.lambda_upload_ticket.lambda_function_name, { "yAxis" : "right" }],
            [".", "Throttles", ".", module.lambda_api_authorizer.lambda_function_name, { "yAxis" : "right" }],
            [".", "Throttles", ".", module.lambda_api_docs.lambda_function_name, { "yAxis" : "right" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Lambda Duration and Invocations"
          region  = data.aws_region.current.region
          view    = "timeSeries"
          stacked = false
          period  = 300
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", module.lambda_upload_ticket.lambda_function_name],
            [".", "Duration", ".", module.lambda_api_authorizer.lambda_function_name],
            [".", "Duration", ".", module.lambda_api_docs.lambda_function_name],
            [".", "Invocations", ".", module.lambda_upload_ticket.lambda_function_name, { "yAxis" : "right" }],
            [".", "Invocations", ".", module.lambda_api_authorizer.lambda_function_name, { "yAxis" : "right" }],
            [".", "Invocations", ".", module.lambda_api_docs.lambda_function_name, { "yAxis" : "right" }]
          ]
        }
      }
    ]
  })
}
