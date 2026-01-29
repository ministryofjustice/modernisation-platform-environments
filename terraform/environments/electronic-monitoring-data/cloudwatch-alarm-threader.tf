# ------------------------------------------------------------------------------
# Incident-threaded Slack notifications for CloudWatch alarms (Amazon Q/Chatbot)
#
# - Triggered by EventBridge "CloudWatch Alarm State Change"
# - Uses S3 as state store: alarm-threading/current/<env>/<alarm_name>.json
# - Publishes Amazon Q custom notifications to the existing emds_alerts SNS topic
# ------------------------------------------------------------------------------

locals {
  # State bucket per environment (logs buckets)
  alarm_thread_state_bucket = {
    dev     = "emds-dev-bucket-logs-20240917140510319000000006"
    test    = "emds-test-bucket-logs-2024092309592738660000000b"
    preprod = "emds-preprod-bucket-logs-2024110511092940930000000a"
    prod    = "emds-prod-bucket-logs-20240918073115961600000004"
  }[local.environment_shorthand]

  alarm_thread_state_prefix = "alarm-threading/current"
}

# ------------------------------------------------------------------------------
# IAM role + policy for the alarm threader lambda
# ------------------------------------------------------------------------------

resource "aws_iam_role" "cloudwatch_alarm_threader" {
  name               = "cloudwatch_alarm_threader_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "cloudwatch_alarm_threader_policy_document" {
  statement {
    sid    = "S3StateAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${local.alarm_thread_state_bucket}/${local.alarm_thread_state_prefix}/${local.environment_shorthand}/*"
    ]
  }

  statement {
    sid    = "AllowPublishToAlertsTopic"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [aws_sns_topic.emds_alerts.arn]
  }

  # Topic is KMS-encrypted; to match the pattern used by mdss_daily_failure_digest
  statement {
    sid    = "AllowUseOfAlertsKmsKey"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:GenerateDataKey*",
      "kms:Decrypt",
    ]
    resources = [aws_kms_key.emds_alerts.arn]
  }
}

resource "aws_iam_policy" "cloudwatch_alarm_threader" {
  name   = "cloudwatch_alarm_threader_lambda_policy"
  policy = data.aws_iam_policy_document.cloudwatch_alarm_threader_policy_document.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_alarm_threader_attach" {
  role       = aws_iam_role.cloudwatch_alarm_threader.name
  policy_arn = aws_iam_policy.cloudwatch_alarm_threader.arn
}

# ------------------------------------------------------------------------------
# Lambda: cloudwatch_alarm_threader
# ------------------------------------------------------------------------------

module "cloudwatch_alarm_threader" {
  source                         = "./modules/lambdas"
  is_image                       = true
  function_name                  = "cloudwatch_alarm_threader"
  role_name                      = aws_iam_role.cloudwatch_alarm_threader.name
  role_arn                       = aws_iam_role.cloudwatch_alarm_threader.arn
  handler                        = "cloudwatch_alarm_threader.handler"
  memory_size                    = 512
  timeout                        = 60
  reserved_concurrent_executions = 1

  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  production_dev          = local.is-production ? "prod" : local.is-preproduction ? "preprod" : local.is-test ? "test" : "dev"

  security_group_ids = [aws_security_group.lambda_generic.id]
  subnet_ids         = data.aws_subnets.shared-public.ids

  environment_variables = {
    SNS_TOPIC_ARN         = aws_sns_topic.emds_alerts.arn
    STATE_BUCKET          = local.alarm_thread_state_bucket
    STATE_PREFIX          = local.alarm_thread_state_prefix
    ENVIRONMENT           = local.environment_shorthand
    INCLUDE_REASON        = "true"
    ENABLE_CUSTOM_ACTIONS = "false"
  }
}

# ------------------------------------------------------------------------------
# EventBridge: CloudWatch alarm state changes -> Lambda
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "alarm_state_change_threader" {
  name        = "emds-alarm-state-change-threader-${local.environment_shorthand}"
  description = "Routes CloudWatch ALARM/OK state changes to cloudwatch_alarm_threader for incident-threaded Slack notifications"

  event_pattern = jsonencode({
    "source": ["aws.cloudwatch"],
    "detail-type": ["CloudWatch Alarm State Change"],
    "detail": {
      "alarmName": [
        aws_cloudwatch_metric_alarm.load_mdss_dlq_alarm.alarm_name,
        aws_cloudwatch_metric_alarm.clean_dlt_dlq_alarm.alarm_name,
        aws_cloudwatch_metric_alarm.glue_database_count_high.alarm_name
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "alarm_state_change_threader" {
  rule = aws_cloudwatch_event_rule.alarm_state_change_threader.name
  arn  = module.cloudwatch_alarm_threader.lambda_function_arn
}

resource "aws_lambda_permission" "alarm_state_change_threader_allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridgeAlarmStateChange"
  action        = "lambda:InvokeFunction"
  function_name = module.cloudwatch_alarm_threader.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alarm_state_change_threader.arn
}
