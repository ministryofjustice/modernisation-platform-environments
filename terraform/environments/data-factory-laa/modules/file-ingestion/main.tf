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

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Policy document for the lambda function to process file uploads
# Lambda will create tables using awswrangler and write to the processed file uploads bucket
data "aws_iam_policy_document" "process_uploads_lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      module.file_uploads_bucket.bucket.arn,
      "${module.file_uploads_bucket.bucket.arn}/*",
      module.processed_file_uploads_bucket.bucket.arn,
      "${module.processed_file_uploads_bucket.bucket.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [var.kms_key_arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:Get*"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${var.database_name}",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.database_name}/*"
    ]
  }
}

module "process_uploads_lambda" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=23d00f7daef40091e87ed2f9dc5d8532e9d2cc22" # v8.8.1


  function_name = "process-file-upload"
  description   = "Lambda function to process file uploads"
  handler       = "process_uploads.lambda_handler"
  runtime       = "python3.14"
  architectures = ["arm64"]
  timeout       = 30
  memory_size   = 4096
  policy_json   = data.aws_iam_policy_document.process_uploads_lambda_policy.json
  attach_policy_json = true

  source_path = "${path.module}/process_uploads.py"

  environment_variables = {
    FILE_UPLOADS_BUCKET = module.file_uploads_bucket.bucket.id
    PROCESSED_FILE_UPLOADS_BUCKET = module.processed_file_uploads_bucket.bucket.id
    DATABASE_NAME = var.database_name
    KMS_KEY_ARN = var.kms_key_arn
  }

  layers = [
    # TODO: Get using data source
    "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python314-Arm64:11"
  ]
}
