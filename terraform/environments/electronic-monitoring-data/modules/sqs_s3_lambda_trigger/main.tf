locals {
  s3_prefix_hyphen = replace(var.s3_prefix, "/", "-")
  s3_suffixes_hyphen = replace(join("-", var.s3_suffixes), ".", "-")
  queue_base_name = substr("${var.bucket.bucket_prefix}-${local.s3_prefix_hyphen}-${local.s3_suffixes_hyphen}-${var.lambda_function_name}", 0, 76)
}

resource "aws_sqs_queue" "s3_event_queue" {
  name                       = local.queue_base_name
  visibility_timeout_seconds = 300 
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.s3_event_dlq.arn
    maxReceiveCount     = 5
  })
}


resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = var.bucket.id

  queue {
    queue_arn     = aws_sqs_queue.s3_event_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.s3_prefix
  }

  depends_on = [aws_sqs_queue_policy.allow_s3_to_write]
}

data "aws_iam_policy_document" "allow_s3_to_write" {
  statement {
    sid    = "S3${var.bucket.id}/${var.s3_prefix}ToSQS"
    effect = "Allow"
    principals {
        type        = "Service"
        identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "SQS:SendMessage"
    ]
    resources = [
      aws_sqs_queue.s3_event_queue.arn
    ]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [var.bucket.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "allow_s3_to_write" {
  queue_url = aws_sqs_queue.s3_event_queue.id
  policy    = data.aws_iam_policy_document.allow_s3_to_write.json
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.s3_event_queue.arn
  function_name    = var.lambda_function_name
  batch_size       = 10
  enabled          = true
}

resource "aws_sqs_queue" "s3_event_dlq" {
  name = "${local.queue_base_name}-dlq"
}
