#------------------------------------------------------------------------------
# S3 bucket for data store logs
#------------------------------------------------------------------------------

module "data_store_log_bucket" {
  source = "./modules/s3_log_bucket"

  source_bucket = aws_s3_bucket.data_store
  account_id    = data.aws_caller_identity.current.account_id
  local_tags    = local.tags
}

#------------------------------------------------------------------------------
# S3 bucket for landed data (internal facing)
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "data_store" {
  bucket_prefix = "em-data-store-"

  tags = local.tags
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

  # Only for copy events as those are events triggered by data being copied
  # from landing bucket.
  lambda_function {
    lambda_function_arn = aws_lambda_function.calculate_checksum_lambda.arn
    events = [
      "s3:ObjectCreated:*"
    ]
  }

  # Only for copy events as those are events triggered by data being copied
  # from landing bucket.
  # lambda_function {
  #   lambda_function_arn = aws_lambda_function.summarise_zip_lambda.arn
  #   events              = [
  #     "s3:ObjectCreated:*"
  #   ]
  # }

  depends_on = [
    aws_lambda_permission.s3_allow_calculate_checksum_lambda,
    # aws_lambda_permission.s3_allow_summarise_zip_lambda,
  ]
}

#------------------------------------------------------------------------------
# temporary replication config
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "replication" {
  name               = "data-store-replication-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


data "aws_iam_policy_document" "replication" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.data_store.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${aws_s3_bucket.data_store.arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = ["${module.s3-data-bucket.bucket.arn}/*"]
  }
}

resource "aws_iam_policy" "replication" {
  name   = "data-store-replication-policy"
  policy = data.aws_iam_policy_document.replication.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}


resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.data_store]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.data_store.id

  rule {
    id = "whole_bucket"

    status = "Enabled"

    destination {
      bucket        = module.s3-data-bucket.bucket.arn
    }
  }
}

#------------------------------------------------------------------------------
# S3 lambda function to calculate data store file checksums
#------------------------------------------------------------------------------

variable "checksum_algorithm" {
  description = "Select Checksum Algorithm. Default and recommended choice is SHA256, however CRC32, CRC32C, SHA1 are also available."
  default     = "SHA256"
}

data "archive_file" "calculate_checksum_lambda" {
  type        = "zip"
  source_file = "lambdas/calculate_checksum_lambda.py"
  output_path = "lambdas/calculate_checksum_lambda.zip"
}

resource "aws_lambda_function" "calculate_checksum_lambda" {
  filename      = "lambdas/calculate_checksum_lambda.zip"
  function_name = "calculate-checksum-lambda"
  role          = aws_iam_role.calculate_checksum_lambda.arn
  handler       = "calculate_checksum_lambda.handler"
  runtime       = "python3.12"
  memory_size   = 4096
  timeout       = 900

  environment {
    variables = {
      Checksum = var.checksum_algorithm
    }
  }

  tags = local.tags
}

resource "aws_iam_role" "calculate_checksum_lambda" {
  name                = "calculate-checksum-lambda-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

data "aws_iam_policy_document" "calculate_checksum_lambda" {
  statement {
    sid    = "S3Permissions"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:GetObjectAttributes",
      "s3:GetObjectVersionAttributes",
      "s3:ListBucket"
    ]
    resources = ["${aws_s3_bucket.data_store.arn}/*"]
  }
}

resource "aws_iam_role_policy" "calculate_checksum_lambda" {
  name   = "calculate_checksum-lambda-iam-policy"
  role   = aws_iam_role.calculate_checksum_lambda.id
  policy = data.aws_iam_policy_document.calculate_checksum_lambda.json
}

resource "aws_lambda_permission" "s3_allow_calculate_checksum_lambda" {
  statement_id  = "AllowCalculateChecksumExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.calculate_checksum_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_store.arn
}

#------------------------------------------------------------------------------
# S3 lambda function to perform zip file summary
#------------------------------------------------------------------------------

data "archive_file" "summarise_zip_lambda" {
  type        = "zip"
  source_file = "lambdas/summarise_zip_lambda.py"
  output_path = "lambdas/summarise_zip_lambda.zip"
}

resource "aws_lambda_function" "summarise_zip_lambda" {
  filename         = "lambdas/summarise_zip_lambda.zip"
  function_name    = "summarise-zip-lambda"
  role             = aws_iam_role.summarise_zip_lambda.arn
  handler          = "summarise_zip_lambda.handler"
  runtime          = "python3.12"
  timeout          = 900
  memory_size      = 1024
  layers           = ["arn:aws:lambda:eu-west-2:017000801446:layer:AWSLambdaPowertoolsPythonV2:67"]
  source_code_hash = data.archive_file.summarise_zip_lambda.output_base64sha256
  tags             = local.tags
}

resource "aws_iam_role" "summarise_zip_lambda" {
  name                = "summarise-zip-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

data "aws_iam_policy_document" "summarise_zip_lambda" {
  statement {
    sid    = "S3Permissions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = ["${aws_s3_bucket.data_store.arn}/*"]
  }
}

resource "aws_iam_role_policy" "summarise_zip_lambda" {
  name   = "summarise-zip-iam-policy"
  role   = aws_iam_role.summarise_zip_lambda.id
  policy = data.aws_iam_policy_document.summarise_zip_lambda.json
}

resource "aws_lambda_permission" "s3_allow_summarise_zip_lambda" {
  statement_id  = "AllowSummariseZipExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.summarise_zip_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_store.arn
}
