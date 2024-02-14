#------------------------------------------------------------------------------
# S3 bucket for data store logs
#------------------------------------------------------------------------------

module "data_store_log_bucket" {
  source = "./modules/s3_log_bucket"

  source_bucket = aws_s3_bucket.data_store
  account_id    = data.aws_caller_identity.current.account_id
}

#------------------------------------------------------------------------------
# S3 bucket for landed data (internal facing)
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "data_store" {
  bucket_prefix = "em-data-store-"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_store" {
  bucket = aws_s3_bucket.data_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data_store" {
  bucket                  = aws_s3_bucket.data_store.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "data_store" {
  bucket = aws_s3_bucket.data_store.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "data_store" {
  bucket = aws_s3_bucket.data_store.id
  policy = data.aws_iam_policy_document.data_store.json
}

data "aws_iam_policy_document" "data_store" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.data_store.arn,
      "${aws_s3_bucket.data_store.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

resource "aws_s3_bucket_logging" "data_store" {
  bucket = aws_s3_bucket.data_store.id

  target_bucket = module.data_store_log_bucket.bucket_id
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

resource "aws_s3_bucket_notification" "data_store" {
  bucket = aws_s3_bucket.data_store.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.checksum_lambda.arn
    events              = [
      "s3:ObjectCreated:Put",
      "s3:ObjectCreated:Post"
    ]
  }

  # lambda_function {
  #   lambda_function_arn = aws_lambda_function.analyse_zip_lambda.arn
  #   events              = [
    # "s3:ObjectCreated:Put",
    # "s3:ObjectCreated:Post"
  # ]
  #   filter_suffix       = ".zip"
  # }

  depends_on = [
    aws_lambda_permission.s3_allow_checksum_lambda,
    # aws_lambda_permission.s3_allow_analyse_zip_lambda,
  ]
}

#------------------------------------------------------------------------------
# S3 lambda function to calculate data store file checksums
#------------------------------------------------------------------------------

variable "checksum_algorithm" {
  description = "Select Checksum Algorithm. Default and recommended choice is SHA256, however CRC32, CRC32C, SHA1 are also available."
  default     = "SHA256"
}

data "archive_file" "this" {
  type        = "zip"
  source_file = "checksum_lambda.py"
  output_path = "checksum_lambda.zip"
}

resource "aws_lambda_function" "checksum_lambda" {
  filename      = "checksum_lambda.zip"
  function_name = "ChecksumLambda"
  role          = aws_iam_role.checksum_lambda.arn
  handler       = "checksum_lambda.handler"
  runtime       = "python3.9"
  timeout       = 600

  environment {
    variables = {
      Checksum = var.checksum_algorithm
    }
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "checksum_lambda" {
  name                = "checksum-lambda-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

data "aws_iam_policy_document" "checksum_lambda" {
  statement {
    sid = "S3Permissions"
    effect  = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:GetObjectAcl",
      "s3:GetObjectAttributes",
      "s3:GetObjectVersionAttributes",
      "s3:ListBucket"
    ]
    resources = ["${aws_s3_bucket.data_store.arn}/*"]
  }
}

resource "aws_iam_role_policy" "checksum_lambda" {
  name   = "checksum-lambda-iam-policy"
  role   = aws_iam_role.checksum_lambda.id
  policy = data.aws_iam_policy_document.checksum_lambda.json
}

resource "aws_lambda_permission" "s3_allow_checksum_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.checksum_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.data_store.arn}"
}

#------------------------------------------------------------------------------