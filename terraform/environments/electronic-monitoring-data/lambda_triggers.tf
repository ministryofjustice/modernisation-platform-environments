module "calculate_checksum_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  lambda_function_name = module.calculate_checksum.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

resource "aws_s3_bucket_notification" "historic_data_checksum" {
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
    queue_arn     = module.format_json_fms_data_sqs.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".JSON"
    filter_prefix = "serco/fms"
  }
  queue {
    queue_arn     = module.process_fms_metadata_sqs.sqs_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".JSON"
    filter_prefix = "serco/fms"
  }
}

module "format_json_fms_data_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  lambda_function_name = module.format_json_fms_data.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

module "copy_mdss_data_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  lambda_function_name = module.copy_mdss_data.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

module "process_fms_metadata_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-data-bucket.bucket
  lambda_function_name = module.process_fms_metadata.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

resource "aws_s3_bucket_notification" "virus_scan" {
  bucket = module.s3-received-files-bucket.bucket.id

  queue {
    queue_arn = module.virus_scan_file.lambda_function_name
    events    = ["s3:ObjectCreated:*"]
  }
}
