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

data "aws_iam_policy_document" "all_health_events" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream"
    ]

    resources = [
      "${aws_cloudwatch_log_group.all_health_events.arn}:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.all_health_events.arn}:*:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }

    condition {
      test     = "ArnEquals"
      values   = [aws_cloudwatch_event_rule.all_health_events.arn]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "all_health_events" {
  policy_document = data.aws_iam_policy_document.all_health_events.json
  policy_name     = "all-health-events-log-publishing-policy"
}

resource "aws_cloudwatch_event_target" "all_health_events" {
  rule = aws_cloudwatch_event_rule.all_health_events.name
  arn  = aws_cloudwatch_log_group.all_health_events.arn
}