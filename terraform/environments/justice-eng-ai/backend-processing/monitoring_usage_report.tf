# Twice-daily Slack post of the last 5 hours of Builder and Forge CPU and memory,
# one row per interval (15 minutes by default). A state machine reads the ECS service metrics and posts
# the table to the job-completion topic, which Chatbot delivers to slack_channel_id.
# The table is built in usage_report.jsonata (JSONata), so no Lambda is needed.

locals {
  # The resources exist whenever a Slack channel is set. usage_report_enabled only
  # switches the schedule on, so a report can still be started by hand.
  usage_report_create  = local.slack_channel_id != ""
  usage_report_name    = "${local.application_name}-usage-report"
  usage_report_enabled = try(local.application_data.accounts[local.environment].usage_report_enabled, false)

  # Minutes per row. The 5-hour window is split into rows of this length, so it must
  # divide 300. Smaller values give more rows and a longer Slack message. The 12:00
  # and 17:00 runs then cover 07:00 to 12:00 and 12:00 to 17:00 with no gap.
  usage_report_window_minutes   = 300
  usage_report_interval_minutes = try(local.application_data.accounts[local.environment].usage_report_interval_minutes, 15)
  usage_report_interval_ms      = local.usage_report_interval_minutes * 60000

  # Evaluated in the schedule time zone below, so this is 12:00 and 17:00 UK time.
  usage_report_schedule = try(local.application_data.accounts[local.environment].usage_report_schedule, "cron(0 12,17 * * ? *)")

  # Both services run in the web UI cluster. The Forge name matches forge_name in
  # web-ui/forge-journey-lab.tf. The query IDs are the ones usage_report.jsonata reads.
  usage_report_services = {
    b = local.web_ui_name
    f = "forge-journey-lab"
  }
  usage_report_metrics = {
    cpu = "CPUUtilization"
    mem = "MemoryUtilization"
  }

  usage_report_queries = flatten([
    for svc_key, service in local.usage_report_services : [
      for metric_key, metric in local.usage_report_metrics : {
        Id = "${svc_key}${metric_key}"
        MetricStat = {
          Metric = {
            Namespace  = "AWS/ECS"
            MetricName = metric
            Dimensions = [
              { Name = "ClusterName", Value = local.web_ui_name },
              { Name = "ServiceName", Value = service },
            ]
          }
          Period = local.usage_report_interval_minutes * 60
          Stat   = "Maximum"
        }
        ReturnData = true
      }
    ]
  ])

  usage_report_definition = {
    Comment       = "Posts the last 5 hours of Builder and Forge CPU and memory peaks, in fixed-length buckets, to Slack."
    QueryLanguage = "JSONata"
    StartAt       = "get_metrics"
    States = {
      get_metrics = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::aws-sdk:cloudwatch:getMetricData"
        Arguments = {
          # The window ends on the last interval boundary so every bucket is complete.
          StartTime         = "{% $fromMillis($floor($toMillis($states.context.Execution.StartTime) / ${local.usage_report_interval_ms}) * ${local.usage_report_interval_ms} - ${local.usage_report_window_minutes * 60000}) %}"
          EndTime           = "{% $fromMillis($floor($toMillis($states.context.Execution.StartTime) / ${local.usage_report_interval_ms}) * ${local.usage_report_interval_ms}) %}"
          ScanBy            = "TimestampAscending"
          MetricDataQueries = local.usage_report_queries
        }
        Assign = {
          message = "{% ( $env := '${local.environment}'; $interval := ${local.usage_report_interval_minutes}; $window := ${local.usage_report_window_minutes}; ${file("${path.module}/usage_report.jsonata")} ) %}"
        }
        Retry = [{
          ErrorEquals     = ["States.TaskFailed"]
          IntervalSeconds = 10
          BackoffRate     = 2
          MaxAttempts     = 2
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Assign      = { failure = "{% $states.errorOutput %}" }
          Next        = "report_failure"
        }]
        Next = "post_to_slack"
      }

      post_to_slack = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::sns:publish"
        Arguments = {
          TopicArn = aws_sns_topic.job_completion.arn
          Message  = "{% $message %}"
        }
        End = true
      }

      # Failures go to the alerts channel so a missing report is noticed.
      report_failure = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::sns:publish"
        Arguments = {
          TopicArn = aws_sns_topic.alerts.arn
          Message  = "{% $string({'version': '1.0', 'source': 'custom', 'content': {'textType': 'client-markdown', 'title': '[${local.environment}] The CPU and memory usage report failed', 'description': $substring($string($failure.Error & ': ' & $failure.Cause), 0, 500)}}) %}"
        }
        End = true
      }
    }
  }
}

data "aws_iam_policy_document" "usage_report" {
  # checkov:skip=CKV_AWS_111: GetMetricData, logging delivery and X-Ray do not support resource-level permissions
  # checkov:skip=CKV_AWS_356: GetMetricData, logging delivery and X-Ray do not support resource-level permissions
  statement {
    sid       = "ReadMetrics"
    effect    = "Allow"
    actions   = ["cloudwatch:GetMetricData"]
    resources = ["*"]
  }

  statement {
    sid       = "Publish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.job_completion.arn, aws_sns_topic.alerts.arn]
  }

  statement {
    sid       = "UseTopicKeys"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
    resources = [aws_kms_key.job_completion.arn, aws_kms_key.alerts.arn]
  }

  statement {
    sid    = "AllowExecutionLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeResourcePolicies",
      "logs:DeleteLogDelivery",
      "logs:GetLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutLogEvents",
      "logs:PutResourcePolicy",
      "logs:UpdateLogDelivery",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowXrayTracing"
    effect = "Allow"
    actions = [
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:PutTelemetryRecords",
      "xray:PutTraceSegments",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "usage_report" {
  count = local.usage_report_create ? 1 : 0

  name               = "${local.usage_report_name}-sfn"
  assume_role_policy = data.aws_iam_policy_document.step_functions_common_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "usage_report" {
  count = local.usage_report_create ? 1 : 0

  name   = local.usage_report_name
  role   = aws_iam_role.usage_report[0].id
  policy = data.aws_iam_policy_document.usage_report.json
}

resource "aws_cloudwatch_log_group" "usage_report" {
  count = local.usage_report_create ? 1 : 0

  name              = "/aws/vendedlogs/states/${local.usage_report_name}"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_sfn_state_machine" "usage_report" {
  count = local.usage_report_create ? 1 : 0

  name       = local.usage_report_name
  role_arn   = aws_iam_role.usage_report[0].arn
  type       = "STANDARD"
  definition = jsonencode(local.usage_report_definition)
  tags       = local.tags

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.usage_report[0].arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tracing_configuration {
    enabled = true
  }

  depends_on = [aws_iam_role_policy.usage_report]

  lifecycle {
    precondition {
      condition     = local.usage_report_interval_minutes >= 1 && local.usage_report_window_minutes % local.usage_report_interval_minutes == 0
      error_message = "usage_report_interval_minutes must be a whole number of minutes that divides ${local.usage_report_window_minutes}."
    }
  }
}

data "aws_iam_policy_document" "usage_report_scheduler_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "usage_report_scheduler" {
  count = local.usage_report_create ? 1 : 0

  name               = "${local.usage_report_name}-scheduler"
  assume_role_policy = data.aws_iam_policy_document.usage_report_scheduler_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "usage_report_scheduler" {
  count = local.usage_report_create ? 1 : 0

  name = "${local.usage_report_name}-start"
  role = aws_iam_role.usage_report_scheduler[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "StartUsageReport"
      Effect   = "Allow"
      Action   = ["states:StartExecution"]
      Resource = [aws_sfn_state_machine.usage_report[0].arn]
    }]
  })
}

resource "aws_scheduler_schedule" "usage_report" {
  count = local.usage_report_create ? 1 : 0

  name                         = local.usage_report_name
  description                  = "Posts the last 5 hours of Builder and Forge CPU and memory to Slack."
  schedule_expression          = local.usage_report_schedule
  schedule_expression_timezone = "Europe/London"
  state                        = local.usage_report_enabled ? "ENABLED" : "DISABLED"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_sfn_state_machine.usage_report[0].arn
    role_arn = aws_iam_role.usage_report_scheduler[0].arn
    input    = "{}"
  }
}
