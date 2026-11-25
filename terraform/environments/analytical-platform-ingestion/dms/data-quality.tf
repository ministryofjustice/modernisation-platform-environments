locals {
  # Deadlines (UTC) leave headroom over typical prod run times; Tariff dev loads at 06:30 after the source's shutdown window
  dms_data_quality_pipelines = {
    (local.tariff.short_resource_name) = {
      task_arn       = module.cica_dms_tariff_dms_implementation.dms_full_load_task_arn
      deadline       = local.environment == "development" ? "07:30" : "01:30"
      exclude_tables = []
    }
    (local.tempus.CaseWork.short_resource_name) = {
      task_arn       = module.cica_dms_tempus_dms_implementation["CaseWork"].dms_full_load_task_arn
      deadline       = "01:30"
      exclude_tables = []
    }
    (local.tempus.SPPProcessPlatform.short_resource_name) = {
      task_arn       = module.cica_dms_tempus_dms_implementation["SPPProcessPlatform"].dms_full_load_task_arn
      deadline       = "06:00"
      exclude_tables = []
    }
    (local.tempus.SPPFinishedJobs.short_resource_name) = {
      task_arn       = module.cica_dms_tempus_dms_implementation["SPPFinishedJobs"].dms_full_load_task_arn
      deadline       = "09:00"
      exclude_tables = []
    }
  }

  # Dev 11:00 is a temporary same-day test; set back to "09:00" before merging
  dms_data_quality_digest_time = local.environment == "development" ? "11:00" : "09:00"
  dms_data_quality_task_arns   = [for pipeline in local.dms_data_quality_pipelines : pipeline.task_arn]
}

module "dms_data_quality_sns_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.0"

  aliases               = ["dms/data-quality-sns-alerts"]
  description           = "Encrypts the DMS data quality alerts SNS topic"
  enable_default_policy = true
  key_statements = [
    {
      sid       = "AllowEventBridge"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["events.amazonaws.com"]
        }
      ]
    }
  ]
  deletion_window_in_days = 7

  tags = local.tags
}

resource "aws_sns_topic" "dms_data_quality" {
  name              = "dms-data-quality"
  kms_master_key_id = module.dms_data_quality_sns_kms.key_arn
  tags              = local.tags
}

data "aws_iam_policy_document" "dms_data_quality_topic" {
  statement {
    effect    = "Allow"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.dms_data_quality.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.dms_data_quality_alarms.arn]
    }
  }
}

resource "aws_sns_topic_policy" "dms_data_quality" {
  arn    = aws_sns_topic.dms_data_quality.arn
  policy = data.aws_iam_policy_document.dms_data_quality_topic.json
}

data "aws_secretsmanager_secret_version" "dms_slack_webhook" {
  secret_id = module.cica_dms_slack_webhook.secret_id
}

resource "aws_sns_topic_subscription" "dms_data_quality_slack" {
  topic_arn = aws_sns_topic.dms_data_quality.arn
  protocol  = "https"
  endpoint  = data.aws_secretsmanager_secret_version.dms_slack_webhook.secret_string
}

data "aws_iam_policy_document" "dms_data_quality_lambda" {
  #checkov:skip=CKV_AWS_356:DescribeReplicationTasks and CloudWatch metric APIs do not support resource-level permissions
  statement {
    actions   = ["dms:DescribeReplicationTasks"]
    resources = ["*"]
  }

  statement {
    actions   = ["dms:DescribeTableStatistics"]
    resources = local.dms_data_quality_task_arns
  }

  statement {
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["DMS/DataQuality"]
    }
  }

  statement {
    actions   = ["cloudwatch:GetMetricData"]
    resources = ["*"]
  }

  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.dms_data_quality.arn]
  }

  statement {
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    resources = [module.dms_data_quality_sns_kms.key_arn]
  }
}

module "dms_data_quality_lambda" {
  # Commit hash for v7.20.1
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=84dfbfddf9483bc56afa0aff516177c03652f0c7"

  function_name   = "dms-data-quality"
  description     = "Checks DMS full loads for row count drops, slow loads and missed deadlines, and posts a daily summary"
  handler         = "main.handler"
  runtime         = "python3.14"
  memory_size     = 256
  timeout         = 420
  architectures   = ["x86_64"]
  build_in_docker = false
  source_path     = "${path.module}/lambda-functions/data_quality/main.py"

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.dms_data_quality_lambda.json

  cloudwatch_logs_retention_in_days = 90

  environment_variables = {
    PIPELINES                    = jsonencode(local.dms_data_quality_pipelines)
    ALERTS_TOPIC_ARN             = aws_sns_topic.dms_data_quality.arn
    ROW_DROP_PERCENT             = "20"
    ROW_DROP_MIN_ROWS            = "1000"
    DURATION_OVERRUN_PERCENT     = "50"
    DURATION_OVERRUN_MIN_MINUTES = "10"
  }

  publish = true # Needed by allowed_triggers https://github.com/terraform-aws-modules/terraform-aws-lambda/issues/36#issuecomment-650217274
  allowed_triggers = merge(
    {
      TaskFinished = {
        principal  = "events.amazonaws.com"
        source_arn = aws_cloudwatch_event_rule.dms_data_quality_task_finished.arn
      }
      Digest = {
        principal  = "events.amazonaws.com"
        source_arn = aws_cloudwatch_event_rule.dms_data_quality_digest.arn
      }
    },
    {
      for pipeline, rule in aws_cloudwatch_event_rule.dms_data_quality_deadline : "Deadline-${pipeline}" => {
        principal  = "events.amazonaws.com"
        source_arn = rule.arn
      }
    }
  )

  tags = local.tags
}

resource "aws_cloudwatch_event_rule" "dms_data_quality_task_finished" {
  name        = "dms-data-quality-task-finished"
  description = "DMS full loads that finished successfully, for row count and duration checks"

  event_pattern = jsonencode({
    source        = ["aws.dms"]
    "detail-type" = ["DMS Replication Task State Change"]
    resources     = local.dms_data_quality_task_arns
    detail = {
      detailMessage = [{ wildcard = "*FULL_LOAD_ONLY_FINISHED*" }]
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "dms_data_quality_task_finished" {
  rule      = aws_cloudwatch_event_rule.dms_data_quality_task_finished.name
  target_id = "dms-data-quality"
  arn       = module.dms_data_quality_lambda.lambda_function_arn
}

resource "aws_cloudwatch_event_rule" "dms_data_quality_deadline" {
  for_each = local.dms_data_quality_pipelines

  name                = "dms-data-quality-deadline-${each.key}"
  description         = "Alerts if ${each.key} has not finished by ${each.value.deadline} UTC"
  schedule_expression = "cron(${tonumber(split(":", each.value.deadline)[1])} ${tonumber(split(":", each.value.deadline)[0])} * * ? *)"

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "dms_data_quality_deadline" {
  for_each = aws_cloudwatch_event_rule.dms_data_quality_deadline

  rule      = each.value.name
  target_id = "dms-data-quality"
  arn       = module.dms_data_quality_lambda.lambda_function_arn
  input     = jsonencode({ action = "deadline", pipeline = each.key })
}

resource "aws_cloudwatch_event_rule" "dms_data_quality_digest" {
  name                = "dms-data-quality-digest"
  description         = "Daily summary of DMS full loads at ${local.dms_data_quality_digest_time} UTC"
  schedule_expression = "cron(${tonumber(split(":", local.dms_data_quality_digest_time)[1])} ${tonumber(split(":", local.dms_data_quality_digest_time)[0])} * * ? *)"

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "dms_data_quality_digest" {
  rule      = aws_cloudwatch_event_rule.dms_data_quality_digest.name
  target_id = "dms-data-quality"
  arn       = module.dms_data_quality_lambda.lambda_function_arn
  input     = jsonencode({ action = "digest" })
}

# Alarm names must start with "dms-data-quality-" so aws_cloudwatch_event_rule.dms_data_quality_alarms forwards them to Slack
resource "aws_cloudwatch_metric_alarm" "dms_data_quality_lambda_errors" {
  alarm_name          = "dms-data-quality-lambda-errors"
  alarm_description   = "DMS data quality Lambda failed, so row count, duration, deadline or summary checks may not have run. Check log group /aws/lambda/${module.dms_data_quality_lambda.lambda_function_name}."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = module.dms_data_quality_lambda.lambda_function_name
  }

  tags = local.tags
}

resource "aws_cloudwatch_event_rule" "dms_data_quality_alarms" {
  name        = "dms-data-quality-alarms"
  description = "DMS data quality CloudWatch alarms entering ALARM state"

  event_pattern = jsonencode({
    source        = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    resources     = [{ prefix = "arn:aws:cloudwatch:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:alarm:dms-data-quality-" }]
    detail = {
      state = { value = ["ALARM"] }
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "dms_data_quality_alarms" {
  rule      = aws_cloudwatch_event_rule.dms_data_quality_alarms.name
  target_id = "DMSDataQualityAlarmToSNS"
  arn       = aws_sns_topic.dms_data_quality.arn

  input_transformer {
    input_paths = {
      alarm       = "$.detail.alarmName"
      description = "$.detail.configuration.description"
      reason      = "$.detail.state.reason"
    }
    input_template = <<TEMPLATE
"🚨 <alarm>"
"<description>"
"<reason>"
TEMPLATE
  }
}
