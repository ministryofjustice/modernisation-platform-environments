resource "aws_sqs_queue" "cortex_xsiam" {
  count = local.is-production ? 1 : 0

  name                      = "${local.component_name}-cortex-xsiam"
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 20
}

data "aws_iam_policy_document" "cortex_xsiam_sqs" {
  count = local.is-production ? 1 : 0

  statement {
    sid       = "AllowS3ObjectNotifications"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.cortex_xsiam[0].arn]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.s3_bucket[0].s3_bucket_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "cortex_xsiam" {
  count = local.is-production ? 1 : 0

  queue_url = aws_sqs_queue.cortex_xsiam[0].id
  policy    = data.aws_iam_policy_document.cortex_xsiam_sqs[0].json
}

resource "aws_s3_bucket_notification" "cortex_xsiam" {
  count  = local.is-production ? 1 : 0
  bucket = module.s3_bucket[0].s3_bucket_id

  queue {
    queue_arn = aws_sqs_queue.cortex_xsiam[0].arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sqs_queue_policy.cortex_xsiam]
}