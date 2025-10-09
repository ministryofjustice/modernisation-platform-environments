module "calculate_checksum_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  lambda_function_name = module.calculate_checksum.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

resource "aws_s3_bucket_notification" "data_bucket_triggers" {
  bucket = module.s3-data-bucket.bucket.id
  queue {
    queue_arn     = module.calculate_checksum_sqs.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".zip"
  }
  queue {
    queue_arn     = module.calculate_checksum_sqs.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".bak"
  }
  queue {
    queue_arn     = module.calculate_checksum_sqs.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".bacpac"
  }
  queue {
    queue_arn     = module.calculate_checksum_sqs.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".csv"
  }
  queue {
    queue_arn     = module.calculate_checksum_sqs.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".7z"
  }
  queue {
    queue_arn     = module.copy_mdss_data_sqs.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".jsonl"
    filter_prefix = "allied/mdss"
  }
  queue {
    queue_arn     = module.process_fms_metadata_sqs.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".JSON"
    filter_prefix = "serco/fms"
  }
}

module "process_fms_metadata_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  lambda_function_name = module.process_fms_metadata.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

module "copy_mdss_data_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  lambda_function_name = module.copy_mdss_data.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

module "virus_scan_file_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-received-files-bucket.bucket
  lambda_function_name = module.virus_scan_file.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

resource "aws_s3_bucket_notification" "virus_scan_file" {
  bucket = module.s3-received-files-bucket.bucket.id

  queue {
    queue_arn = module.virus_scan_file_sqs.sqs_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [module.virus_scan_file_sqs]
}


# ----------------------------------------------
# Format Json data sqs queue
# ----------------------------------------------

resource "aws_sqs_queue" "format_fms_json_event_queue" {
  name                       = "format-fms-json-queue"
  visibility_timeout_seconds = 6 * 15 * 60 # 6 x longer than longest possible lambda
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.format_fms_json_event_dlq.arn
    maxReceiveCount     = 5
  })4
  sqs_managed_sse_enabled = true
}

resource "aws_sqs_queue" "format_fms_json_event_dlq" {
  name                    = "format-fms-json-dlq"
  sqs_managed_sse_enabled = true
}

data "aws_iam_policy_document" "allow_lambda_to_write" {
  statement {
    sid    = "FormatFMSJsonPermissions"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = [
      "SQS:SendMessage"
    ]
    resources = [
      aws_sqs_queue.format_fms_json_event_queue.arn
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [module.process_fms_metadata.lambda_function_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "allow_lambda_to_write" {
  queue_url = aws_sqs_queue.format_fms_json_event_queue.id
  policy    = data.aws_iam_policy_document.allow_lambda_to_write.json
}


resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.format_fms_json_event_queue.arn
  function_name    = module.format_json_fms_data.lambda_function_name
  batch_size       = 10
  scaling_config {
    maximum_concurrency = 1000
  }
}