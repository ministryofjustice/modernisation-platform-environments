resource "aws_s3_bucket" "ap_export_bucket" {
    bucket_prefix = "ap-export-bucket-"
}

resource "aws_s3_bucket_public_access_block" "ap_export_bucket" {
  bucket                  = aws_s3_bucket.ap_export_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "ap_export_bucket" {
  bucket = aws_s3_bucket.ap_export_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "ap_export_bucket" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.ap_export_bucket.arn,
      "${aws_s3_bucket.ap_export_bucket.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

module "ap_export_log_bucket" {
  source = "./modules/s3_log_bucket"

  source_bucket = aws_s3_bucket.ap_export_bucket
  account_id    = data.aws_caller_identity.current.account_id
  local_tags    = local.tags

}


resource "aws_s3_bucket_logging" "ap_export_bucket" {
  bucket = aws_s3_bucket.ap_export_bucket.id

  target_bucket = module.ap_export_log_bucket.bucket_id
  target_prefix = "log/"

  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

resource "aws_s3_bucket_notification" "csv_bucket_notification" {
  bucket = aws_s3_bucket.ap_export_bucket.id

  lambda_function {
    id                  = "csv_bucket_notification"
    lambda_function_arn = aws_lambda_function.em_ap_transfer_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.em_ap_transfer_lambda]
}


resource "aws_s3_bucket_ownership_controls" "ap_export_bucket" {
  bucket = aws_s3_bucket.ap_export_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ap_export_bucket" {
  bucket = aws_s3_bucket.ap_export_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

data "aws_iam_policy_document" "get_json_files" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.ap_export_bucket.arn,
      "${aws_s3_bucket.ap_export_bucket.arn}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::moj-reg-dev/landing/electronic-monitoring-service/data/*"
    ]
  }
}

resource "aws_iam_role" "em_ap_transfer_lambda" {
  name                = "em-ap-transfer-lambda-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.lambda_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

resource "aws_iam_role_policy" "em_ap_transfer_lambda" {
  name   = "em-ap-transfer-lambda-iam-policy"
  role   = aws_iam_role.em_ap_transfer_lambda.id
  policy = data.aws_iam_policy_document.get_json_files.json
}

data "archive_file" "em_ap_transfer_lambda" {
  type        = "zip"
  source_file = "lambdas/em_ap_transfer_lambda.py"
  output_path = "lambdas/em_ap_transfer_lambda.zip"
}

resource "aws_lambda_function" "em_ap_transfer_lambda" {
    filename = "lambdas/em_ap_transfer_lambda.zip"
    function_name = "em-ap-transfer-lambda"
    role = aws_iam_role.em_ap_transfer_lambda.arn
    handler = "em_ap_transfer_lambda.handler"
    runtime = "python3.12"
    memory_size = 4096
    timeout = 900
}

resource "aws_lambda_permission" "em_ap_transfer_lambda" {
  statement_id  = "AllowS3ObjectInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.em_ap_transfer_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.ap_export_bucket.arn
}
