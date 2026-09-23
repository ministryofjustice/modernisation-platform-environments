######################################
### EventBridge Rules
######################################

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


######################################
### WorkSpaces CloudWatch Logs
######################################

# Stores WorkSpaces events and provides the source for the Slack subscription.
resource "aws_cloudwatch_log_group" "workspace_changes" {

  name              = "/aws/events/${local.application_name}/${local.environment}/workspace-changes"
  retention_in_days = 90

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-workspace-change-events" }
  )
}

# Allows EventBridge to write WorkSpaces events to the log group.
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

# Captures security-group API calls from CloudTrail.
resource "aws_cloudwatch_event_rule" "security_group_changes" {
  name        = "${local.application_name}-${local.environment}-security-group-changes"
  description = "Capture security-group API calls"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName = [
        "CreateSecurityGroup",
        "DeleteSecurityGroup",
        "AuthorizeSecurityGroupIngress",
        "AuthorizeSecurityGroupEgress",
        "RevokeSecurityGroupIngress",
        "RevokeSecurityGroupEgress",
        "ModifySecurityGroupRules"
      ]
    }
  })

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-security-group-changes" }
  )
}

######################################
### Security Group CloudWatch Logs
######################################

resource "aws_cloudwatch_log_group" "security_group_changes" {
  name              = "/aws/events/${local.application_name}/${local.environment}/security-group-changes"
  retention_in_days = 90

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-security-group-change-events" }
  )
}

# Allows EventBridge to write security-group events to the log group.
data "aws_iam_policy_document" "security_group_changes_log_policy" {
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

    resources = ["${aws_cloudwatch_log_group.security_group_changes.arn}:*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.security_group_changes.arn]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "security_group_changes_log_policy" {
  policy_document = data.aws_iam_policy_document.security_group_changes_log_policy.json
  policy_name     = "${local.application_name}-${local.environment}-security-group-changes"
}

resource "aws_cloudwatch_event_target" "security_group_changes_log_group" {
  rule           = aws_cloudwatch_event_rule.security_group_changes.name
  target_id      = "SecurityGroupChangesCloudWatchLogs"
  arn            = aws_cloudwatch_log_group.security_group_changes.arn
  event_bus_name = "default"

  depends_on = [aws_cloudwatch_log_resource_policy.security_group_changes_log_policy]
}

# IAM is a global service; its events only reach the default event bus in us-east-1.
resource "aws_cloudwatch_event_rule" "iam_policy_changes" {
  provider    = aws.us-east-1
  name        = "${local.application_name}-${local.environment}-iam-policy-changes"
  description = "Capture IAM policy API calls"

  event_pattern = jsonencode({
    source      = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["iam.amazonaws.com"]
      eventName = [
        "CreatePolicy",
        "DeletePolicy",
        "CreatePolicyVersion",
        "DeletePolicyVersion",
        "SetDefaultPolicyVersion",
        "AttachRolePolicy",
        "DetachRolePolicy",
        "PutRolePolicy",
        "DeleteRolePolicy",
        "AttachUserPolicy",
        "DetachUserPolicy",
        "PutUserPolicy",
        "DeleteUserPolicy",
        "AttachGroupPolicy",
        "DetachGroupPolicy",
        "PutGroupPolicy",
        "DeleteGroupPolicy"
      ]
    }
  })

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-iam-policy-changes" }
  )
}

######################################
### IAM Policy CloudWatch Logs
######################################

resource "aws_cloudwatch_log_group" "iam_policy_changes" {
  provider          = aws.us-east-1
  name              = "/aws/events/${local.application_name}/${local.environment}/iam-policy-changes"
  retention_in_days = 90

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-iam-policy-change-events" }
  )
}

# Allows EventBridge to write IAM policy events to the log group.
data "aws_iam_policy_document" "iam_policy_changes_log_policy" {
  provider = aws.us-east-1
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

    resources = ["${aws_cloudwatch_log_group.iam_policy_changes.arn}:*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.iam_policy_changes.arn]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "iam_policy_changes_log_policy" {
  provider        = aws.us-east-1
  policy_document = data.aws_iam_policy_document.iam_policy_changes_log_policy.json
  policy_name     = "${local.application_name}-${local.environment}-iam-policy-changes"
}

resource "aws_cloudwatch_event_target" "iam_policy_changes_log_group" {
  provider       = aws.us-east-1
  rule           = aws_cloudwatch_event_rule.iam_policy_changes.name
  target_id      = "IamPolicyChangesCloudWatchLogs"
  arn            = aws_cloudwatch_log_group.iam_policy_changes.arn
  event_bus_name = "default"

  depends_on = [aws_cloudwatch_log_resource_policy.iam_policy_changes_log_policy]
}

######################################
### Lambda Function
######################################

# Reads the Slack webhook secret and posts CloudTrail event messages.
data "archive_file" "workspace_event_slack" {

  type        = "zip"
  output_path = "${path.module}/xxx-new-scripts/workspace-event-slack-lambda.zip"

  source {
    content  = file("${path.module}/xxx-new-scripts/workspace-event-slack-lambda.py")
    filename = "lambda_function.py"
  }
}

######################################
### IAM Resources
######################################

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

# IAM policy events land on the us-east-1 default event bus, so the Lambda
# runs there. The role is created via the default provider because the
# us-east-1 provider role cannot call iam:CreateRole; IAM roles are global
# so this role still works for a Lambda function running in us-east-1.
resource "aws_iam_role" "iam_policy_event_slack" {
  name = "${local.application_name}-${local.environment}-iam-policy-event-slack-role"

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
    { Name = "${local.application_name}-${local.environment}-iam-policy-event-slack-role" }
  )
}

resource "aws_iam_role_policy_attachment" "iam_policy_event_slack_basic" {
  role       = aws_iam_role.iam_policy_event_slack.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Matches the secret in every region, since the us-east-1 replica has its own ARN suffix.
resource "aws_iam_role_policy" "iam_policy_event_slack_secrets" {
  name = "${local.application_name}-${local.environment}-iam-policy-event-slack-secrets"
  role = aws_iam_role.iam_policy_event_slack.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:${local.application_name}/${local.environment}/workspace-event-slack-webhook-*"
        ]
      }
    ]
  })
}

resource "aws_lambda_function" "iam_policy_event_slack" {
  provider         = aws.us-east-1
  function_name    = "${local.application_name}-${local.environment}-iam-policy-event-slack"
  description      = "Posts IAM policy change events to Slack"
  filename         = data.archive_file.workspace_event_slack.output_path
  source_code_hash = data.archive_file.workspace_event_slack.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  role             = aws_iam_role.iam_policy_event_slack.arn

  environment {
    variables = {
      SLACK_WEBHOOK_SECRET = aws_secretsmanager_secret.workspace_event_slack_webhook.name
    }
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-iam-policy-event-slack" }
  )
}

######################################
### Lambda Permissions
######################################

# Allows each CloudWatch log group to invoke the shared Slack Lambda.
resource "aws_lambda_permission" "allow_workspace_event_log_invoke" {
  statement_id  = "AllowExecutionFromCloudWatchLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.workspace_event_slack.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.workspace_changes.arn}:*"
}

resource "aws_lambda_permission" "allow_security_group_event_log_invoke" {
  statement_id  = "AllowExecutionFromSecurityGroupCloudWatchLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.workspace_event_slack.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.security_group_changes.arn}:*"
}

# Its Lambda, role, and log subscription live in us-east-1 alongside the rule and log group.
resource "aws_lambda_permission" "allow_iam_policy_event_log_invoke" {
  provider      = aws.us-east-1
  statement_id  = "AllowExecutionFromIamPolicyCloudWatchLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.iam_policy_event_slack.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.iam_policy_changes.arn}:*"
}

######################################
### CloudWatch Log Subscriptions
######################################

# Each dedicated log group forwards its events to the same Lambda and Slack channel.
resource "aws_cloudwatch_log_subscription_filter" "workspace_changes_slack" {
  name            = "${local.application_name}-${local.environment}-workspace-slack"
  log_group_name  = aws_cloudwatch_log_group.workspace_changes.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.workspace_event_slack.arn
}

resource "aws_cloudwatch_log_subscription_filter" "security_group_changes_slack" {
  name            = "${local.application_name}-${local.environment}-security-group-slack"
  log_group_name  = aws_cloudwatch_log_group.security_group_changes.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.workspace_event_slack.arn
}

resource "aws_cloudwatch_log_subscription_filter" "iam_policy_changes_slack" {
  provider        = aws.us-east-1
  name            = "${local.application_name}-${local.environment}-iam-policy-slack"
  log_group_name  = aws_cloudwatch_log_group.iam_policy_changes.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.iam_policy_event_slack.arn
}

