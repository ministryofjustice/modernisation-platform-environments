# IAM Role for EventBridge to assume and write logs to the Log Groups
resource "aws_iam_role" "eventbridge_to_logs_role" {
  name = "${var.env_name}-eventbridge-to-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement : [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "eventbridge_logs_policy" {
  name        = "${var.env_name}-eventbridge-to-logs-policy"
  description = "Policy to allow EventBridge to write logs to CloudWatch Log Groups"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement : [{
      Action   = "logs:PutLogEvents",
      Effect   = "Allow",
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_logs_policy_attachment" {
  policy_arn = aws_iam_policy.eventbridge_logs_policy.arn
  role       = aws_iam_role.eventbridge_to_logs_role.name
}

resource "aws_cloudwatch_log_resource_policy" "log_group_policy" {
  policy_name = "${var.env_name}-eventbridge-to-logs-policy"
  policy_document = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" = ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
      },
      "Action" : [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource" : "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:log-group:/metrics/${var.env_name}/*"
    }]
  })
}