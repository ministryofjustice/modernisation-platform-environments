data "aws_iam_policy_document" "dms_events_logs" {
  statement {
    sid    = "AllowEventBridgeDMSEvents"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
    }
    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/events/dms/*:*"]
  }
}

# One policy for all DMS pipelines: log resource policies are limited to 10 per account and region
resource "aws_cloudwatch_log_resource_policy" "dms_events_logs" {
  policy_name     = "dms-events-logs"
  policy_document = data.aws_iam_policy_document.dms_events_logs.json
}
