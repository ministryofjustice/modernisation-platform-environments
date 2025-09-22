locals {
  bucket_function_elements = split(trimprefix(var.bucket.id, var.bucket_prefix), "-")
  bucket_function          = join("-", slice(local.bucket_function_elements, 0, length(local.bucket_function_elements) - 1))
  queue_base_name          = substr("${local.bucket_function}-${var.lambda_function_name}", 0, 76)
  sid_name                 = replace(local.queue_base_name, "-" ,"")
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "sqs_kms_key_policy" {
  statement {
    sid    = "AccountUseOfKey"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = [aws_kms_key.sqs_kms_key.arn]
  }
  statement {
    sid    = "S3UseofKey"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [var.bucket.arn]
    }
  }
  statement {
    sid    = "AllowLambdaToDecrypt"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_kms_key" "sqs_kms_key" {
  description             = "KMS key for encrypting S3 event SQS queue"
  enable_key_rotation     = true
}

resource "aws_kms_key_policy" "sqs_kms_key_policy" {
  key_id = aws_kms_key.sqs_kms_key.id
  policy = data.aws_iam_policy_document.sqs_kms_key_policy.json
}


resource "aws_sqs_queue" "s3_event_queue" {
  name                       = local.queue_base_name
  visibility_timeout_seconds = 20 * 60 # Longer than longest possible lambda
  redrive_policy             = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.s3_event_dlq.arn
    maxReceiveCount     = 5
  })
  kms_master_key_id                 = aws_kms_key.sqs_kms_key.id
  kms_data_key_reuse_period_seconds = 300

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
  name                              = "${local.queue_base_name}-dlq"
  kms_master_key_id                 = aws_kms_key.sqs_kms_key.id
  kms_data_key_reuse_period_seconds = 300
}
