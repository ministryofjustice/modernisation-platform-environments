##############################################
### WorkSpaces API Audit Monitoring
###
### Captures WorkSpaces create and terminate API calls
### recorded by CloudTrail and exposes them as CloudWatch
### metrics and alarms. Notification actions can be added
### later when the Slack alerting Lambda is available.
##############################################

# CloudTrail API events are delivered to EventBridge automatically.
resource "aws_cloudwatch_event_rule" "workspace_changes" {

  name        = "${local.application_name}-${local.environment}-workspace-changes"
  description = "Capture WorkSpaces creation and termination API calls"

  event_pattern = jsonencode({
    source      = ["aws.workspaces"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["workspaces.amazonaws.com"]
      eventName   = ["CreateWorkspaces", "TerminateWorkspaces"]
    }
  })

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-workspace-changes" }
  )
}

# Dedicated log group for the raw API events. This is the source for the
# metric filters and can also be consumed by the future Slack alerting Lambda.
#checkov:skip=CKV_AWS_158: CloudWatch audit log encryption is not required for this event log
#checkov:skip=CKV_AWS_338: Audit log retention is intentionally limited to 90 days
resource "aws_cloudwatch_log_group" "workspace_changes" {

  name              = "/aws/events/${local.application_name}/${local.environment}/workspace-changes"
  retention_in_days = 90

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-workspace-change-events" }
  )
}

data "aws_iam_policy_document" "workspace_changes_log_policy" {

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = ["${aws_cloudwatch_log_group.workspace_changes.arn}:*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.workspace_changes.arn]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "workspace_changes_log_policy" {

  policy_document = data.aws_iam_policy_document.workspace_changes_log_policy.json
  policy_name     = "${local.application_name}-${local.environment}-workspace-changes"
}

resource "aws_cloudwatch_event_target" "workspace_changes_log_group" {

  rule           = aws_cloudwatch_event_rule.workspace_changes.name
  target_id      = "WorkspaceChangesCloudWatchLogs"
  arn            = aws_cloudwatch_log_group.workspace_changes.arn
  event_bus_name = "default"

  depends_on = [aws_cloudwatch_log_resource_policy.workspace_changes_log_policy]
}

resource "aws_cloudwatch_log_metric_filter" "workspace_created" {

  name           = "${local.application_name}-${local.environment}-workspace-created"
  log_group_name = aws_cloudwatch_log_group.workspace_changes.name
  pattern        = "{ $.detail.eventName = \"CreateWorkspaces\" }"

  metric_transformation {
    name      = "WorkspaceCreated"
    namespace = "${local.application_name}/${local.environment}"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "workspace_terminated" {

  name           = "${local.application_name}-${local.environment}-workspace-terminated"
  log_group_name = aws_cloudwatch_log_group.workspace_changes.name
  pattern        = "{ $.detail.eventName = \"TerminateWorkspaces\" }"

  metric_transformation {
    name      = "WorkspaceTerminated"
    namespace = "${local.application_name}/${local.environment}"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "workspace_created" {

  alarm_name          = "${local.application_name}-${local.environment}-workspace-created"
  alarm_description   = "A WorkSpaces creation API call was detected"
  namespace           = "${local.application_name}/${local.environment}"
  metric_name         = aws_cloudwatch_log_metric_filter.workspace_created.metric_transformation[0].name
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "workspace_terminated" {

  alarm_name          = "${local.application_name}-${local.environment}-workspace-terminated"
  alarm_description   = "A WorkSpaces termination API call was detected"
  namespace           = "${local.application_name}/${local.environment}"
  metric_name         = aws_cloudwatch_log_metric_filter.workspace_terminated.metric_transformation[0].name
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}