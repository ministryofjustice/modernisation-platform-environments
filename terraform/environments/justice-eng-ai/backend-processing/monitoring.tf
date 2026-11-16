# Alerting for the backend: a dedicated alerts topic delivered to Slack by the
# AWS Chatbot module in slack_notifications.tf, plus alarms for script-runner
# failures (hard errors, Step Functions) and Bedrock errors. Runtime alarms for
# the web UI and per-prototype infrastructure are in monitoring_runtime.tf.

locals {
  alerts_topic_name = "${local.application_name}-alerts"
  metric_namespace  = local.application_name
  alarm_actions     = [aws_sns_topic.alerts.arn]

  state_machine_arns = merge(
    {
      root                 = module.step_functions_root.arn
      control_plane        = module.step_functions_control_plane.arn
      control_plane_resume = module.step_functions_control_plane.resume_arn
      build_image          = module.step_functions_build_image.arn
      build_infra          = module.step_functions_build_infra.arn
    },
    { for m in module.step_functions_notify : "notify" => m.arn },
    { deploy_prototype = module.step_functions_deploy_prototype.arn },
  )

  # Bedrock errors are matched in the existing ECS logs by text. Thresholds are counts
  # within a 5 minute period. "failed" matches any failed call, so it overlaps the others.
  bedrock_error_types = {
    throttled   = { threshold = 3, pattern = "?ThrottlingException ?TooManyRequestsException ?\"Too many requests\"" }
    timeout     = { threshold = 2, pattern = "?ModelTimeoutException ?ReadTimeoutError ?\"Read timeout\"" }
    token-limit = { threshold = 1, pattern = "?\"Input is too long\" ?\"too many input tokens\" ?\"maximum context length\"" }
    failed      = { threshold = 3, pattern = "?\"Bedrock call failed\" ?\"Bedrock stream call failed\" ?\"Assessment failed\"" }
  }

  # The control plane runs in script-runner, so its logs are in the script-runner log group.
  bedrock_log_groups = merge(
    { control-plane = aws_cloudwatch_log_group.script_runner.name },
    { web-ui = data.aws_cloudwatch_log_group.web_ui.name },
  )
  bedrock_log_alarms = {
    for pair in setproduct(keys(local.bedrock_log_groups), keys(local.bedrock_error_types)) :
    "${pair[0]}-${pair[1]}" => merge(local.bedrock_error_types[pair[1]], {
      component  = pair[0]
      error_type = pair[1]
      log_group  = local.bedrock_log_groups[pair[0]]
    })
  }
}

# ---------- Alerts topic ----------

data "aws_iam_policy_document" "kms_alerts" {
  # checkov:skip=CKV_AWS_109: Key policy is attached to the key itself; account root delegates access to IAM
  # checkov:skip=CKV_AWS_111: Key policy is attached to the key itself; account root delegates access to IAM
  # checkov:skip=CKV_AWS_356: Policy is attached to a resource
  statement {
    sid    = "AllowAccountAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowAlarmsAndEventsToPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com", "events.amazonaws.com"]
    }
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_kms_key" "alerts" {
  description             = "Encrypts the ${local.application_name} alerts SNS topic"
  policy                  = data.aws_iam_policy_document.kms_alerts.json
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = local.tags
}

resource "aws_kms_alias" "alerts" {
  name          = "alias/${local.alerts_topic_name}"
  target_key_id = aws_kms_key.alerts.id
}

resource "aws_sns_topic" "alerts" {
  name              = local.alerts_topic_name
  kms_master_key_id = aws_kms_key.alerts.id
  tags              = local.tags
}

data "aws_iam_policy_document" "alerts_topic" {
  # Mirrors the SNS default policy, which Chatbot and CloudWatch alarms rely on, and adds EventBridge.
  statement {
    sid    = "DefaultOwnerAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:AddPermission",
      "sns:RemovePermission",
      "sns:DeleteTopic",
      "sns:Subscribe",
      "sns:ListSubscriptionsByTopic",
      "sns:Publish",
    ]
    resources = [aws_sns_topic.alerts.arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AllowEventBridgeToPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.alerts_topic.json
}

# ---------- Script-runner hard errors ----------
# entrypoint.sh logs {"event":"script_runner_hard_error",...} whenever a script
# exits non-zero, which fails the job. Find the script in the log group.

resource "aws_cloudwatch_log_metric_filter" "script_runner_hard_errors" {
  name           = "${local.application_name}-script-runner-hard-errors"
  log_group_name = aws_cloudwatch_log_group.script_runner.name
  pattern        = "{ $.event = \"script_runner_hard_error\" }"

  metric_transformation {
    name      = "ScriptRunnerHardErrors"
    namespace = "${local.metric_namespace}/ScriptRunner"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "script_runner_hard_errors" {
  alarm_name          = "${local.application_name}-${local.environment}-script-runner-hard-errors"
  alarm_description   = "A script-runner script exited with an error and failed its job. Search the ${aws_cloudwatch_log_group.script_runner.name} log group for script_runner_hard_error."
  namespace           = "${local.metric_namespace}/ScriptRunner"
  metric_name         = "ScriptRunnerHardErrors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  tags                = local.tags

  depends_on = [aws_cloudwatch_log_metric_filter.script_runner_hard_errors]
}

# Any failed, timed out or aborted execution, including failures that never reach a script.
resource "aws_cloudwatch_metric_alarm" "state_machine_failures" {
  for_each = local.state_machine_arns

  alarm_name          = "${local.application_name}-${local.environment}-${replace(each.key, "_", "-")}-state-machine-failures"
  alarm_description   = "The ${each.key} state machine had a failed, timed out or aborted execution."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  tags                = local.tags

  dynamic "metric_query" {
    for_each = {
      failed    = "ExecutionsFailed"
      timed_out = "ExecutionsTimedOut"
      aborted   = "ExecutionsAborted"
    }
    content {
      id = "m_${metric_query.key}"
      metric {
        namespace   = "AWS/States"
        metric_name = metric_query.value
        period      = 300
        stat        = "Sum"
        dimensions  = { StateMachineArn = each.value }
      }
    }
  }

  metric_query {
    id          = "total"
    expression  = "FILL(m_failed, 0) + FILL(m_timed_out, 0) + FILL(m_aborted, 0)"
    label       = "Failed executions"
    return_data = true
  }
}

# Script-runner tasks that cannot start never run entrypoint.sh, so they log nothing.
resource "aws_cloudwatch_event_rule" "script_runner_task_failed_to_start" {
  name        = "${local.application_name}-script-runner-task-failed-to-start"
  description = "A script-runner ECS task failed to start."
  tags        = local.tags

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail = {
      clusterArn = [aws_ecs_cluster.script_runner.arn]
      lastStatus = ["STOPPED"]
      stopCode   = ["TaskFailedToStart"]
    }
  })
}

resource "aws_cloudwatch_event_target" "script_runner_task_failed_to_start" {
  rule = aws_cloudwatch_event_rule.script_runner_task_failed_to_start.name
  arn  = aws_sns_topic.alerts.arn

  input_transformer {
    input_paths = {
      cluster = "$.detail.clusterArn"
      task    = "$.detail.taskArn"
      reason  = "$.detail.stoppedReason"
    }
    input_template = "{\"version\":\"1.0\",\"source\":\"custom\",\"content\":{\"textType\":\"client-markdown\",\"title\":\"[${local.environment}] Script-runner task failed to start\",\"description\":\"*Cluster:* <cluster>\\n*Task:* <task>\\n*Reason:* <reason>\"}}"
  }

  depends_on = [aws_sns_topic_policy.alerts]
}

# ---------- Bedrock errors ----------
# Custom metrics from the ECS logs of the control plane and the web UI. Client-side
# timeouts and oversized prompts never appear in the AWS/Bedrock metrics below.

resource "aws_cloudwatch_log_metric_filter" "bedrock_errors" {
  for_each = local.bedrock_log_alarms

  name           = "${local.application_name}-${each.key}-bedrock"
  log_group_name = each.value.log_group
  pattern        = each.value.pattern

  metric_transformation {
    name          = "${each.key}-bedrock"
    namespace     = "${local.metric_namespace}/Bedrock"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "bedrock_errors" {
  for_each = local.bedrock_log_alarms

  alarm_name          = "${local.application_name}-${local.environment}-${each.key}-bedrock"
  alarm_description   = "Bedrock ${each.value.error_type} errors in the ${each.value.component} logs (${each.value.log_group})."
  namespace           = "${local.metric_namespace}/Bedrock"
  metric_name         = "${each.key}-bedrock"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = each.value.threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  tags                = local.tags

  depends_on = [aws_cloudwatch_log_metric_filter.bedrock_errors]
}

# Bedrock's own metrics for the configured model or inference profile, covering all callers.
resource "aws_cloudwatch_metric_alarm" "bedrock_service" {
  for_each = {
    throttles     = { metric = "InvocationThrottles", threshold = 3 }
    client-errors = { metric = "InvocationClientErrors", threshold = 5 }
    server-errors = { metric = "InvocationServerErrors", threshold = 1 }
  }

  alarm_name          = "${local.application_name}-${local.environment}-bedrock-invocation-${each.key}"
  alarm_description   = "Bedrock reported ${each.value.metric} for ${local.bedrock_model_id}."
  namespace           = "AWS/Bedrock"
  metric_name         = each.value.metric
  dimensions          = { ModelId = local.bedrock_model_id }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = each.value.threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  tags                = local.tags
}
