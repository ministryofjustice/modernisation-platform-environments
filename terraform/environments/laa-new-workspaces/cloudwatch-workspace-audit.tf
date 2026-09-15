# Finds WorkSpaces create and terminate events from CloudTrail.
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


# Stores the matching events in CloudWatch Logs for review and future alerting.
resource "aws_cloudwatch_log_group" "workspace_changes" {

  name              = "/aws/events/${local.application_name}/${local.environment}/workspace-changes"
  retention_in_days = 90

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-workspace-change-events" }
  )
}

# Allows EventBridge to write events to the log group.
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

# Applies the EventBridge-to-CloudWatch Logs permissions.
resource "aws_cloudwatch_log_resource_policy" "workspace_changes_log_policy" {

  policy_document = data.aws_iam_policy_document.workspace_changes_log_policy.json
  policy_name     = "${local.application_name}-${local.environment}-workspace-changes"
}

# Sends matching WorkSpaces events to the log group.
resource "aws_cloudwatch_event_target" "workspace_changes_log_group" {

  rule           = aws_cloudwatch_event_rule.workspace_changes.name
  target_id      = "WorkspaceChangesCloudWatchLogs"
  arn            = aws_cloudwatch_log_group.workspace_changes.arn
  event_bus_name = "default"

  depends_on = [aws_cloudwatch_log_resource_policy.workspace_changes_log_policy]
}

# Counts WorkSpaces creation events.
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

# Counts WorkSpaces termination events.
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