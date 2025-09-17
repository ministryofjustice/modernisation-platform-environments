data "aws_iam_policy_document" "datasync_cloudwatch_logs" {
  statement {
    sid    = "AllowDataSync"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream"
    ]
    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
    resources = [
      "${module.datasync_task_logs.cloudwatch_log_group_arn}*",
      "${module.datasync_enhanced_logs.cloudwatch_log_group_arn}*"
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:datasync:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:task/*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "datasync_cloudwatch_logs" {
  policy_name     = "datasync-cloudwatch-logs"
  policy_document = data.aws_iam_policy_document.datasync_cloudwatch_logs.json
}
