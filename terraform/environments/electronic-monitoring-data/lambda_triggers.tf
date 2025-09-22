# ---------------------------------------
# Data bucket notification triggers
# ---------------------------------------
resource "aws_s3_bucket_notification" "historic_data_store" {
  bucket     = module.s3-data-bucket.bucket.id

  lambda_function {
    lambda_function_arn = module.calculate_checksum.lambda_function_arn
    events = [
      "s3:ObjectCreated:*"
    ]
    filter_suffix = ".bak"
  }
  lambda_function {
    lambda_function_arn = module.calculate_checksum.lambda_function_arn
    events = [
      "s3:ObjectCreated:*",
    ]
    filter_suffix = ".zip"
  }
  lambda_function {
    lambda_function_arn = module.calculate_checksum.lambda_function_arn
    events = [
      "s3:ObjectCreated:*",
    ]
    filter_suffix = ".bacpac"
  }
  lambda_function {
    lambda_function_arn = module.calculate_checksum.lambda_function_arn
    events = [
      "s3:ObjectCreated:*",
    ]
    filter_suffix = ".7z"
  }
  lambda_function {
    lambda_function_arn = module.format_json_fms_data.lambda_function_arn
    events = [
      "s3:ObjectCreated:*",
    ]
    filter_suffix = ".JSON"
    filter_prefix = "serco/fms/"
  }
  lambda_function {
    lambda_function_arn = module.copy_mdss_data.lambda_function_arn
    events = [
      "s3:ObjectCreated:*",
    ]
    filter_suffix = ".jsonl"
    filter_prefix = "allied/mdss/"
  }
}

# ---------------------------------------
# virus scan trigger
# ---------------------------------------

module "virus_scan_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-received-files-bucket.bucket
  lambda_function_name = module.virus_scan_file.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

resource "aws_s3_bucket_notification" "scan_received_files" {
  bucket = module.s3-received-files-bucket.bucket.id

  lambda_function {
    lambda_function_arn = module.virus_scan_file.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

}

# ---------------------------------------
# Metadata process trigger
# ---------------------------------------

module "process_fms_metadata_sqs" {
  source               = "./modules/sqs_s3_lambda_trigger"
  bucket               = module.s3-raw-formatted-data-bucket.bucket
  lambda_function_name = module.process_fms_metadata.lambda_function_name
  bucket_prefix        = local.bucket_prefix
}

resource "aws_s3_bucket_notification" "process_fms_metadata" {
  bucket = module.s3-received-files-bucket.bucket.id

  lambda_function {
    lambda_function_arn = module.process_fms_metadata.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

}
