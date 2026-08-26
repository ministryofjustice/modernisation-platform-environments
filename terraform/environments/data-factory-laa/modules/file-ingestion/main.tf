module "file_uploads_bucket" {
  source   = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=4f72896323ec7f06e293f1f75732549b3248f841"

  bucket_prefix       = "file-uploads"
  bucket_namespace    = "account-regional"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  sse_algorithm       = "aws:kms"
  custom_kms_key      = var.kms_key_arn

  providers = {
    aws.bucket-replication = aws.bucket-replication
  }

  tags = var.tags
}

module "processed_file_uploads_bucket" {
  source   = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=4f72896323ec7f06e293f1f75732549b3248f841"

  bucket_prefix       = "processed-file-uploads"
  bucket_namespace    = "account-regional"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  sse_algorithm       = "aws:kms"
  custom_kms_key      = var.kms_key_arn

  providers = {
    aws.bucket-replication = aws.bucket-replication
  }
  
  tags = var.tags
}

module "process_uploads_lambda" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=23d00f7daef40091e87ed2f9dc5d8532e9d2cc22" # v8.8.1


  function_name = "process-file-upload"
  description   = "Lambda function to process file uploads"
  handler       = "process_uploads.lambda_handler"
  runtime       = "python3.14"
  architectures = ["arm64"]

  source_path = "${path.module}/process_uploads.py"

  environment_variables = {
    FILE_UPLOADS_BUCKET = module.file_uploads_bucket.bucket.id
    PROCESSED_FILE_UPLOADS_BUCKET = module.processed_file_uploads_bucket.bucket.id
    DATABASE_NAME = var.database_name
  }

  layers = [
    # TODO: Get using data source
    "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python314-Arm64:11"
  ]
}
