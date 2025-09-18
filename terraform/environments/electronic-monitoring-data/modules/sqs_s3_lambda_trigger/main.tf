locals {
  s3_prefix_hyphen         = var.s3_prefix != null ? replace(var.s3_prefix, "/", "-") : ""
  s3_suffixes_hyphen       = var.s3_suffixes != null ? replace(join("-", var.s3_suffixes), ".", "-") : ""
  bucket_function_elements = split(trimprefix(var.bucket.id, var.bucket_prefix), "-")
  bucket_function          = join("-", slice(local.bucket_function_elements, 0, length(local.bucket_function_elements) - 1))
  queue_base_name          = substr("${local.bucket_function}-${local.s3_prefix_hyphen}-${local.s3_suffixes_hyphen}-${var.lambda_function_name}", 0, 76)
  sid_name                 = replace(local.queue_base_name, "-" ,"")
  s3_notification_filters  = length(var.s3_suffixes) > 0 && var.s3_prefix != null ? [
      for suffix in var.s3_suffixes : {
        prefix = var.s3_prefix
        suffix = suffix
      }
    ] : []
}

#trivy:ignore:AVD-AWS-0135 default is sufficient
resource "aws_sqs_queue" "s3_event_queue" {
  #checkov:skip=CKV2_AWS_73 default is sufficient
  name                       = local.queue_base_name
  visibility_timeout_seconds = 20 * 60 # Longer than longest possible lambda
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.s3_event_dlq.arn
    maxReceiveCount     = 5
  })
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}


resource "aws_s3_bucket_notification" "s3_notification_prefix_only" {
  count  = (length(var.s3_suffixes) == 0 && var.s3_prefix != null) ? 1 : 0
  bucket = var.bucket.id

  queue {
    queue_arn = aws_sqs_queue.s3_event_queue.arn
    events    = ["s3:ObjectCreated:*"]
    filter_prefix = var.s3_prefix
  }

  depends_on = [aws_sqs_queue_policy.allow_s3_to_write]
}

resource "aws_s3_bucket_notification" "s3_notification_prefix_suffixes" {
  for_each = {
    for filter in local.s3_notification_filters :
    "${filter.prefix}_${filter.suffix}" => filter
  }
  bucket   = var.bucket.id

  queue {
    queue_arn     = aws_sqs_queue.s3_event_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = each.value.prefix
    filter_suffix = each.value.suffix
  }

  depends_on = [aws_sqs_queue_policy.allow_s3_to_write]
}

resource "aws_s3_bucket_notification" "s3_notification_suffixes" {
  for_each = length(var.s3_suffixes) > 0 && var.s3_prefix == null ? toset(var.s3_suffixes) : toset([])
  bucket   = var.bucket.id

  queue {
    queue_arn     = aws_sqs_queue.s3_event_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = each.value
  }

  depends_on = [aws_sqs_queue_policy.allow_s3_to_write]
}

resource "aws_s3_bucket_notification" "s3_notification" {
  count = length(var.s3_suffixes) == 0 && var.s3_prefix == null ? 1 : 0
  bucket   = var.bucket.id

  queue {
    queue_arn     = aws_sqs_queue.s3_event_queue.arn
    events        = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sqs_queue_policy.allow_s3_to_write]
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

#trivy:ignore:AVD-AWS-0135 default is sufficient
resource "aws_sqs_queue" "s3_event_dlq" {
  #checkov:skip=CKV2_AWS_73 default is sufficient
  name = "${local.queue_base_name}-dlq"
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}
