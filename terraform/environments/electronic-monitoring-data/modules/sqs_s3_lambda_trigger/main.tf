locals {
  bucket_function_elements = split(trimprefix(var.bucket.id, var.bucket_prefix), "-")
  bucket_function          = join("-", slice(local.bucket_function_elements, 0, length(local.bucket_function_elements) - 1))
  queue_base_name          = substr("${local.bucket_function}-${var.lambda_function_name}", 0, 76)
  sid_name                 = replace(local.queue_base_name, "-", "")
}

data "aws_caller_identity" "current" {}


resource "aws_sqs_queue" "s3_event_queue" {
  name                       = local.queue_base_name
  visibility_timeout_seconds = 6 * 15 * 60 # 6 x longer than longest possible lambda
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.s3_event_dlq.arn
    maxReceiveCount     = 5
  })
  sqs_managed_sse_enabled = true
}

data "aws_iam_policy_document" "allow_s3_to_write" {
  statement {
    sid    = "${local.sid_name}Permissions"
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
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [var.bucket.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
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
  batch_size       = 1
  scaling_config {
    maximum_concurrency = 10
  }

}

resource "aws_sqs_queue" "s3_event_dlq" {
  name                    = "${local.queue_base_name}-dlq"
  sqs_managed_sse_enabled = true
}
