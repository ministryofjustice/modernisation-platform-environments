# Log group Policy to enable EventBridge to write events to log groups
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
      "Resource" : "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.id}:log-group:/metrics/${var.env_name}/*"
    }]
  })
}