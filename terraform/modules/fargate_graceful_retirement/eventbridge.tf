resource "aws_cloudwatch_event_rule" "ecs_restart_rule" {
  name        = "ecs_task_retirement_rul"
  description = "Rule to catch AWS ECS Task Patching Retirement events"

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
  role_arn = aws_iam_role.step_function_role.arn
}


# test rule for all aws health events
resource "aws_cloudwatch_event_rule" "all_health_events" {
  name        = "all_health_events"
  description = "Rule to catch all AWS Health events"

  event_pattern = jsonencode({
    "source" : ["aws.health"]
  })
}

resource "aws_cloudwatch_log_group" "all_health_events" {
  name = "/aws/health/all_health_events"
}

# create IAM role for CloudWatch Logs
resource "aws_iam_role" "cloudwatch_logs_role" {
  name = "cloudwatch_logs_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_logs_policy" {
  name = "cloudwatch_logs_policy"
  role = aws_iam_role.cloudwatch_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# log all health events to cloudwatch logs
resource "aws_cloudwatch_event_target" "log_all_health_events" {
  rule     = aws_cloudwatch_event_rule.all_health_events.name
  arn      = aws_cloudwatch_log_group.all_health_events.arn
  role_arn = aws_iam_role.cloudwatch_logs_role.arn
}
