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


# Slack notifications: this log group is the trigger source for the Lambda.
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

# Slack notifications: Lambda reads the webhook secret and posts the event message.
data "archive_file" "workspace_event_slack" {

  type        = "zip"
  output_path = "${path.module}/xxx-new-scripts/workspace-event-slack-lambda.zip"

  source {
    content  = file("${path.module}/xxx-new-scripts/workspace-event-slack-lambda.py")
    filename = "lambda_function.py"
  }
}

resource "aws_iam_role" "workspace_event_slack" {
  name = "${local.application_name}-${local.environment}-workspace-event-slack-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-workspace-event-slack-role" }
  )
}

resource "aws_iam_role_policy_attachment" "workspace_event_slack_basic" {
  role       = aws_iam_role.workspace_event_slack.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "workspace_event_slack_secrets" {
  name = "${local.application_name}-${local.environment}-workspace-event-slack-secrets"
  role = aws_iam_role.workspace_event_slack.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.workspace_event_slack_webhook.arn
        ]
      }
    ]
  })
}

resource "aws_lambda_function" "workspace_event_slack" {
  function_name    = "${local.application_name}-${local.environment}-workspace-event-slack"
  description      = "Posts WorkSpaces create and terminate events to Slack"
  filename         = data.archive_file.workspace_event_slack.output_path
  source_code_hash = data.archive_file.workspace_event_slack.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  role             = aws_iam_role.workspace_event_slack.arn

  environment {
    variables = {
      SLACK_WEBHOOK_SECRET = aws_secretsmanager_secret.workspace_event_slack_webhook.name
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-workspace-event-slack" }
  )
}

resource "aws_lambda_permission" "allow_workspace_event_log_invoke" {
  statement_id  = "AllowExecutionFromCloudWatchLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.workspace_event_slack.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.workspace_changes.arn}:*"
}

#  Slack notifications: trigger the Lambda when a WorkSpace is created.
resource "aws_cloudwatch_log_subscription_filter" "workspace_created_slack" {
  name            = "${local.application_name}-${local.environment}-workspace-created-slack"
  log_group_name  = aws_cloudwatch_log_group.workspace_changes.name
  filter_pattern  = "{ $.detail.eventName = \"CreateWorkspaces\" }"
  destination_arn = aws_lambda_function.workspace_event_slack.arn
}

# Slack notifications: trigger the Lambda when a WorkSpace is deleted.
resource "aws_cloudwatch_log_subscription_filter" "workspace_terminated_slack" {
  name            = "${local.application_name}-${local.environment}-workspace-terminated-slack"
  log_group_name  = aws_cloudwatch_log_group.workspace_changes.name
  filter_pattern  = "{ $.detail.eventName = \"TerminateWorkspaces\" }"
  destination_arn = aws_lambda_function.workspace_event_slack.arn
}

