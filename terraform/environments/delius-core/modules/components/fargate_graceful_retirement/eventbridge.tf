# eventbridge rule for ECS Task Retirements
resource "aws_cloudwatch_event_rule" "ecs_restart_rule" {
  name        = "RuleToRestartECSTasksWhenEventsReceived-in-${var.environment}"
  description = "Rule to catch AWS ECS Task Patching Retirement events for ${var.environment}"

  event_pattern = jsonencode({
    "detail-type" : ["AWS Health Event"],
    "detail" : {
      "eventTypeCode" : ["AWS_ECS_TASK_PATCHING_RETIREMENT"]
    }
  })
}

resource "aws_cloudwatch_event_target" "step_function_target" {
  rule     = aws_cloudwatch_event_rule.ecs_restart_rule.name
  arn      = aws_sfn_state_machine.ecs_restart_state_machine.arn
  role_arn = aws_iam_role.eventbridge_execution_role.arn
}


# CloudWatch log group to capture events
resource "aws_cloudwatch_log_group" "ecs_restart_events" {
  name = "/aws/health/ecs_restart_events/${var.environment}"
}

# IAM policy to allow EventBridge to write logs
data "aws_iam_policy_document" "ecs_restart_logging" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.ecs_restart_events.arn}:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "ecs_restart_logging_policy" {
  policy_document = data.aws_iam_policy_document.ecs_restart_logging.json
  policy_name     = "ecs-restart-events-log-policy-${var.environment}"
}


# event bridge target to push to log groups
resource "aws_cloudwatch_event_target" "ecs_restart_logging_target" {
  rule = aws_cloudwatch_event_rule.ecs_restart_rule.name
  arn  = aws_cloudwatch_log_group.ecs_restart_events.arn
}

resource "aws_iam_role" "eventbridge_execution_role" {
  name = "${var.environment}_eventbridge_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "eventbridge_execution_role_policy" {
  name = "${var.environment}_eventbridge_execution_role_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "logs:*",
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "states:StartExecution",
        Resource = aws_sfn_state_machine.ecs_restart_state_machine.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_execution_role_policy" {
  policy_arn = aws_iam_policy.eventbridge_execution_role_policy.arn
  role       = aws_iam_role.eventbridge_execution_role.name
}
